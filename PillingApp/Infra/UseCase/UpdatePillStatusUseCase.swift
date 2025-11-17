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
        memo: String?,
        takenAt: Date?
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
        print("순서:\(#fileID)")
        
        self.cycleRepository = cycleRepository
        self.timeProvider = timeProvider
    }
    
    func execute(
        cycle: Cycle,
        recordIndex: Int,
        newStatus: PillStatus,
        memo: String?,
        takenAt: Date? = nil
    ) -> Observable<Cycle> {
        // 🔍 [디버깅] UseCase 진입점
        print("🔍 [UpdatePillStatusUseCase] execute 호출")
        print("   📌 recordIndex: \(recordIndex)")
        print("   ✅ newStatus: \(newStatus)")
        print("   💾 전달받은 memo: '\(memo ?? "nil")'")
        print("   🕐 takenAt: \(String(describing: takenAt))")

        guard cycle.records.indices.contains(recordIndex) else {
            print("   ❌ recordIndex가 범위를 벗어남")
            return .just(cycle)
        }

        var updatedCycle = cycle
        let record = updatedCycle.records[recordIndex]
        let now = timeProvider.now

        print("   📝 기존 record.memo: '\(record.memo)'")

        // takenAt 결정 로직:
        // 1. 명시적으로 전달된 takenAt이 있으면 사용
        // 2. 없으면 기존 로직 적용 (상태가 taken이면 record.takenAt ?? now)
        let finalTakenAt: Date?
        if let providedTakenAt = takenAt {
            finalTakenAt = providedTakenAt
        } else {
            finalTakenAt = newStatus.isTaken ? (record.takenAt ?? now) : nil
        }

        let finalMemo = memo ?? record.memo
        print("   📦 최종 memo: '\(finalMemo)'")

        let updatedRecord = DayRecord(
            id: record.id,
            cycleDay: record.cycleDay,
            status: newStatus,
            scheduledDateTime: record.scheduledDateTime,
            takenAt: finalTakenAt,
            memo: finalMemo,
            createdAt: record.createdAt,
            updatedAt: now
        )

        print("   🚀 Repository로 전달할 updatedRecord.memo: '\(updatedRecord.memo)'")

        updatedCycle.records[recordIndex] = updatedRecord

        return cycleRepository.updateRecord(updatedRecord, in: cycle.id)
            .map { updatedCycle }
    }
}
