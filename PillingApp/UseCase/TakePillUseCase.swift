//
//  TakePillUseCase.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/12/25.
//

import Foundation
import RxSwift

// MARK: - TakePillUseCaseProtocol

protocol TakePillUseCaseProtocol {
    func execute(cycle: PillCycle, settings: UserSettings) -> Observable<PillCycle>
}

// MARK: - TakePillUseCase

final class TakePillUseCase: TakePillUseCaseProtocol {
    private let cycleRepository: PillCycleRepositoryProtocol
    private let timeProvider: TimeProvider
    
    init(
        cycleRepository: PillCycleRepositoryProtocol,
        timeProvider: TimeProvider
    ) {
        self.cycleRepository = cycleRepository
        self.timeProvider = timeProvider
    }
    
    func execute(cycle: PillCycle, settings: UserSettings) -> Observable<PillCycle> {
        let now = timeProvider.now
        
        guard let todayIndex = cycle.records.firstIndex(where: {
            timeProvider.isDate($0.scheduledDateTime, inSameDayAs: now)
        }) else {
            return .just(cycle)
        }
        
        var updatedCycle = cycle
        var record = updatedCycle.records[todayIndex]
        
        guard !record.status.isTaken else {
            return .just(cycle)
        }
        
        let timeDiff = now.timeIntervalSince(record.scheduledDateTime)
        let isWithinWindow = abs(timeDiff) <= Double(settings.delayThresholdMinutes * 60)
        let newStatus: PillStatus = isWithinWindow ? .todayTaken : .todayTakenDelayed
        
        let updatedRecord = PillRecord(
            id: record.id,
            cycleDay: record.cycleDay,
            status: newStatus,
            scheduledDateTime: record.scheduledDateTime,
            takenAt: now,
            memo: record.memo,
            createdAt: record.createdAt,
            updatedAt: now
        )
        
        updatedCycle.records[todayIndex] = updatedRecord
        
        return cycleRepository.updateRecord(updatedRecord, in: cycle.id)
            .map { updatedCycle }
    }
}
