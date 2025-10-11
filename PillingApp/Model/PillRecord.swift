//
//  PillRecord.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/12/25.
//

import Foundation
// MARK: - Domain/Entities/PillRecord.swift

struct PillRecord {
    let id: UUID
    let cycleDay: Int
    let status: PillStatus
    let scheduledDateTime: Date
    let takenAt: Date?
    let createdAt: Date
    let updatedAt: Date
}
