//
//  DigicelLoginApi.swift
//  DigicelLoginPlugin
//
//  Created by Miri on 12/07/2019.
//

import Foundation
import CleengLogin
import ZappPlugins
import ZappLoginPluginsSDK
import ApplicasterSDK

let kDigicelLoginAndSubscribeApiErrorDomain = "DigicelLoginAndSubscribeApi"

class DigicelLoginApi {
    
    public var configurationJSON: NSDictionary?

    public var cleengLogin: ZappCleengLogin?

    var currentDigicelUser: DigicelUser?
    
    var digicelToken: DigicelToken?

    /// Cleeng publisher id
    let publisherId: String
    
    let cleengWebServiceURL: String = "https://applicaster-cleeng-sso.herokuapp.com"
    
    let digiCelWebServiceURL = "https://digicelid.digicelgroup.com/selfcarev2"
    
    let digicelRedirectUri = "https://applicaster.sportsmax/auth/"
    
    let digicelSecretKey: String
    
    let digicelClientID: String


    required init(configurationJSON: NSDictionary?) {
        
        //mandatory params
        let publisherId: String! = configurationJSON?["cleeng_login_publisher_id"] as? String
        self.publisherId = publisherId
        
        let digicelSecretKey: String! = configurationJSON?["digicel_secret"] as? String
        self.digicelSecretKey = digicelSecretKey
        
        let digicelClientID: String! = configurationJSON?["digicel_client_id"] as? String
        self.digicelClientID = digicelClientID
    }
    
    //MARK: - Digicel API'S
    
    /// Call this api to get Digicel access token.
    /// - Parameter completion: The closure to execute when finish
    public func getAccessTokenWith(authCode: String?, completion: @escaping ((_ succeeded: Bool, _ accessToken: String?, _ error: Error?) -> Void)) {
        guard let code = authCode else {
            completion(false, nil ,NSError(domain: kDigicelLoginAndSubscribeApiErrorDomain, code: ErrorType.invalideCustomerToken.rawValue, userInfo: nil) as Error)
            return
        }
        
        let params = String(format: "code=%@&client_id=%@&client_secret=%@&redirect_uri=%@&grant_type=%@", encode(string: code),self.digicelClientID,self.digicelSecretKey,encode(string: digicelRedirectUri),"authorization_code")
        
        makePostRequest(apiName: "oauth2/token", params: params) { [weak self] (response, _, error) in
            guard let strongSelf = self else {
                return
            }
            
            if let response = response as? [String : Any] {
                guard let token = response["access_token"] as? String,
                    token.isEmpty == false else {
                    return completion(false, nil, error ?? NSError(domain: kDigicelLoginAndSubscribeApiErrorDomain, code: ErrorType.unknown.rawValue, userInfo: nil) as Error)
                }
                let dgToken = DigicelToken.init(dict: response)
                strongSelf.digicelToken = dgToken
                completion(true, token ,nil)
            } else {
                completion(false, nil, error ?? NSError(domain: kDigicelLoginAndSubscribeApiErrorDomain, code: ErrorType.unknown.rawValue, userInfo: nil) as Error)
            }
        }
    }
    
    /// Call this api to get Digicel user account.
    func getUserAccountWith(accessToken: String?, completion: @escaping ((_ succeeded: Bool, _ response: [String:Any]?, _ error: Error?) -> Void)) {
        guard let accessToken = accessToken else {
            completion(false, nil, NSError(domain: kDigicelLoginAndSubscribeApiErrorDomain, code: ErrorType.invalideCustomerToken.rawValue, userInfo: nil) as Error)
            return
        }
        let apiName = "account?scope=GET_ACCOUNT"
        let url = URL(string: "\(digiCelWebServiceURL)/\(apiName)")!
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        makeRequest(request: request) { [weak self] (response, _, error) in
            if let response = response as? [String:Any] {
                completion(true, response, nil)
            } else {
                completion(false, nil, error ?? NSError(domain: kDigicelLoginAndSubscribeApiErrorDomain, code: ErrorType.unknown.rawValue, userInfo: nil) as Error)
            }
        }
    }
    
