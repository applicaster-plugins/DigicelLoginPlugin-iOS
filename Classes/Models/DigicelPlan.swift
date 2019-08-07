//
//  File.swift
//  DigicelPlan
//
//  Created by Miri on 22/07/2019.
//

import Foundation

class DigicelPlan: NSObject {
    struct PlanModelKeys {
        static let name = "name"
        static let dateEnd = "dateEnd"
        static let dateStart = "dateStart"
        static let description = "description"
        static let planId = "planId"
        static let subscriptionId = "subscriptionId"

    }
    var object:[String:Any]?
    
    var name: String?
    var dateEnd: Int64?
    var dateStart: Int64?
    var planDescription: String?
    var planId: Int?
    var subscriptionId: Int?
    
    init?(dict:[String:Any]) {
        super.init()
        
        object = dict
        name = dict[PlanModelKeys.name] as? String
        dateEnd = dict[PlanModelKeys.dateEnd] as? Int64
        dateStart = dict[PlanModelKeys.dateStart] as? Int64
        planDescription = dict[PlanModelKeys.description] as? String
        planId = dict[PlanModelKeys.planId] as? Int
        subscriptionId = dict[PlanModelKeys.subscriptionId] as? Int

    }
    
}
