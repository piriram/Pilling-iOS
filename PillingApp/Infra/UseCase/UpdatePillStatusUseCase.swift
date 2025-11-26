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

        // 과거 날짜를 scheduled 또는 notTaken으로 바꾸려는 경우 자동으로 missed로 변환
        let finalStatus: PillStatus
        if newStatus == .scheduled || newStatus == .notTaken {
            let calendar = Calendar.current
            let startOfToday = calendar.startOfDay(for: now)
            let isPastDate = record.scheduledDateTime < startOfToday

            print("🔍 [UpdatePillStatusUseCase] 과거 날짜 체크")
            print("   현재시각: \(now)")
            print("   오늘시작: \(startOfToday)")
            print("   예정시각: \(record.scheduledDateTime)")
            print("   과거날짜: \(isPastDate)")
            print("   요청상태: \(newStatus.rawValue) → 최종: \(isPastDate ? "missed" : newStatus.rawValue)")

            if isPastDate {
                finalStatus = .missed
            } else {
                finalStatus = newStatus
            }
        } else {
            finalStatus = newStatus
        }

        // takenAt 결정 로직:
        // 1. 명시적으로 전달된 takenAt이 있으면 사용
        // 2. 없으면 기존 로직 적용 (상태가 taken이면 record.takenAt ?? now)
        let finalTakenAt: Date?
        if let providedTakenAt = takenAt {
            finalTakenAt = providedTakenAt
        } else {
            finalTakenAt = finalStatus.isTaken ? (record.takenAt ?? now) : nil
        }

        let finalMemo = memo ?? record.memo
        
        let updatedRecord = DayRecord(
            id: record.id,
            cycleDay: record.cycleDay,
            status: finalStatus,
            scheduledDateTime: record.scheduledDateTime,
            takenAt: finalTakenAt,
            memo: finalMemo,
            createdAt: record.createdAt,
            updatedAt: now
        )

        print("✅ [UpdatePillStatusUseCase] 레코드 업데이트")
        print("   인덱스: \(recordIndex)")
        print("   이전 상태: \(record.status.rawValue)")
        print("   최종 상태: \(finalStatus.rawValue)")

        updatedCycle.records[recordIndex] = updatedRecord

        return cycleRepository.updateRecord(updatedRecord, in: cycle.id)
            .map { updatedCycle }
    }
}
