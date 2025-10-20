//
//  DayItem.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/12/25.
//

import UIKit

// MARK: - Domain/Entities/DayItem.swift

struct DayItem {
    let cycleDay: Int
    let date: Date
    let status: PillStatus
    let scheduledDateTime: Date
}
