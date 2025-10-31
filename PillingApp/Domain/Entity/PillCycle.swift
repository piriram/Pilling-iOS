//
//  PillCycle.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/12/25.
//

import Foundation

// MARK: - PillCycle

struct PillCycle {
    let id: UUID
    let cycleNumber: Int
    let startDate: Date
    let activeDays: Int
    let breakDays: Int
    var scheduledTime: String
    var records: [PillRecord]
    let createdAt: Date
    
    var totalDays: Int { activeDays + breakDays }
    
    func isActiveDay(forDay day: Int) -> Bool {
        return day >= 1 && day <= activeDays
    }
    
    func isBreakDay(forDay day: Int) -> Bool {
        return day > activeDays && day <= totalDays
    }
}
