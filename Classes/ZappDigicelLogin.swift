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
import ZappPlugins


@objc public class ZappDigicelLogin : NSObject, ZPLoginProviderUserDataProtocol, ZPAppLoadingHookProtocol,APTimedWebViewControllerDelegate, DigicelRedirectUriProtocol, DigicelBaseProtocol {
   
    /// Cleeng publisher identifier. **Required**
    private var cleengPublisherId: String!
    public var configurationJSON: NSDictionary?
    // The configuration model
    internal var configuration: ZappDigicelConfiguration?
    //cleeng login object
    private var cleengLogin: ZappCleengLogin!
    private var digicelApi: DigicelLoginApi?
    //web view for for the login screen
    private var digicelWebViewController: DigicelLoginWebViewController!
    private var navigationController: UINavigationController? = nil
    //cleeng offers view controller
    private var offersNavagationController: CleengLoginAndSubscriptionController?
    fileprivate var loginCompletion:(((_ status: ZPLoginOperationStatus) -> Void))?
    private var didComeBackFromDigicelOffers = false

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
        digicelApi = DigicelLoginApi(configurationJSON: configurationJSON)
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc func appMovedToForeground() {
        if(didComeBackFromDigicelOffers){
            checkForDigicelSubscruptions()
            APApplicasterController.sharedInstance().rootViewController.topmostModal()?.children.first?.dismiss(animated: false, completion: nil)
        }
    }
    
    func checkForDigicelSubscruptions(){
        digicelApi?.getUserSubscriptions(completion: { (succeeded, plans, error) in
            if(plans?.count != 0){
                self.digicelApi?.currentDigicelUser?.userType = .Premium
                DigicelCredentialsManager.saveDigicelUserType(type: .Premium)
                if let plan = plans?.first as? DigicelPlan , let email = self.digicelApi?.currentDigicelUser?.email{
                    self.digicelApi?.cleengUpdateUserPackages(withEmail: email, plan: plan, completion: { (success, error) in
                        if let date = plan.dateEnd{
                            self.digicelApi?.generateTokenForDigicelPlan(dateEnd: date, completion: { (success) in
                                
                            })
                        }
                    })
                }
            }
        })
    }
    
    //MARK: - ZPLoginProviderUserDataProtocol
    
    /// A map of closures to call on verify completion
    private var verifyCalls: [String:((Bool) -> ())] = [:]
    
    /**
     `ZPLoginProviderUserDataProtocol` api. Call this to check if user has access to one or more items.
     */
    
//    public func isUserComply(policies: [String : NSObject], completion: @escaping (Bool) -> ()) {
//      cleengLogin.isUserComply(policies: policies, completion: completion)
//    }
    
    
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
    
    
    /**
     `ZPLoginProviderUserDataProtocol` api. Call this to check if user has access to one or more items.
     */
    public func isUserComply(policies: [String : NSObject]) -> Bool {
       
        var result = true
        
        if let freeValue = policies["free"] as? Bool {
            if freeValue {return true}
        }
        
        if let freeValue = policies["free"] as? String {
            return (freeValue == "true") ? true : false
        }
        
        if(validForFreePass()){
            return true
       }else{
         cleengLogin.isUserComply(policies: policies, completion: { (success) in
              result =  success
           })
        }
        return result
    }
    
