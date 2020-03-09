//
//  DigicelTimedWebViewController.swift
//  DigicelLoginPlugin
//
//  Created by Miri on 15/07/2019.
//

import Foundation
import ApplicasterSDK
import ZappPlugins

let kCallbackURL = "https://applicaster.sportsmax";
let kCallBackMailURL = "https://digicelid.digicelgroup.com/management/identity.do?"
let kCallBackCodeURL = "https://digicelid.digicelgroup.com/otp/verify.do"

public protocol DigicelRedirectUriProtocol {
    func handleRedirectUriWith(params: [String : Any]?)
    func handleRedirectUriUpdateMail()
    func handleRedirectUriRegisterCompleted()
}

class DigicelTimedWebViewController: APTimedWebViewController {
    
    public var redirectUriDelegate: DigicelRedirectUriProtocol!
 
    public override func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void) {
        super.webView(webView, decidePolicyFor: navigationAction, decisionHandler: decisionHandler)
        let request = navigationAction.request
        
        if let urlString = request.url?.absoluteString {
            if((urlString.range(of: kCallBackMailURL) != nil)) {
                self.redirectUriDelegate.handleRedirectUriUpdateMail()
            }
        }
        
        if let urlString = request.url?.absoluteString,
            (urlString.range(of: kCallbackURL) != nil),
            let requestUrl = request.url,
            let queryDict = (requestUrl as NSURL).queryDictionary(),
            let code = queryDict["code"] as? String  {
            self.redirectUriDelegate.handleRedirectUriWith(params: ["code" : code])
            return
        }
        
        if let urlString = request.url?.absoluteString {
            if((urlString.starts(with: kCallbackURL))){
                self.redirectUriDelegate.handleRedirectUriRegisterCompleted()
            }
        }
    }
}
