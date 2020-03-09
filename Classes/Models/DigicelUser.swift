//
//  File.swift
//  DigicelUser
//
//  Created by Miri on 22/07/2019.
//

import Foundation

class DigicelUser: Codable {
    enum UserType: String, Codable {
        case Free = "free", Basic = "basic", Premium = "premium"
    }
    
    enum SubscriberType: String, Codable {
        case InNetwork = "inNetwork", OffNetwork = "offNetwork"
    }
    
    struct UserModelKeys {
        static let email = "email"
        static let password = "password"
        static let msisdn = "msisdn"
        static let userGuid = "userGuid"
        static let userId = "userId"
        static let firstName = "firstName"
        static let lastName = "lastName"
        static let countryCode = "countryCode"
        static let international = "international"
        static let enabled = "enabled"
    }
    
    let email: String?
    let password: String?

    let msisdn: String?
    let userGuid: String?
    let userId: Float?
    
    let firstName: String?
    let lastName: String?

    let countryCode: String?
    let international: Bool?
    
    var digicelToken: DigicelToken? = nil
    var digicelActivePlans: [DigicelPlan]? = nil
    var subscriberType: SubscriberType? = nil
    
    var enabled: Bool?

    var userType = UserType.Free
    
    init(_ response: [String:Any]) {
        email = response[UserModelKeys.email] as? String
        password = response[UserModelKeys.password] as? String
        
        msisdn = response[UserModelKeys.msisdn] as? String
        userGuid = response[UserModelKeys.userGuid] as? String
        userId = response[UserModelKeys.userId] as? Float
        
        firstName = response[UserModelKeys.firstName] as? String
        lastName = response[UserModelKeys.lastName] as? String
        
        countryCode = response[UserModelKeys.countryCode] as? String
        international = response[UserModelKeys.international] as? Bool

        enabled = response[UserModelKeys.enabled] as? Bool
    }
}
