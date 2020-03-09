//
//  DigicelCredentialsManager.swift
//  DigicelLoginPlugin
//
//  Created by MSApps on 25/08/2019.
//

import Foundation


public class DigicelCredentialsManager {
    struct UserDefaultsKeys {
       static let digicelUser = "DigicelCredentialsManager.DigicelUser"
    }
    
    static func saveDigicelUser(_ digicelUser: DigicelUser?) {
        let data = digicelUser == nil ? nil : try? PropertyListEncoder().encode(digicelUser)
        UserDefaults.standard.set(data, forKey: UserDefaultsKeys.digicelUser)
    }
    
    static func loadDigicelUser() -> DigicelUser? {
        guard let data = UserDefaults.standard.object(forKey: UserDefaultsKeys.digicelUser) as? Data else {
            return nil
        }
        
        return try? PropertyListDecoder().decode(DigicelUser.self, from: data)
    }
}
