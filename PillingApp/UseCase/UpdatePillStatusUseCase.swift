//
//  UpdatePillStatusUseCase.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/12/25.
//

import Foundation
import RxSwift
// MARK: - Domain/UseCases/UpdatePillStatusUseCase.swift

protocol UpdatePillStatusUseCaseProtocol {
    func execute(
        cycle: PillCycle,
        recordIndex: Int,
        newStatus: PillStatus
    ) -> Observable<PillCycle>
}

final class UpdatePillStatusUseCase: UpdatePillStatusUseCaseProtocol {
    private let cycleRepository: PillCycleRepositoryProtocol
    
    init(cycleRepository: PillCycleRepositoryProtocol) {
        self.cycleRepository = cycleRepository
    }
    
    func execute(
        cycle: PillCycle,
        recordIndex: Int,
        newStatus: PillStatus
    ) -> Observable<PillCycle> {
        guard cycle.records.indices.contains(recordIndex) else {
            return .just(cycle)
        }
        
        var updatedCycle = cycle
        var record = updatedCycle.records[recordIndex]
        let now = Date()
        
        let takenAt: Date? = newStatus.isTaken ? (record.takenAt ?? now) : nil
        
        let updatedRecord = PillRecord(
            id: record.id,
            cycleDay: record.cycleDay,
            status: newStatus,
            scheduledDateTime: record.scheduledDateTime,
            takenAt: takenAt,
            memo: record.memo,
            createdAt: record.createdAt,
            updatedAt: now
        )
        
        updatedCycle.records[recordIndex] = updatedRecord
        
        return cycleRepository.updateRecord(updatedRecord, in: cycle.id)
            .map { updatedCycle }
    }
}
