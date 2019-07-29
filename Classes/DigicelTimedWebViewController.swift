//
//  DigicelTimedWebViewController.swift
//  DigicelLoginPlugin
//
//  Created by Miri on 15/07/2019.
//

import Foundation
import ApplicasterSDK
import ZappPlugins
import ZappLoginPluginsSDK

let kCallbackURL = "https://applicaster.sportsmax";

public protocol DigicelRedirectUriProtocol {
    func handleRedirectUriWith(params: [String : Any]?)
}

class DigicelTimedWebViewController: APTimedWebViewController {
    
    public var redirectUriDelegate: DigicelRedirectUriProtocol!
 
    public override func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void) {
        super.webView(webView, decidePolicyFor: navigationAction, decisionHandler: decisionHandler)
        let request = navigationAction.request
        
        guard let urlString = request.url?.absoluteString,
            (urlString.range(of: kCallbackURL) != nil),
            let requestUrl = request.url,
            let queryDict = (requestUrl as NSURL).queryDictionary(),
            let code = queryDict["code"] as? String else {
            return
        }
        self.redirectUriDelegate.handleRedirectUriWith(params: ["code" : code])
    }
}