    private func validForFreePass() -> Bool{
        if((isFreeAccess() && digicelApi?.currentDigicelUser?.userType == .Basic) || digicelApi?.currentDigicelUser?.userType == .Premium){
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
        if (digicelApi?.currentDigicelUser?.userType != .Free){
            didComeBackFromDigicelOffers = true
            self.showSubscription()
        }else{
            createNavigationControllerWithWebLogin()
        }
    }
    
    /**
     `ZPLoginProviderUserDataProtocol` api. Call this to logout from Cleeng.
     */
    public func logout(_ completion: @escaping ((ZPLoginOperationStatus) -> Void)) {
        cleengLogin.logout(completion)
        DigicelCredentialsManager.saveDigicelUserType(type: .Free)
        digicelApi?.currentDigicelUser?.userType = .Free
    }
    
    public func isAuthenticated() -> Bool {
        return false
    }
    
    func showSubscription(){
        let digicelUser = digicelApi?.currentDigicelUser?.subscriberType == .InNetwotk
        if let offersNav = offersNavagationController{
             offersNav.digicelInNetworkUser = digicelUser
             APApplicasterController.sharedInstance().rootViewController.topmostModal().present(offersNav, animated: true)
        }else{
            offersNavagationController = CleengLoginAndSubscriptionController(startWith: .subscriptionsList, api: getCleengApi()!, configuration: cleengLogin.configuration)
            offersNavagationController?.digicelInNetworkUser = digicelUser
            APApplicasterController.sharedInstance().rootViewController.topmostModal().present(offersNavagationController!, animated: true)
        }
    }
    
    // internal error for login flaw
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
        
        //check if free access and have free access token.  if not , generate.
        if let freeAccessAuthId = configurationJSON?["digicel_free_access_auth_id"] as? String{
            if (APAuthorizationManager.sharedInstance()?.authorizationTokens()[freeAccessAuthId] as? String == nil && (digicelApi?.currentDigicelUser?.userType != .Free) && self.isFreeAccess()){
                digicelApi?.freeAccessToken { (success) in
                    
                }
            }
        }
        
       // check if digicel expierd
        if(getUserToken() != "" && digicelApi?.currentDigicelUser?.subscriberType == .InNetwotk){
            if let sportmaxOfferId = configurationJSON?["Sportsmax_offer_id"] as? String , let offerId = DigicelCredentialsManager.getDigicelPlanOfferId(){
                if(sportmaxOfferId == offerId){
                    if (!isTokenValid(token: getUserToken())){
                        guard let api = digicelApi else{
                         return
                        }
                        api.getUserSubscriptions { (success, response, error) in
                            if(response?.count != 0){
                                guard let email = api.currentDigicelUser?.email, let plan = response?.first as? DigicelPlan, let dateEnd = plan.dateEnd else{
                                    return
                                }
                                self.digicelApi?.currentDigicelUser?.userType = .Premium
                                DigicelCredentialsManager.saveDigicelUserType(type: .Premium)
                                api.generateTokenForDigicelPlan(dateEnd: dateEnd, completion: { (success) in
                                    
                                })
                                api.cleengUpdateUserPackages(withEmail: email, plan: plan, completion: { (success, error) in
                                    
                                })
                            }else{
                                self.digicelApi?.currentDigicelUser?.userType = .Basic
                                DigicelCredentialsManager.saveDigicelUserType(type: .Premium)
                            }
                        }
                    }
                }
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
        guard let digicelApi =  self.digicelApi else{
            return
        }
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
                            DigicelCredentialsManager.saveDigicelUserType(type: .Basic)
                            digicelApi.getSubscriberType(completion: { (inNetwotk, error) in
                                if (inNetwotk){
                                    digicelApi.getUserSubscriptions(completion: { (succeeded, plans, error) in
                                        if(plans?.count == 0){
                                            self.closeOnlyLoginScreen(completion: {
                                                 completion(false, error)
                                                self.showSubscription()
                                            })
                                        }else{
                                            digicelApi.currentDigicelUser?.userType = .Premium
                                            DigicelCredentialsManager.saveDigicelUserType(type: .Premium)
                                            if let plan = plans?.first as? DigicelPlan , let email = digicelApi.currentDigicelUser?.email{
                                                digicelApi.cleengUpdateUserPackages(withEmail: email, plan: plan, completion: { (success, error) in
                                                    if let date = plan.dateEnd{
                                                        digicelApi.generateTokenForDigicelPlan(dateEnd: date, completion: { (success) in
                                                            self.closeOnlyLoginScreen(completion: {
                                                                completion(true, error)
                                                            })
                                                        })
                                                    }
                                                })
                                            }
                                            
                                        }
                                    })
                                }else{
                                    if self.isFreeAccess(){
                                        digicelApi.freeAccessToken(completion: { (succeeded) in
                                            self.closeOnlyLoginScreen(completion: {
                                                completion(true, error)
                                            })
                                        })
                                    }else{
                                        self.closeOnlyLoginScreen(completion: {
                                            completion(false, error)
                                        })
                                    }
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
    
    func closeOnlyLoginScreen(completion: @escaping () -> ()){
        if  let vc = self.navigationController?.viewControllers.first{
            vc.dismiss(animated: true) {
                completion()
            }
        }
    }
    
    //check if the token expierd
    func isTokenValid(token: String) -> Bool{
        let tokenEncoded = token.components(separatedBy: ".")[1]
        let dataDec = Data(base64Encoded: tokenEncoded)
        guard let decodeString = String(data: dataDec!, encoding: .utf8)else{
            return false
        }
        do{
            let timeInt = try convertToDictionary(from: decodeString)["exp"] as? Int64
            let currentTime = Int64((NSDate().timeIntervalSince1970 * 1000.0).rounded())
            if(timeInt! * 1000 > currentTime) {
                    return true
            }
        }catch{
            return false
        }
        return false
    }
    
    func convertToDictionary(from text: String) throws -> [String: Any] {
        guard let data = text.data(using: .utf8) else { return [:] }
        let anyResult: Any = try JSONSerialization.jsonObject(with: data, options: [])
        return anyResult as? [String: Any] ?? [:]
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
        cleengApi.cleengLoginState = .loggedIn
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
