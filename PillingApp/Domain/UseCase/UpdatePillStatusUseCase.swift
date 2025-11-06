//
//  UpdatePillStatusUseCase.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/12/25.
//

import Foundation
import RxSwift
// MARK: - UpdatePillStatusUseCaseProtocol

protocol UpdatePillStatusUseCaseProtocol {
    func execute(
        cycle: Cycle,
        recordIndex: Int,
        newStatus: PillStatus,
        memo: String?
    ) -> Observable<Cycle>
}

// MARK: - UpdatePillStatusUseCase

final class UpdatePillStatusUseCase: UpdatePillStatusUseCaseProtocol {
    private let cycleRepository: CycleRepositoryProtocol
    private let timeProvider: TimeProvider
    
    init(
        cycleRepository: CycleRepositoryProtocol,
        timeProvider: TimeProvider
    ) {
        self.cycleRepository = cycleRepository
        self.timeProvider = timeProvider
    }
    
    func execute(
        cycle: Cycle,
        recordIndex: Int,
        newStatus: PillStatus,
        memo: String?
    ) -> Observable<Cycle> {
        guard cycle.records.indices.contains(recordIndex) else {
            return .just(cycle)
        }
        
        var updatedCycle = cycle
        let record = updatedCycle.records[recordIndex]
        let now = timeProvider.now
        
        let takenAt: Date? = newStatus.isTaken ? (record.takenAt ?? now) : nil
        
        let updatedRecord = DayRecord(
            id: record.id,
            cycleDay: record.cycleDay,
            status: newStatus,
            scheduledDateTime: record.scheduledDateTime,
            takenAt: takenAt,
            memo: memo ?? record.memo,
            createdAt: record.createdAt,
            updatedAt: now
        )
        
        updatedCycle.records[recordIndex] = updatedRecord
        
        return cycleRepository.updateRecord(updatedRecord, in: cycle.id)
            .map { updatedCycle }
    }
}
