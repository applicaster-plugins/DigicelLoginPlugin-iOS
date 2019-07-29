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
    var dateEnd: Float?
    var dateStart: Float?
    var planDescription: String?
    var planId: String?
    var subscriptionId: String?
    
    init?(dict:[String:Any]) {
        super.init()
        
        object = dict
        name = dict[PlanModelKeys.name] as? String
        dateEnd = dict[PlanModelKeys.dateEnd] as? Float
        dateStart = dict[PlanModelKeys.dateStart] as? Float
        planDescription = dict[PlanModelKeys.description] as? String
        planId = dict[PlanModelKeys.planId] as? String
        subscriptionId = dict[PlanModelKeys.subscriptionId] as? String

    }
    
}
