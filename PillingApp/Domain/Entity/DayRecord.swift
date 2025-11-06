//
//  PillRecord.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/12/25.
//

import Foundation
// MARK: - PillInfo

struct PillInfo: Codable{
    let name: String
    let takingDays: Int
    let breakDays: Int
}

// MARK: - Domain/Entities/PillRecord.swift

struct DayRecord {
    let id: UUID
    let cycleDay: Int
    let status: PillStatus
    let scheduledDateTime: Date
    let takenAt: Date?
    let memo: String
    let createdAt: Date
    let updatedAt: Date
}

// 
