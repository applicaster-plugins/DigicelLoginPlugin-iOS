//
//  File.swift
//  DigicelToken
//
//  Created by Miri on 22/07/2019.
//

import Foundation


class DigicelToken: NSObject {
    struct TokenModelKeys {
        static let expiresIn = "expires_in"
        static let type = "token_type"
        static let accessToken = "access_token"
        static let refreshToken = "refresh_token"
        
    }
    var object:[String:Any]?
    
    var expiresIn: Float?
    var type: String?
    var accessToken: String?
    var refreshToken: String?
    
    init?(dict:[String:Any]) {
        super.init()
        
        object = dict
        expiresIn = dict[TokenModelKeys.expiresIn] as? Float
        type = dict[TokenModelKeys.type] as? String
        accessToken = dict[TokenModelKeys.accessToken] as? String
        refreshToken = dict[TokenModelKeys.refreshToken] as? String

    }
    
}
