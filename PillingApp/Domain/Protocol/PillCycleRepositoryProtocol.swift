//
//  PillCycleRepositoryProtocol.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/12/25.
//

import Foundation
import RxSwift

// MARK: - PillCycleRepositoryProtocol

protocol PillCycleRepositoryProtocol {
    func fetchCurrentCycle() -> Observable<PillCycle?>
    func saveCycle(_ cycle: PillCycle) -> Observable<Void>
    func updateRecord(_ record: PillRecord, in cycleID: UUID) -> Observable<Void>
    func deleteAllCycles() -> Observable<Void>
}
