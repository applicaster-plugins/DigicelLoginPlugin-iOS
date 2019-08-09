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
    }
    
    //MARK: - ZPLoginProviderUserDataProtocol
    
    /// A map of closures to call on verify completion
    private var verifyCalls: [String:((Bool) -> ())] = [:]
    
    /**
     `ZPLoginProviderUserDataProtocol` api. Call this to check if user has access to one or more items.
     */
    
    public func isUserComply(policies: [String : NSObject], completion: @escaping (Bool) -> ()) {
        
       cleengLogin.isUserComply(policies: policies, completion: completion)
       
    }
    
    //check if user can see item or need to login / buy subscription
    public func itemIsLocked(policies: [String : NSObject]) -> Bool{
        if let isfree = policies["free"] as? Bool{
            if(isfree){
                return true
            }
        }

        if(isFreeAccess() && (digicelApi?.currentDigicelUser?.userType == .Basic || digicelApi?.currentDigicelUser?.userType == .Premium)){
            return true
        }
        
        if let _ = policies["playable_items"]{
            return digicelApi?.currentDigicelUser?.userType  == DigicelUser.UserType.Basic || digicelApi?.currentDigicelUser?.userType  == DigicelUser.UserType.Premium
        }
        

        if let type = policies["type"] as? String {
            switch type {
            case "Channel":
                  return digicelApi?.currentDigicelUser?.userType  == DigicelUser.UserType.Basic || digicelApi?.currentDigicelUser?.userType  == DigicelUser.UserType.Premium
            case "AtomEntry":
                 return digicelApi?.currentDigicelUser?.userType  == DigicelUser.UserType.Basic || digicelApi?.currentDigicelUser?.userType  == DigicelUser.UserType.Premium
            case "VodItem":
                return digicelApi?.currentDigicelUser?.userType  == DigicelUser.UserType.Basic || digicelApi?.currentDigicelUser?.userType  == DigicelUser.UserType.Premium
            case "Category":
                 return digicelApi?.currentDigicelUser?.userType  == DigicelUser.UserType.Basic || digicelApi?.currentDigicelUser?.userType  == DigicelUser.UserType.Premium
            case "Collection":
                return digicelApi?.currentDigicelUser?.userType  == DigicelUser.UserType.Basic || digicelApi?.currentDigicelUser?.userType  == DigicelUser.UserType.Premium
            default:
                 return digicelApi?.currentDigicelUser?.userType  == DigicelUser.UserType.Basic || digicelApi?.currentDigicelUser?.userType  == DigicelUser.UserType.Premium
            }
        }
        return false
   }
    
    /**
     `ZPLoginProviderUserDataProtocol` api. Call this to check if user has access to one or more items.
     */
    public func isUserComply(policies: [String : NSObject]) -> Bool {
        return itemIsLocked(policies: policies)
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
                            digicelApi.freeAccessToken()
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
                // present alert with error
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
            retVal = (str == "0")
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
            digicelApi.getUserSubscriptions(completion: { (succeeded, response, error) in
                if succeeded == true {
                    digicelApi.registerToCleeng(api: self.getCleengApi(), completion: { (succeeded, error) in
                        if succeeded == true {
                            digicelApi.freeAccessToken()
                            digicelApi.currentDigicelUser?.userType = .Basic
                            if self.isFreeAccess() == true {
                                completion(succeeded, error)
                                self.userDidSelectToClose()
                            }
                            else  {
                                completion(succeeded, error)
                                //check if need to continue app flow or present the digicel subscription screen
                                self.userDidSelectToClose()
                            }
                        }
                        else {
                            // present error alert and return completion(.failed)
                        }
                    })
                }
                else {
                    // present error alert and return completion(.failed)
                }
            })
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
