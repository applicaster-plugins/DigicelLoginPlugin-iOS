//
//  File.swift
//  DigicelUser
//
//  Created by Miri on 22/07/2019.
//

import Foundation

class DigicelUser: NSObject {
    struct UserModelKeys {
        static let email = "email"
        static let password = "password"
        static let msisdn = "msisdn"
        static let userGuid = "userGuid"
        static let userId = "userId"
        static let firstName = "firstName"
        static let lastName = "lastName"
        static let countryCode = "countryCode"
        static let enabled = "enabled"
        static let international = "international"

    }
    var object:[String:Any]?
    
    var token: DigicelToken?
    var email: String?
    var password: String?
    var msisdn: String?
    var userGuid: String?
    var userId: Float?
    var firstName: String?
    var lastName: String?
    var countryCode: String?
    var enabled: Bool?
    var international: Bool?
    var digicelActivePlans: [DigicelPlan]?

    init(userEmail:String) {
        super.init()
        email = userEmail
    }
    
    init?(dict:[String:Any]) {
        super.init()
        
        object = dict
        email = dict[UserModelKeys.email] as? String
        password = dict[UserModelKeys.password] as? String
        msisdn = dict[UserModelKeys.msisdn] as? String
        userGuid = dict[UserModelKeys.userGuid] as? String
        userId = dict[UserModelKeys.userId] as? Float
        firstName = dict[UserModelKeys.firstName] as? String
        lastName = dict[UserModelKeys.lastName] as? String
        countryCode = dict[UserModelKeys.countryCode] as? String
        enabled = dict[UserModelKeys.enabled] as? Bool
        international = dict[UserModelKeys.international] as? Bool

    }

    func set(userToken: DigicelToken?) {
        let t = userToken
        token = t
    }
    
    func set(userEmail: String?) {
        let e = userEmail
        email = e
    }
    
    func set(activePlans: [DigicelPlan]?) {
        let plans = activePlans
        digicelActivePlans = plans
    }
}
