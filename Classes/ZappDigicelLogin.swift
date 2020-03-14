//
//  ZappDigicelLogin.swift
//  CleengPluginExample
//
//  Created by Miri on 12/07/2019.
//  Copyright © 2018 Applicaster. All rights reserved.
//

import Foundation

import ApplicasterSDK
import ZappPlugins
import CleengLoginDigicel

@objc public class ZappDigicelLogin : NSObject, ZPLoginProviderUserDataProtocol, ZPPluggableScreenProtocol, ZPScreenHookAdapterProtocol  {
    public var screenPluginDelegate: ZPPlugableScreenDelegate?
    
    public var configurationJSON: NSDictionary?
    
    internal var configuration: ZappDigicelConfiguration?
    
    private var cleengLogin: CleengLoginPlugin?
    private let digicelApi: DigicelLoginApi?
    
    private var navigationController: UINavigationController? = nil
    private var digicelWebViewController: DigicelLoginWebViewController!
    
    fileprivate var loginCompletion: ((Bool, NSError?, [String : Any]?) -> Void)?
    
    public required override convenience init() {
        self.init(configurationJSON: nil)
    }
    
    public required init(configurationJSON: NSDictionary?) {
        guard let configurationJSON = configurationJSON else {
            self.digicelApi = nil
            super.init()
            return
        }
        
        self.configurationJSON = configurationJSON
        self.configuration = ZappDigicelConfiguration(configuration: (configurationJSON as? [String:Any]) ?? [:])
        
        self.digicelApi = DigicelLoginApi(configurationJSON: configurationJSON)
        
        super.init()
    }
    
    required public convenience init?(screenName: String?, dataSourceModel: NSObject?) {
        self.init(configurationJSON: nil)
    }
    
    public required convenience init?(pluginModel: ZPPluginModel, dataSourceModel: NSObject?) {
        self.init(configurationJSON: nil)
    }
    
    public required convenience init?(pluginModel: ZPPluginModel, screenModel: ZLScreenModel, dataSourceModel: NSObject?) {
        let generalSection = screenModel.object["general"] as? NSDictionary
        
        self.init(configurationJSON: generalSection)
    }
    
    public func isUserComply(policies: [String : NSObject], completion: @escaping (Bool) -> ()) {
        completion(false)
    }
    
    public func handleUrlScheme(_ params: NSDictionary) {
    }
    
    public func login(_ additionalParameters: [String : Any]?, completion: @escaping ((ZPLoginOperationStatus) -> Void)) {
        completion(.completedSuccessfully)
    }
    
    public func logout(_ completion: @escaping ((ZPLoginOperationStatus) -> Void)) {
        DigicelCredentialsManager.saveDigicelUser(nil)
        
        guard let cleengLogin = self.cleengLogin else {
            completion(.completedSuccessfully)
            return
        }
        
        cleengLogin.logout(completion: { (result) in
            completion(.completedSuccessfully)
        })
    }
    
    public func isAuthenticated() -> Bool {
        guard let digicelUser = DigicelCredentialsManager.loadDigicelUser() else {
            return false
        }
        
        return digicelUser.digicelToken != nil && digicelUser.userType != .Free
    }
    
    public func isPerformingAuthorizationFlow() -> Bool {
        return false
    }
    
    public func getUserToken() -> String {
        return ""
    }
    
    public func createScreen() -> UIViewController {
        return UIViewController()
    }
    
    public func executeHook(presentationIndex: NSInteger, dataDict: [String : Any]?, taskFinishedWithCompletion: @escaping (Bool, NSError?, [String : Any]?) -> Void) {
        taskFinishedWithCompletion(false, nil, nil)
    }
    
