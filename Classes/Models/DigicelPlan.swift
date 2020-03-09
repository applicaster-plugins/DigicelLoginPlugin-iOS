//
//  File.swift
//  DigicelPlan
//
//  Created by Miri on 22/07/2019.
//

import Foundation

class DigicelPlan: Codable {
    struct PlanModelKeys {
        static let name = "name"
        static let dateEnd = "dateEnd"
        static let dateStart = "dateStart"
        static let description = "description"
        static let planId = "planId"
        static let subscriptionId = "subscriptionId"

    }
    
    let name: String?
    let dateEnd: Int64?
    let dateStart: Int64?
    let planDescription: String?
    let planId: Int?
    let subscriptionId: Int?
    
    var cleengOfferId: String?

    init?(dict: [String:Any]) {
        name = dict[PlanModelKeys.name] as? String
        dateEnd = dict[PlanModelKeys.dateEnd] as? Int64
        dateStart = dict[PlanModelKeys.dateStart] as? Int64
        planDescription = dict[PlanModelKeys.description] as? String
        planId = dict[PlanModelKeys.planId] as? Int
        subscriptionId = dict[PlanModelKeys.subscriptionId] as? Int
    }
}
