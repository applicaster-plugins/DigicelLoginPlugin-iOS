//
//  DigicelLoginApi.swift
//  DigicelLoginPlugin
//
//  Created by Miri on 12/07/2019.
//

import Foundation
import CleengLoginDigicel
import ZappPlugins
import Alamofire

let kDigicelLoginAndSubscribeApiErrorDomain = "DigicelLoginAndSubscribeApi"

enum ErrorType: Int {
    case unknown = -1
    case anotherLoginOrSignupInProcess = -2
    case alreadyLoggedInWithAnotherUser = -3
    case currentItemHasNoAuthorizationProvidersIDs = -5
    case subscriptionVerificationTimeOut = -6
    case loadTokensTimeOut = -7
    case noStoreProduct = -8
    case itemDataIsNotLoadedYet = -9
    case itemIsNotAvailable = -14
    
    case storeJsonDecodeError = -10
    case storeNotHaveReceiptData = -11
    case storeNoRemoteData = -12
    case storeReceiptInvalid = -13
    
    case invalideCustomerToken = 1
    case offerNotExist = 4
    case apiRequireEnterpriseAccount = 5
    case badCustomerEmailOrCustomerNotExist = 10
    case missingEmailOrPassword_orInvalideCustomerData = 11
    case inactiveCustomerAccount = 12
    case customerAlreadyExist = 13
    case ipAddressLimitExceeded = 14
    case invalideCustomerCredentials = 15
    case invalideResetPasswordTokenOrResetUrl = 16
    
    var error: Error {
        var userInfo: [String:Any]?
        if let message = self.errorMessage {
            userInfo = [NSLocalizedDescriptionKey : message]
        }
        return NSError(domain: kDigicelLoginAndSubscribeApiErrorDomain, code: self.rawValue, userInfo: userInfo) as Error
    }
    
    private var errorMessage: String? {
        switch self {
        case .alreadyLoggedInWithAnotherUser:
            return "Please logout before trying to login with another user"
        default:
            return nil
        }
    }
}

class DigicelLoginApi {
    private enum ApiType: String {
        case getAccessToken = "oauth2/token"
        case getUserAccount = "account?scope=GET_ACCOUNT"
        case getUserSubscriptions = "me/provisioning/subscriptions?status=active"
    }
    
    public var configurationJSON: NSDictionary?
    var currentDigicelUser: DigicelUser?
    let digiCelWebServiceURL: String
    let digicelRedirectUri = "https://applicaster.sportsmax/auth/"
    let digicelSecretKey: String
    let digicelClientID: String
    
    required init(configurationJSON: NSDictionary?) {
        self.configurationJSON = configurationJSON

        let digicelSecretKey: String! = configurationJSON?["digicel_secret"] as? String ?? ""
        self.digicelSecretKey = digicelSecretKey
        
        let digicelClientID: String! = configurationJSON?["digicel_client_id"] as? String ?? ""
        self.digicelClientID = digicelClientID
        
        self.digiCelWebServiceURL = configurationJSON?["digicel_base_url"] as? String ?? "https://digicelid.digicelgroup.com/selfcarev2"
        
        self.currentDigicelUser = DigicelCredentialsManager.loadDigicelUser()
    }
    
    public func handleOAuthFlow(authCode: String, completion: @escaping ((_ digicelUser: DigicelUser?, _ error: Error?) -> Void)) {
        func handleUserAccount(_ digicelUser: DigicelUser) {
            self.currentDigicelUser = digicelUser
            DigicelCredentialsManager.saveDigicelUser(digicelUser)
            
            completion(digicelUser, nil)
        }
        
        func handleAccessToken(_ digicelToken: DigicelToken) {
            self.fetchUserAccount(digicelToken.accessToken) { (succeeded, digicelUser, error) in
                guard succeeded, let digicelUser = digicelUser else {
                    completion(nil, error ?? NSError(domain: kDigicelLoginAndSubscribeApiErrorDomain, code: ErrorType.invalideCustomerToken.rawValue, userInfo: nil) as Error)
                    return
                }
                
                digicelUser.digicelToken = digicelToken
                handleUserAccount(digicelUser)
            }
        }
        
        self.fetchAccessToken(authCode) { (succeeded, digicelToken, error) in
            guard succeeded, let digicelToken = digicelToken else {
                completion(nil, error ?? NSError(domain: kDigicelLoginAndSubscribeApiErrorDomain, code: ErrorType.unknown.rawValue, userInfo: nil) as Error)
                return
            }
            
            handleAccessToken(digicelToken)
        }
    }
    
    func fetchUserSubscriptions(completion: @escaping ((_ succeeded: Bool, _ response: [Any]?, _ error: Error?) -> Void)) {
        guard
            let digicelUser = self.currentDigicelUser,
            let accessToken = digicelUser.digicelToken?.accessToken else {
                completion(false, nil, NSError(domain: kDigicelLoginAndSubscribeApiErrorDomain, code: ErrorType.invalideCustomerToken.rawValue, userInfo: nil) as Error)
                return
        }
        
        let apiName = "me/provisioning/subscriptions?status=active"
        let url = URL(string: "\(digiCelWebServiceURL)/\(apiName)")!
        let request = NSMutableURLRequest(url: url)
        
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("en_US", forHTTPHeaderField: "Lang")
        request.setValue("5000341", forHTTPHeaderField: "AndroidVer")
        request.setValue("SPORTSMAX", forHTTPHeaderField: "Source")
        request.setValue("digicelid.digicelgroup.com", forHTTPHeaderField: "Host")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        
        makeRequest(request: request) { (response, _, error) in
            if let response = response as? [Any] {
                var activePlans = [DigicelPlan]()
                
                for index in 0..<response.count {
                    if  let plan = response[index] as? [String : Any],
                        let subscriptions = plan["subscriptions"] as? [Any] {
                        for i in 0 ..< subscriptions.count {
                            if (plan["groupName"] as? String == "SPORTSMAX") {
                                if let subscription = subscriptions[i] as? [String : Any],
                                    let digicelPlan = DigicelPlan(dict: subscription) {
                                    activePlans.append(digicelPlan)
                                }
                            }
                        }
                    }
                }
                
                digicelUser.digicelActivePlans = activePlans
                DigicelCredentialsManager.saveDigicelUser(digicelUser)

                completion(true, activePlans, nil)
            }
            else {
                completion(false, nil, error ?? NSError(domain: kDigicelLoginAndSubscribeApiErrorDomain, code: ErrorType.unknown.rawValue, userInfo: nil) as Error)
            }
        }
    }
    
