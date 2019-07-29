//
//  DispatchQueue+Extension.swift
//  DigicelLoginPlugin
//
//  Created by Miri on 21 Tamuz 5779.
//

import Foundation

internal extension DispatchQueue {
    static func onMain(_ block: @escaping (() -> Void)) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }
}
