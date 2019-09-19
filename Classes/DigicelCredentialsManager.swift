//
//  DigicelCredentialsManager.swift
//  DigicelLoginPlugin
//
//  Created by MSApps on 25/08/2019.
//

import Foundation


@objc public class DigicelCredentialsManager: NSObject{
    
    enum CredentialsType: String {
        case digicelUserToken = "digicelUserToken"
        case digicelUserType = "digicelUserType"
        case digicelSubscriberType = "digicelSubscriberType"
        case digicelPlans = "digicelPlans"
        case digicelPlanOfferID = "digicelPlanOfferID"
        case digicelUserEmail = "digicelUserEmail"
        
    }
    
    static func saveDigicelUserEmail(email: String?){
        UserDefaults.standard.set(email, forKey: CredentialsType.digicelUserEmail.rawValue)
    }
    
    static func getDigicelUserEmail() -> String?{
        return UserDefaults.standard.string(forKey: CredentialsType.digicelUserEmail.rawValue)
    }
    
    static func saveDigicelUserToken(token: String){
       UserDefaults.standard.set(token, forKey: CredentialsType.digicelUserToken.rawValue)
    }
    
    static func getDigicelUserToken() -> String?{
     return UserDefaults.standard.string(forKey: CredentialsType.digicelUserToken.rawValue)
    }
    
    static func saveDigicelUserType(type: DigicelUser.UserType?){
        UserDefaults.standard.set(type?.rawValue, forKey: CredentialsType.digicelUserType.rawValue)
    }
    
    static func getDigicelUserType() -> DigicelUser.UserType?{
        let type = DigicelUser.UserType(rawValue: (UserDefaults.standard.string(forKey: CredentialsType.digicelUserType.rawValue) ?? DigicelUser.UserType.Free.rawValue ))
        return type
       
    }
    
    static func saveDigicelSubscriberType(type: DigicelUser.SubscriberType?){
        UserDefaults.standard.set(type?.rawValue, forKey: CredentialsType.digicelSubscriberType.rawValue)
    }
    
    static func getDigicelSubscriberType() -> DigicelUser.SubscriberType?{
        let type = DigicelUser.SubscriberType(rawValue: (UserDefaults.standard.string(forKey: CredentialsType.digicelSubscriberType.rawValue) ?? ""))
        return type
    }
    
    static func saveDigicelPlanOfferId(type: String?){
        UserDefaults.standard.set(type, forKey: CredentialsType.digicelPlanOfferID.rawValue)
    }
    
    static func getDigicelPlanOfferId() -> String?{
        return UserDefaults.standard.string(forKey: CredentialsType.digicelPlanOfferID.rawValue)
    }
    
    static func saveDigicelPlanes(dic: [String:Any]?){
        UserDefaults.standard.set(dic, forKey: CredentialsType.digicelPlans.rawValue)
    }
    
    static func getDigicelPlanes() ->  [String:Any]?{
        return UserDefaults.standard.dictionary(forKey: CredentialsType.digicelPlans.rawValue)
    }
}
