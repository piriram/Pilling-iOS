//
//  PillCycle.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/12/25.
//
import UIKit
import RxSwift
// MARK: - Domain/Entities/PillCycle.swift

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
// MARK: - Domain/RepositoryProtocols/PillCycleRepositoryProtocol.swift

protocol PillCycleRepositoryProtocol {
    func fetchCurrentCycle() -> Observable<PillCycle?>
    func saveCycle(_ cycle: PillCycle) -> Observable<Void>
    func updateRecord(_ record: PillRecord, in cycleID: UUID) -> Observable<Void>
    func deleteAllCycles() -> Observable<Void>
}
