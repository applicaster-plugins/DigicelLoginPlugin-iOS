//
//  ZappDigicelLogin.swift
//  CleengPluginExample
//
//  Created by Miri on 12/07/2019.
//  Copyright © 2018 Applicaster. All rights reserved.
//

import Foundation
import ZappPlugins
import ZappLoginPluginsSDK
import ApplicasterSDK
import SwiftyStoreKit
import CleengLogin

@objc public class ZappDigicelLogin : NSObject, ZPLoginProviderUserDataProtocol, ZPAppLoadingHookProtocol,APTimedWebViewControllerDelegate, DigicelRedirectUriProtocol, DigicelBaseProtocol {
   
    
    
    /// Cleeng publisher identifier. **Required**
    private var cleengPublisherId: String!
    
    /// Plugin configuration json. See plugin manifest for the list of available configuration flags
    public var configurationJSON: NSDictionary?
    
    // The configuration model
    internal var configuration: ZappDigicelConfiguration?
    
    private var cleengLogin: ZappCleengLogin!

    private var digicelApi: DigicelLoginApi?
    
    private var userType: DigicelUser.UserType? = .Free

    private var digicelWebViewController: DigicelLoginWebViewController!
    
    private var navigationController: UINavigationController? = nil
    
    fileprivate var loginCompletion:(((_ status: ZPLoginOperationStatus) -> Void))?

    public required override init() {
        super.init()
    }
    
    public required init(configurationJSON: NSDictionary?) {
        
        let publisherId: String! = configurationJSON?["cleeng_login_publisher_id"] as? String
        assert(publisherId != nil, "'cleeng_login_publisher_id' is mandatory")
        
        super.init()
        self.configurationJSON = configurationJSON
        cleengLogin = ZappCleengLogin.init(configurationJSON: configurationJSON)
        self.cleengPublisherId = publisherId
        self.configuration = ZappDigicelConfiguration(configuration: (configurationJSON as? [String:Any]) ?? [:])
        if let userType = UserDefaults.standard.string(forKey: "userType"){
           self.userType = DigicelUser.UserType(rawValue: userType)!
        }
    }
    
    //MARK: - ZPLoginProviderUserDataProtocol
    
    /// A map of closures to call on verify completion
    private var verifyCalls: [String:((Bool) -> ())] = [:]
    
    /**
     `ZPLoginProviderUserDataProtocol` api. Call this to check if user has access to one or more items.
     */
    
    public func isUserComply(policies: [String : NSObject], completion: @escaping (Bool) -> ()) {
        if(isFreeAccess() && (userType == .Basic || userType == .Premium)){
             completion(true)
        }else{
            completion(false)
           // cleengLogin.isUserComply(policies: policies, completion: completion)
        }
    }
    
    
    public func handleUrlScheme(_ params: NSDictionary) {
        guard let action = params["action"] as? String else{
            return
        }
        switch action {
        case "login":
            if(getUserToken() != ""){
                displayErrorAlert(message: .alreadyLogin)
            }else{
                login(nil) { (bool) in
                    
                }
            }
        case "logout":
            if(getUserToken() != ""){
                logout { (bool) in
                    
                }
            }else{
                displayErrorAlert(message: .alreadyLogout)
                }
        default:
            return
        }
    }
   
   
    
    //check if user can see item or need to login / buy subscription
    public func itemIsLocked(policies: [String : NSObject]) -> Bool{
        if let isfree = policies["free"] as? Bool{
            if(isfree){
                return true
            }
        }
        
        if let _ = policies["playable_items"]{
            return canPlayItem()
        }
        
        if let type = policies["type"] as? String {
            switch type {
            case "Channel":
                  return canPlayItem()
            case "AtomEntry":
                 return canPlayItem()
            case "VodItem":
                return canPlayItem()
            case "Category":
                 return canPlayItem()
            case "Collection":
                return canPlayItem()
            default:
                 return canPlayItem()
            }
        }
        return false
   }
    
    /**
     `ZPLoginProviderUserDataProtocol` api. Call this to check if user has access to one or more items.
     */
//    public func isUserComply(policies: [String : NSObject]) -> Bool {
//        return itemIsLocked(policies: policies)
//    }
    
    public func canPlayItem() -> Bool{
        if(isFreeAccess() && (userType == .Basic || userType == .Premium)){
            return true
        }
        return false
    }
    
    //public fun
    
    /**
     `ZPLoginProviderUserDataProtocol` api. Call this to present UI to let user make login (if needed) and IAP purchase (if needed).
     */
    public func login(_ additionalParameters: [String : Any]?, completion: @escaping ((ZPLoginOperationStatus) -> Void)) {
        loginCompletion = completion
  
       createNavigationControllerWithWebLogin()
    }
    
    /**
     `ZPLoginProviderUserDataProtocol` api. Call this to logout from Cleeng.
     */
    public func logout(_ completion: @escaping ((ZPLoginOperationStatus) -> Void)) {
        cleengLogin.logout(completion)
    }
    
