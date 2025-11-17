//
//  DateEnvironment.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 11/13/25.
//

import Foundation

// MARK: - DateEnvironment
struct DateEnvironment {
    let calendar: Calendar
    let now: Date
    
    static var `default`: DateEnvironment {
        .init(calendar: .current, now: Date())
    }
}
