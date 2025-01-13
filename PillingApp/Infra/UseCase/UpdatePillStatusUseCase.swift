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
        
        guard cycle.records.indices.contains(recordIndex) else {
            print("   ❌ recordIndex가 범위를 벗어남")
            return .just(cycle)
        }
        
        var updatedCycle = cycle
        let record = updatedCycle.records[recordIndex]
        let now = timeProvider.now
        
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
        
        updatedCycle.records[recordIndex] = updatedRecord
        
        return cycleRepository.updateRecord(updatedRecord, in: cycle.id)
            .map { updatedCycle }
    }
}