    public func executeHook(presentationIndex: NSInteger, model: NSObject?, taskFinishedWithCompletion: @escaping (Bool, NSError?, [String : Any]?) -> Void) {
        func completeHook(status: Bool) {
            self.screenPluginDelegate?.removeScreenPluginFromNavigationStack()
            taskFinishedWithCompletion(status, nil, nil)
        }
        
        guard let digicelApi = self.digicelApi else {
            completeHook(status: false)
            return
        }
        
        guard let playables = model as? Array<Any>, let playable = playables[0] as? ZPAtomEntryPlayableProtocol else {
            completeHook(status: false)
            return
        }
        
        let extensions = playable.extensionsDictionary as? [String: NSObject] ?? [String: NSObject]()
        
        if let freeValue = extensions["free"] as? Bool, freeValue {
            completeHook(status: true)
            return
        }
        
        if let freeValue = extensions["free"] as? String, freeValue == "true" {
            completeHook(status: true)
            return
        }
        
        if let currentDigicelUser = digicelApi.currentDigicelUser {
            let userType = currentDigicelUser.userType
            if userType == .Basic || userType == .Premium {
                completeHook(status: true)
                return
            }
        }
        
        guard let authId = self.configuration?.premiumAuthId else {
            completeHook(status: false)
            return
        }
        
        let overridePolicies = extensions.merge([
            "ds_product_ids": [authId] as NSObject,
            "requires_authentication": NSNumber(booleanLiteral: false)
        ]) as [String: NSObject]
        
        playable.extensionsDictionary = overridePolicies as NSDictionary
        
        self.cleengLogin = self.createCleengLoginPlugin(model)
        
        guard let cleengLogin = self.cleengLogin else {
            completeHook(status: false)
            return
        }
        
        cleengLogin.isUserComply(policies: overridePolicies) { (status) in
            if status {
                completeHook(status: true)
                return
            }
            
            func handleLoginCompletion() {
                if let digicelUser = digicelApi.currentDigicelUser, digicelUser.userType == .Premium {
                    completeHook(status: true)
                    return
                }
                
                // verify purchase with cleeng
                cleengLogin.login(overridePolicies) { (cleengStatus) in
                    completeHook(status: cleengStatus == .completedSuccessfully)
                }
            }
            
            func performLogin() {
                self.loginCompletion = { (status: Bool, error: NSError?, data: [String: Any]?) in
                    self.closeInnerScreen {
                        guard status else {
                            completeHook(status: false)
                            return
                        }
                        
                        handleLoginCompletion()
                    }
                }
                
                self.showLoginScreen()
            }
            
            if self.isAuthenticated() && cleengLogin.isAuthenticated() {
                handleLoginCompletion()
            }
            else if self.isAuthenticated() && !cleengLogin.isAuthenticated() {
                self.logout() { status in
                    performLogin()
                }
            }
            else {
                performLogin()
            }
        }
    }
    
    public var isFlowBlocker: Bool {
        return true
    }
}

extension ZappDigicelLogin: ZPAppLoadingHookProtocol {
    public func executeAfterAppRootPresentation(displayViewController: UIViewController?, completion: (() -> Swift.Void)?) {
        completion?()
    }
}

extension ZappDigicelLogin: DigicelRedirectUriProtocol, DigicelBaseProtocol, LoginProtocol {
    public func handleRedirectUriWith(params: [String : Any]?) {
        guard let params = params, let code = params["code"] as? String else {
            self.loginCompletion?(false, nil, nil)
            return
        }
        
        self.handleOAuthFlow(redirectCode: code)
    }
    
    public func handleRedirectUriRegisterCompleted() {
        self.showWebLoginOrRegister(register: false)
    }
    
    public func handleRedirectUriUpdateMail() {
    }
    
    public func userDidSelectToClose() {
        if let navController = self.navigationController {
            navController.popToRootViewController(animated: true)
        }
        else {
            self.loginCompletion?(false, nil, nil)
        }
    }
    
    func actionSelected(register: Bool) {
        self.showWebLoginOrRegister(register: register)
    }
    
    func closeLoginScreen() {
        self.loginCompletion?(false, nil, nil)
    }
}