    public func isAuthenticated() -> Bool {
        return false
    }
    
    func displayErrorAlert(message: ZappDigicelLoginLocalization.Key = .errorInternalMessage){
       // let title = self.configuration?.localization.localizedString(for: .errorInternalTitle, defaultString: NSLocalizedString("Error", comment: "Error"))
        let message = self.configuration?.localization.localizedString(for: message)
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: self.configuration?.localization.localizedString(for: .alertCancelAction, defaultString: NSLocalizedString("OK", comment: "Cancel")), style: .cancel, handler: { [weak self] _ in
             guard let strongSelf = self else { return }
            if let vc = strongSelf.navigationController?.presentingViewController {
                vc.dismiss(animated: true, completion: {
                })
            }
        }))
        if let vc = self.navigationController?.viewControllers.first{
            vc.present(alert, animated: true, completion: nil)
        }else{
            APApplicasterController.sharedInstance().rootViewController.topmostModal().present(alert, animated: true)
        }
    }
    
    /**
     `ZPLoginProviderUserDataProtocol` api. Check if there currently UI presented to make login or IAP purchase for an item
     */
    public func isPerformingAuthorizationFlow() -> Bool {
        return cleengLogin.isPerformingAuthorizationFlow()
    }
    
    public func getUserToken() -> String {
        return cleengLogin.getUserToken()
    }
    
    //MARK: - ZPAppLoadingHookProtocol
    public func executeAfterAppRootPresentation(displayViewController: UIViewController?, completion: (() -> Swift.Void)?) {
        guard let startOnAppLaunch = configurationJSON?["cleeng_login_start_on_app_launch"] else {
            completion?()
            return
        }
        
        if (APAuthorizationManager.sharedInstance()?.authorizationTokens()["179"] as? String == nil && (UserDefaults.standard.string(forKey: "userType") != nil)){
            let digicelApi = DigicelLoginApi(configurationJSON: configurationJSON)
            digicelApi.freeAccessToken { (success) in
                
            }
        }
        
        var presentLogin = false
        if let flag = startOnAppLaunch as? Bool {
            presentLogin = flag
        } else if let num = startOnAppLaunch as? Int {
            presentLogin = (num == 1)
        } else if let str = startOnAppLaunch as? String {
            presentLogin = (str == "1")
        }
        
        if presentLogin {
            let item = EmptyAPPurchasableItem()
            self.login(["playable_items" : [item]], completion: { [weak self] _ in
                
                guard let strongSelf = self else {
                    return
                }
                if let vc = strongSelf.navigationController?.presentingViewController {
                    vc.dismiss(animated: true, completion: completion)
                } else {
                    completion?()
                }
            })
        } else {
            completion?()
        }
    }
    
    //MARK: -

    public func handleRedirectUriWith(params: [String : Any]?) {
        guard let params = params,
            let code = params["code"] as? String else {
                return
        }
        startOAuthFlow(redirectCode: code)
    }
    
    //MARK: - Private
    
    func startOAuthFlow(redirectCode: String) {
        let digicelApi = DigicelLoginApi(configurationJSON: configurationJSON)
        self.digicelApi = digicelApi
        digicelApi.cleengLogin = cleengLogin
        digicelApi.continueOAuthFlow(authCode: redirectCode) { (succeeded, response, error) in
            if succeeded == true {
                if let response = response as? [String : Any],
                    let email = response["email"] as? String,
                    email.isEmpty == false {
                    // The user has an email address, continue
                    self.continueSubscriptionFlow(completion: { (succeeded, error) in
                        if succeeded == true {
                            if let completion = self.loginCompletion {
                                completion(.completedSuccessfully)
                            }
                           
                        }
                        else {
                            if let completion = self.loginCompletion {
                                completion(.failed)
                            }
                        }
                    })
                }
                else {
                    //present webview with Digicel email verification
                    self.presentEmailVerificationWebView()
                }
            }
            else {
                self.displayErrorAlert()
            }
            
        }
    }
    
    // Flag to indicate if login only gets free access
    func isFreeAccess() -> Bool {
        guard let loggedInFreeAccess = configurationJSON?["logged_in_free_access"] else {
            return false
        }
        var retVal = false
        if let flag = loggedInFreeAccess as? Bool {
            retVal = flag
        } else if let num = loggedInFreeAccess as? Int {
            retVal = (num == 1)
        } else if let str = loggedInFreeAccess as? String {
            retVal = (str == "1")
        }
        return retVal
    }
    
    func createNavigationControllerWithWebLogin () {
        
        if let configurationJSON = configurationJSON {
            let bundle = Bundle.init(for: type(of: self))
            let loginWebViewController = DigicelLoginWebViewController(nibName: "DigicelLoginWebViewController", bundle: bundle)
            loginWebViewController.delegate = self
            digicelWebViewController = loginWebViewController
            navigationController = UINavigationController(rootViewController: loginWebViewController)
            if let navController = navigationController {
               navController.setNavigationBarHidden(true, animated: false)
                if let webViewVC = DigicelTimedWebViewController(url: URL(string: (configurationJSON["digicel_login_url"] as? String)!)) {
                    webViewVC.redirectUriDelegate = self
                    loginWebViewController.webLoginVC = webViewVC
                    APApplicasterController.sharedInstance().rootViewController.topmostModal().present(navController,
                                                                                                       animated: true) {
                                                                                                        
                                                                                                        webViewVC.loadTargetURL()
                    }
                }
            }
        }
    }
    
    func presentWebViewWith(url: String?) {
        guard let urlStr = url else {
            return
        }
        if let webViewVC = DigicelTimedWebViewController(url: URL(string: urlStr)) {
            webViewVC.redirectUriDelegate = self
            
            if let digicelWebViewController = digicelWebViewController {
                digicelWebViewController.webLoginVC = webViewVC
                digicelWebViewController.addChildViewController(digicelWebViewController.webLoginVC, to: digicelWebViewController.webContainerView)
                webViewVC.loadTargetURL()
            }
        }
    }
    
    
    func presentEmailVerificationWebView()  {
            self.presentWebViewWith(url: "https://digicelid.digicelgroup.com/management/identity/edit/email.do")
    }
    
    public func handleRedirectUriUpdateMail() {
   //     self.userDidSelectToClose()
    }
    
    func continueSubscriptionFlow(completion: @escaping ((_ succeeded: Bool, _ error: Error?) -> Void)) {
        if let digicelApi = digicelApi {
                    digicelApi.registerToCleeng(api: self.getCleengApi(), completion: { (succeeded, error) in
                        if succeeded == true {
                            digicelApi.currentDigicelUser?.userType = .Basic
                            UserDefaults.standard.set(DigicelUser.UserType.Basic.rawValue, forKey: "userType")
                            digicelApi.freeAccessToken(completion: { (sucsses) in
                                if(sucsses){
                                    if self.isFreeAccess() == true {
                                       if  let vc = self.navigationController?.viewControllers.first{
                                        vc.dismiss(animated: false, completion: {
                                            completion(succeeded, error)
                                        })
                                        }
                                    }
                                    else  {
                                        if  let vc = self.navigationController?.viewControllers.first{
                                            vc.dismiss(animated: false, completion: {
                                                completion(false, error)
                                            })
                                        }
                                    }
                        }
                        else {
                             self.displayErrorAlert()
                             completion(false, error)
                        }
                    })
                }
                else {
                     self.displayErrorAlert()
                    completion(false, error)
                }
            })
        }
    }
    
    func showOffersViewController(){
        let bundle = Bundle.init(for: type(of: self))
        let offersVC = DigicelOffersViewController(nibName: "DigicelOffersViewController", bundle: bundle)
        offersVC.delegate = self
        if let _ = self.digicelWebViewController{
            navigationController?.present(offersVC, animated: true, completion: nil)
           
        }else{
            navigationController = UINavigationController(rootViewController: offersVC)
            if let navController = navigationController{
                navController.setNavigationBarHidden(true, animated: false)
                APApplicasterController.sharedInstance().rootViewController.topmostModal().present(navController,
                                                                                                   animated: true) {
                }
            }
        }
    }
    
    func closeOnlyLoginScreen(){
        if  let vc = self.navigationController?.viewControllers.first{
            vc.dismiss(animated: false, completion: nil)
        }
    }
    
    func getCleengApi() -> CleengLoginAndSubscribeApi? {
        var cleengApi: CleengLoginAndSubscribeApi
        
        if let api = cleengLogin.getApi() {
            cleengApi = api
        }
        else {
            let item = EmptyAPPurchasableItem()
            let api = CleengLoginAndSubscribeApi(item: item, publisherId: cleengPublisherId)
            cleengApi = api
        }
        return cleengApi
    }
    
    //MARK: - DigicelBaseProtocol

    public func userDidSelectToClose() {
        if let vc = navigationController?.presentingViewController {
            let c = loginCompletion
            loginCompletion = nil
            vc.dismiss(animated: true, completion: {
                c?(.cancelled)
            })
        }
        else {
            loginCompletion?(.cancelled)
        }
    }
}

//MARK: - APTimedWebViewControllerDelegate

public func timedWebViewController(_ timedVC: APTimedWebViewController!, shouldStartLoadWith request: URLRequest!, navigationType: WKNavigationType) -> Bool {
    return true
}

//MARK: - Utils private classes

/**
 An object to use when plugin presented on app launch (without any item to be played), since *ZappCleengLogin* requires at least one item.
 */
private class EmptyAPPurchasableItem : APPurchasableItem {
    override var authorizationProvidersIDs: NSArray! {
        return []
    }
    
    override func isLoaded() -> Bool {
        return true
    }
}