    /// Call this api to get Digicel user Subscriptions.
    func getUserSubscriptions(completion: @escaping ((_ succeeded: Bool, _ response: [Any]?, _ error: Error?) -> Void)) {
        guard let digicelToken = digicelToken,
            let accessToken = digicelToken.accessToken else {
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
        request.setValue("ANDROID", forHTTPHeaderField: "Source")
        request.setValue("digicelid.digicelgroup.com", forHTTPHeaderField: "Host")
        request.setValue("no-cach", forHTTPHeaderField: "Cache-Control")

        makeRequest(request: request) { [weak self] (response, _, error) in
            guard let strongSelf = self else {
                return
            }
            if var response = response as? [Any] {
                var activePlans = [DigicelPlan]()
                for index in 0..<response.count {
                    if  let plan = response[index] as? [String : Any],
                        let subscriptions = plan["subscriptions"] as? [Any] {
                        for i in 0..<subscriptions.count {
                            if let subscription = subscriptions[i] as? [String : Any],
                                let digicelPlan = DigicelPlan.init(dict: subscription) {
                                activePlans.append(digicelPlan)
                            }
                        }
                    }
                }
                strongSelf.currentDigicelUser?.set(activePlans: activePlans)
                completion(true, response, nil)
            } else {
                completion(false, nil, error ?? NSError(domain: kDigicelLoginAndSubscribeApiErrorDomain, code: ErrorType.unknown.rawValue, userInfo: nil) as Error)
            }
        }
    }
    
    //MARK: - Cleeng API'S
    /// register to cleeng and get token / if user email already exists - get token
    func registerToCleeng(api: CleengLoginAndSubscribeApi?, completion: @escaping ((_ succeeded: Bool, _ error: Error?) -> Void)) {
        if let user = currentDigicelUser,
            let email = user.email {
            //Try to signup
            self.cleengRegisterCustomer(withEmail: email, api: api) { (succeeded, error) in
                //Signup has failed. If we tried to signup with email account & we got that user already exist, then make a login with email and publisherId without giving the user any indication
                if let error = error as NSError? {
                    if error.code == ErrorType.customerAlreadyExist.rawValue {
                        // generate cleeng customer token
                        self.cleengGenerateCustomerToken(withEmail: email, api: api, completion: completion)
                    }
                }
                else {
                    // return completion or alert
                }
            }
        }
        else {
            // return completion or alert
        }
    }
    
    /// Call this api to generate cleeng customer token.
    func cleengGenerateCustomerToken(withEmail email: String, api: CleengLoginAndSubscribeApi?, completion: @escaping ((_ succeeded: Bool, _ error: Error?) -> Void)) {
        let apiName = "generateCustomerToken"
        let url = URL(string: "\(cleengWebServiceURL)/\(apiName)")!
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let params: [String:Any] = ["email" : email,
                                    "publisherId" : self.publisherId]
        request.httpBody = try! JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
        
        makeRequest(request: request) { [weak self] (response, _, error) in
            if let response = response,
                let api = api {
                api.updateDataWith(email: email, response: response, error: error, completion: { (succeeded, error) in
                    completion(succeeded, error)
                })
            } else {
                completion(false, error ?? NSError(domain: kDigicelLoginAndSubscribeApiErrorDomain, code: ErrorType.unknown.rawValue, userInfo: nil) as Error)
            }
        }
    }
    
    //
    func cleengUpdateUserPackages(withEmail email: String , plan: DigicelPlan , completion: @escaping ((_ succeeded: Bool, _ error: Error?) -> Void)){
        let apiName = "https://c9brkksqb8.execute-api.eu-west-1.amazonaws.com/stage/subscriptions/create"
        let url = URL(string: apiName)!
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(publisherId)", forHTTPHeaderField: "Authorization")
        
        let params: [String:Any] = ["email" : email , "planId" : plan.planId , "subscriptionId" : plan.subscriptionId , "dateEnd" : plan.dateEnd ]
        request.httpBody = try! JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
        
        makeRequest(request: request) { [weak self] (response, _, error) in
            let res = response as? [String : Any]
        }
    }
    
    func freeAccessToken(completion: @escaping ((_ succeeded: Bool) -> Void)){
       let timestamp = NSDate().addingDays(30)?.timeIntervalSince1970
       let uuid = ZAAppConnector.sharedInstance().identityDelegate.getDeviceId()
       let url = "timestamp=\(timestamp!)&uuid=\(uuid!)"
       let data = (url).data(using: String.Encoding.utf8)
       let base64URL = data!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
       let tokenUrl = "sportsmaxds://fetchData?type=SPORTSMAX_TOKEN&url=" + base64URL ;
       let atom =   APAtomFeed.init(url: tokenUrl)
        APAtomFeedLoader.load(model: atom!) { (sucsses, model) in
            if let token  = model?.extensions["auth_token"] as? String{
                APAuthorizationManager.sharedInstance().setAuthorizationToken(token, withAuthorizationProviderID: "179")
                completion(true)
            }else{
                completion(false)
            }
        }
        
    }
    
    func cleengRegisterCustomer(withEmail email: String, api: CleengLoginAndSubscribeApi?, completion: @escaping ((_ succeeded: Bool, _ error: Error?) -> Void)) {
        let apiName = "register"
        let url = URL(string: "\(cleengWebServiceURL)/\(apiName)")!
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let locale = Locale.current
        guard let country = (locale as NSLocale).object(forKey: .countryCode) as? String else {
            completion(false, NSError(domain: "NSLocale", code: -1, userInfo: [NSLocalizedDescriptionKey : "NSLocale has no Country code"]) as Error)
            return
        }
       
        let params = [
            "publisherId" : self.publisherId,
            "email" : email,
            "country" : country,
            "locale" : "en_US",//localeIdentifier (Cleeng can't support locale such as en_IL)
            "currency" : "USD"//currency (Cleeng can't support currency such as ILS)
        ]
        
        request.httpBody = try! JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
        
        makeRequest(request: request) { [weak self] (response, _, error) in
            if let response = response,
                let api = api {
                api.updateDataWith(email: email, response: response, error: error, completion: { (succeeded, error) in
                    completion(succeeded, error)
                })
            } else {
                completion(false, error ?? NSError(domain: kDigicelLoginAndSubscribeApiErrorDomain, code: ErrorType.unknown.rawValue, userInfo: nil) as Error)
            }
        }
    }
    
    
    //MARK: - Make requests
    
    private func makePostRequest(apiName: String, params: String, completion: @escaping ((_ result: Any?, _ httpResponse: HTTPURLResponse?, _ error: Error?) -> Void)) {
        
        let updatedParams = params
        print("Send request: \(apiName) with params: \(updatedParams)")
        
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
    
    
    private func makeRequest(request: NSMutableURLRequest, completion: @escaping ((_ result: Any?, _ httpResponse: HTTPURLResponse?, _ error: Error?) -> Void)) {
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
            guard let data = data , let json = (try? JSONSerialization.jsonObject(with: data, options: [])) else {
                let err = error ?? (NSError(domain: kDigicelLoginAndSubscribeApiErrorDomain, code: DigicelLoginApi.ErrorType.unknown.rawValue, userInfo: nil) as Error)
                DispatchQueue.onMain {
                    completion(nil, (response as? HTTPURLResponse), err)
                }
                return
            }
            
            print("Response: \(json)")
            if let json = json as? [String:Any] , let code = json["code"] as? Int {
                let error: NSError
                if let message = json["message"] as? String {
                    error = NSError(domain: kDigicelLoginAndSubscribeApiErrorDomain, code: code, userInfo: [NSLocalizedDescriptionKey : message])
                } else {
                    error = NSError(domain: kDigicelLoginAndSubscribeApiErrorDomain, code: code, userInfo: nil)
                }
                
                DispatchQueue.onMain {
                    completion(nil, (response as? HTTPURLResponse), error as Error)
                }
            }
            else {
                DispatchQueue.onMain {
                    completion(json, (response as? HTTPURLResponse), error)
                }
            }
        }
        
        task.resume()
    }
    
    //MARK: - digicel api for token and account info
    /// getting access token and digicel account
    public func continueOAuthFlow(authCode: String?, completion: @escaping ((_ succeeded: Bool, _ response: Any?, _ error: Error?) -> Void)) {
        getAccessTokenWith(authCode: authCode) { (succeeded, accessToken, error) in
            if succeeded == true {
                // update the digi token model
                self.getUserAccountWith(accessToken: accessToken, completion: { (succeeded, response, error) in
                    if succeeded == true {
                        if let response = response {
                            // Create digicel user
                            let user = DigicelUser.init(dict: response)
                            self.currentDigicelUser = user
                            return completion(true, response, nil)
                        }
                        else {
                            return completion(true, nil, error ?? NSError(domain: kDigicelLoginAndSubscribeApiErrorDomain, code: ErrorType.unknown.rawValue, userInfo: nil) as Error)
                        }
                    }
                    else {
                        return completion(false, nil, error ?? NSError(domain: kDigicelLoginAndSubscribeApiErrorDomain, code: ErrorType.unknown.rawValue, userInfo: nil) as Error)
                    }
                })
            }
            else {
                return completion(false, nil, error ?? NSError(domain: kDigicelLoginAndSubscribeApiErrorDomain, code: ErrorType.unknown.rawValue, userInfo: nil) as Error)
            }
        }
    }
    
    //MARK: - Helpers

    private func encode(string: String) -> String {
        var retVal = ""
        if let encodedStr = string.addingPercentEncoding(withAllowedCharacters: CharacterSet(charactersIn: "!*'();:@&=+$,/?%#[]{} ").inverted) {
            retVal = encodedStr
        }
        return retVal
    }
    
    //MARK: - Api names
    
    enum ApiType: String {
        case getAccessToken = "oauth2/token"
        case getUserAccount = "account?scope=GET_ACCOUNT"
        case getUserSubscriptions = "me/provisioning/subscriptions?status=active"
        case cleengGenerateCustomerToken  = "generateCustomerToken"
    }

    //MARK: - Errors
    
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
    
}

