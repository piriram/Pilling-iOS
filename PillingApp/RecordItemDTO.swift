//
//  RecordItemDTO.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 11/12/25.
//

import Foundation

// MARK: - DTO
struct RecordItemDTO {
    let category: String
    let percentage: Int
    let days: Int
    let colorHex: String
}

struct PeriodRecordDTO {
    let startDate: String
    let endDate: String
    let completionRate: Int
    let medicineName: String
    let records: [RecordItemDTO]
    let skippedCount: Int
    let isEmpty: Bool
}