    func fetchSubscriberType(completion: @escaping ((_ success: Bool, _ error: Error?) -> Void)) {
        guard
            let digicelUser = self.currentDigicelUser,
            let accessToken = digicelUser.digicelToken?.accessToken else {
                completion(false, NSError(domain: kDigicelLoginAndSubscribeApiErrorDomain, code: ErrorType.invalideCustomerToken.rawValue, userInfo: nil) as Error)
                return
        }
        
        let apiname = "me/profile/subscribertype"
        let url = URL(string: "\(digiCelWebServiceURL)/\(apiname)")
        let request = NSMutableURLRequest(url: url!)
        
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("en", forHTTPHeaderField: "Lang")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("digicelid.digicelgroup.com", forHTTPHeaderField: "Host")
        
        makeRequest(request: request) { (result, response, error) in
            guard let response = response else {
                completion(false, nil)
                return
            }
            
            if (response.statusCode == 200) {
                digicelUser.subscriberType = .InNetwork
            }
            else if (response.statusCode == 404) {
                digicelUser.subscriberType = .OffNetwork
            }
            else {
                completion(false, nil)
                return
            }
            
            DigicelCredentialsManager.saveDigicelUser(digicelUser)
            completion(true, nil)
        }
    }
}

// MARK: - Private
extension DigicelLoginApi {
    fileprivate func fetchAccessToken(_ authCode: String, completion: @escaping ((_ succeeded: Bool, _ digicelToken: DigicelToken?, _ error: Error?) -> Void)) {
        let params = String(format: "code=%@&client_id=%@&client_secret=%@&redirect_uri=%@&grant_type=%@", encode(string: authCode), self.digicelClientID, self.digicelSecretKey, encode(string: digicelRedirectUri),"authorization_code")
        
        makePostRequest(apiName: "oauth2/token", params: params) { (response, _, error) in
            guard
                let response = response as? [String : Any],
                let token = response["access_token"] as? String,
                !token.isEmpty else {
                    completion(false, nil, error ?? NSError(domain: kDigicelLoginAndSubscribeApiErrorDomain, code: ErrorType.unknown.rawValue, userInfo: nil) as Error)
                    return
            }
            
            let digicelToken = DigicelToken(response)
            completion(true, digicelToken, nil)
        }
    }
    
    fileprivate func fetchUserAccount(_ accessToken: String, completion: @escaping ((_ succeeded: Bool, _ digicelUser: DigicelUser?, _ error: Error?) -> Void)) {
        let apiName = "account?scope=GET_ACCOUNT"
        let url = URL(string: "\(digiCelWebServiceURL)/\(apiName)")!
        
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        makeRequest(request: request) { (response, _, error) in
            guard let response = response as? [String: Any] else {
                completion(false, nil, error ?? NSError(domain: kDigicelLoginAndSubscribeApiErrorDomain, code: ErrorType.unknown.rawValue, userInfo: nil) as Error)
                return
            }
                            
            let digicelUser = DigicelUser(response)
            completion(true, digicelUser, nil)
        }
    }
}

// MARK: - Helpers
extension DigicelLoginApi {
    fileprivate func makePostRequest(apiName: String, params: String, completion: @escaping ((_ result: Any?, _ httpResponse: HTTPURLResponse?, _ error: Error?) -> Void)) {
        let updatedParams = params
        
        let url = URL(string: "\(digiCelWebServiceURL)/\(apiName)")!
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = updatedParams.data(using: .utf8)
        
        makeRequest(request: request) { (result, response, error) in
            completion(result, response, error)
        }
    }
    
    fileprivate func makeRequest(request: NSMutableURLRequest, completion: @escaping ((_ result: Any?, _ httpResponse: HTTPURLResponse?, _ error: Error?) -> Void)) {
        let request = request as URLRequest
        Alamofire.request(request).responseJSON { (responseObject) in
            guard case let .success(value) = responseObject.result else {
                completion(nil, responseObject.response, responseObject.error)
                return
            }
            
            if let object = value as? [String: Any], let code = object["code"] as? Int { // assume the code in response indicates failure
                let error: NSError
                if let message = object["message"] as? String {
                    error = NSError(domain: kDigicelLoginAndSubscribeApiErrorDomain, code: code, userInfo: [NSLocalizedDescriptionKey : message])
                }
                else {
                    error = NSError(domain: kDigicelLoginAndSubscribeApiErrorDomain, code: code, userInfo: nil)
                }
                
                completion(nil, responseObject.response, error)
                return
            }
            
            completion(value, responseObject.response, nil)
        }
    }
        
    fileprivate func encode(string: String) -> String {
        var retVal = ""
        if let encodedStr = string.addingPercentEncoding(withAllowedCharacters: CharacterSet(charactersIn: "!*'();:@&=+$,/?%#[]{} ").inverted) {
            retVal = encodedStr
        }
        return retVal
    }
}
