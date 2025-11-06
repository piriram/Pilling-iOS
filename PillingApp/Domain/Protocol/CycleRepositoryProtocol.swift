//
//  PillCycleRepositoryProtocol.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/12/25.
//

import Foundation
import RxSwift

// MARK: - PillCycleRepositoryProtocol

protocol CycleRepositoryProtocol {
    func fetchCurrentCycle() -> Observable<Cycle?>
    func saveCycle(_ cycle: Cycle) -> Observable<Void>
    func updateRecord(_ record: PillRecord, in cycleID: UUID) -> Observable<Void>
    func deleteAllCycles() -> Observable<Void>
    func fetchCycle(by id: UUID) -> Observable<Cycle?>
}