extension ZappDigicelLogin {
    private func createCleengLoginPlugin(_ model: NSObject?) -> CleengLoginPlugin? {
        guard
            let pluginModel = ZPPluginManager.pluginModelById("CleengDigicel"),
            let classType = ZPPluginManager.adapterClass(pluginModel) as? CleengLoginPlugin.Type,
            let screenModel = ZAAppConnector.sharedInstance().genericDelegate.screenModelForPluginID(pluginID: "CleengDigicel", dataSource: model) else {
                return nil
        }
        
        return classType.init(pluginModel: pluginModel, screenModel: screenModel, dataSourceModel: model)
    }
    
    private func handleOAuthFlow(redirectCode: String) {
        guard let digicelApi = self.digicelApi else {
            self.loginCompletion?(false, nil, nil)
            return
        }
        
        digicelApi.handleOAuthFlow(authCode: redirectCode) { (digicelUser, error) in
            guard let digicelUser = digicelUser else {
                self.displayErrorAlert()
                return
            }
            
            if let email = digicelUser.email, !email.isEmpty {
              self.syncWithCleeng() { (succeeded, error) in
                  self.loginCompletion?(succeeded, nil, nil)
              }
            }
            else {
                self.presentEmailVerificationWebView()
            }
        }
    }
    
    private func displayErrorAlert(message: ZappDigicelLoginLocalization.Key = .errorInternalMessage) {
        let message = self.configuration?.localization.localizedString(for: message)
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: self.configuration?.localization.localizedString(for: .alertCancelAction, defaultString: NSLocalizedString("OK", comment: "Cancel")), style: .cancel, handler: { [weak self] _ in
            guard let strongSelf = self else { return }
            if let vc = strongSelf.navigationController?.presentingViewController {
                vc.dismiss(animated: true, completion: {
                    self?.loginCompletion?(false, nil, nil)
                })
            }
        }))
        
        if let vc = self.navigationController?.viewControllers.first {
            vc.present(alert, animated: true, completion: nil)
        }
        else {
            ZAAppConnector.sharedInstance().navigationDelegate?.topmostModal()?.present(alert, animated: true)
        }
    }
    
    private func showWebLoginOrRegister(register :Bool) {
        guard
            let navigationController = self.navigationController,
            let configurationJSON = self.configurationJSON,
            let clientId = configurationJSON["digicel_client_id"] as? String,
            let loginUrl = configurationJSON["digicel_login_url"] as? String,
            let digicelScope = configurationJSON["digicel_scope"] as? String else {
                return
        }
        
        let url: String
        
        if register {
            guard let registerUrl = configurationJSON["digicel_welcome_screen_create_account_link"] as? String else {
                return
            }
            
            url = registerUrl
        }
        else {
            url = "\(loginUrl)?response_type=code&client_id=\(clientId)&redirect_uri=https://applicaster.sportsmax/auth/&scope=\(digicelScope)"
        }
        
        let bundle = Bundle.init(for: type(of: self))
        let loginWebViewController = DigicelLoginWebViewController(nibName: "DigicelLoginWebViewController", bundle: bundle)
        loginWebViewController.delegate = self
        
        self.digicelWebViewController = loginWebViewController
        
        if let webViewVC = DigicelTimedWebViewController(url: URL(string: url)) {
            webViewVC.view.backgroundColor = UIColor.white
            webViewVC.redirectUriDelegate = self
            loginWebViewController.webLoginVC = webViewVC
            webViewVC.spinner.color = UIColor.black
            navigationController.pushViewController(loginWebViewController, animated: true)
            webViewVC.loadTargetURL()
        }
    }
    
    private func showLoginScreen() {
        let bundle = Bundle.init(for: type(of: self))
        
        let loginViewController = DigicelLoginViewController(nibName: "DigicelLoginViewController", bundle: bundle)
        loginViewController.loginProtocol = self
        loginViewController.configuration = self.configuration
        
        self.navigationController = UINavigationController(rootViewController: loginViewController)
        if let navController = self.navigationController {
            navController.setNavigationBarHidden(true, animated: false)
            ZAAppConnector.sharedInstance().navigationDelegate?.topmostModal()?.present(navController, animated: true, completion: nil)
        }
    }
    
    private func presentWebViewWith(url: String?) {
        guard let urlStr = url else {
            return
        }
        
        if let webViewVC = DigicelTimedWebViewController(url: URL(string: urlStr)) {
            webViewVC.redirectUriDelegate = self
            
            if let digicelWebViewController = self.digicelWebViewController {
                digicelWebViewController.webLoginVC = webViewVC
                digicelWebViewController.addChildViewController(digicelWebViewController.webLoginVC, to: digicelWebViewController.webContainerView)
                webViewVC.loadTargetURL()
            }
            else {
                let bundle = Bundle.init(for: type(of: self))
                
                let loginWebViewController = DigicelLoginWebViewController(nibName: "DigicelLoginWebViewController", bundle: bundle)
                loginWebViewController.delegate = self
                self.digicelWebViewController = loginWebViewController
                
                self.navigationController = UINavigationController(rootViewController: loginWebViewController)
                if let navController = navigationController {
                    navController.setNavigationBarHidden(true, animated: false)
                }
                
                loginWebViewController.webLoginVC = webViewVC
                ZAAppConnector.sharedInstance().navigationDelegate?.topmostModal()?.present(navigationController!, animated: true) {
                    webViewVC.loadTargetURL()
                }
            }
        }
    }
    
    private func presentEmailVerificationWebView() {
        self.presentWebViewWith(url: "https://digicelid.digicelgroup.com/management/identity/edit/email.do")
    }
    
    private func syncWithCleeng(completion: @escaping ((_ succeeded: Bool, _ error: Error?) -> Void)) {
        guard
            let digicelApi = self.digicelApi,
            let cleengPlugin = self.cleengLogin,
            var digicelUser = digicelApi.currentDigicelUser,
            let email = digicelUser.email else {
                completion(false, nil)
                return
        }
        
        func handleUserSubscriptions(succeeded: Bool, plans: [Any]?, error: Error?) {
            guard succeeded else {
                completion(false, nil)
                return
            }
            
            guard let plans = plans, plans.count > 0 else {
                completion(true, nil)
                return
            }
            
            guard let _ = plans.first as? DigicelPlan else {
                completion(false, nil)
                return
            }
            
            digicelUser.userType = .Premium
            DigicelCredentialsManager.saveDigicelUser(digicelUser)
                        
            completion(true, nil)
        }
        
        func handleDigicelSubscriptionType(success: Bool, error: Error?) {
            guard success, let subscriberType = digicelUser.subscriberType else {
                completion(false, error)
                return
            }
            
            if (subscriberType == .InNetwork) {
                digicelApi.fetchUserSubscriptions(completion: handleUserSubscriptions)
            }
            else {
                completion(true, nil)
            }
        }
        
        func handleCleengRegistration(result: Result<Void, Error>) {
            if case let .failure(error) = result {
                completion(false, error)
                return
            }
            
            digicelUser.userType = .Basic
            DigicelCredentialsManager.saveDigicelUser(digicelUser)
            
            digicelApi.fetchSubscriberType(completion: handleDigicelSubscriptionType)
        }
        
        let authData = [
            "email": email
        ]
        
        cleengPlugin.signUp(authData: authData, completion: handleCleengRegistration)
    }
    
    private func closeInnerScreen(completion: @escaping () -> ()) {
        guard let navController = self.navigationController else {
            completion()
            return
        }
        
        navController.dismiss(animated: true) {
            completion()
        }
    }
}

extension ZappDigicelLogin: APTimedWebViewControllerDelegate {
    public func timedWebViewController(_ timedVC: APTimedWebViewController!, shouldStartLoadWith request: URLRequest!, navigationType: WKNavigationType) -> Bool {
        return true
    }
}
