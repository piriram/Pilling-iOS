//
//  PillStatusItem.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/21/25.
//

import Foundation

protocol PillStatusItem {
    var cycleDay: Int { get }
    var status: PillStatus { get }
    var scheduledDateTime: Date { get }
}

extension DayItem: PillStatusItem {}
extension PillRecord: PillStatusItem {}
