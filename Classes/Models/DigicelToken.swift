//
//  File.swift
//  DigicelToken
//
//  Created by Miri on 22/07/2019.
//

import Foundation


struct DigicelToken: Codable {
    struct TokenModelKeys {
        static let accessToken = "access_token"
        static let expiresIn = "expires_in"
        static let type = "token_type"
        static let refreshToken = "refresh_token"
    }
    
    let accessToken: String

    let expiresIn: Float?
    let type: String?
    let refreshToken: String?
        
    init?(_ response: [String: Any]) {
        guard let accessToken = response[TokenModelKeys.accessToken] as? String else {
            return nil
        }
        
        self.accessToken = accessToken

        self.expiresIn = response[TokenModelKeys.expiresIn] as? Float
        self.type = response[TokenModelKeys.type] as? String
        self.refreshToken = response[TokenModelKeys.refreshToken] as? String

    }
}
