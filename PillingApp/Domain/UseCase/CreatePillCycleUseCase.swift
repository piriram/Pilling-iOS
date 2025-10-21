//
//  CreatePillCycleUseCase.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/13/25.
//
import Foundation
import RxSwift

// MARK: - CreatePillCycleUseCaseProtocol

protocol CreatePillCycleUseCaseProtocol {
    func execute(
        pillInfo: PillInfo,
        startDate: Date,
        scheduledTime: String
    ) -> Observable<PillCycle>
}

// MARK: - CreatePillCycleUseCase

final class CreatePillCycleUseCase: CreatePillCycleUseCaseProtocol {
    
    private let cycleRepository: PillCycleRepositoryProtocol
    private let timeProvider: TimeProvider
    
    init(
        cycleRepository: PillCycleRepositoryProtocol,
        timeProvider: TimeProvider
    ) {
        self.cycleRepository = cycleRepository
        self.timeProvider = timeProvider
    }
    
    func execute(
        pillInfo: PillInfo,
        startDate: Date,
        scheduledTime: String
    ) -> Observable<PillCycle> {
        return Observable.deferred { [weak self] in
            guard let self = self else {
                return .error(PillCycleError.deallocated)
            }
            
            do {
                let cycle = try self.createCycle(
                    pillInfo: pillInfo,
                    startDate: startDate,
                    scheduledTime: scheduledTime
                )
                return self.cycleRepository
                    .saveCycle(cycle)
                    .map { cycle }
            } catch {
                return .error(error)
            }
        }
    }
    
    // MARK: - Private
    
    private func createCycle(
        pillInfo: PillInfo,
        startDate: Date,
        scheduledTime: String
    ) throws -> PillCycle {
        let now = timeProvider.now
        let todayStart = timeProvider.startOfDay(for: now)
        let cal = timeProvider.calendar
        
        let activeDays = pillInfo.takingDays
        let breakDays = pillInfo.breakDays
        let totalDays = activeDays + breakDays
        
        guard totalDays > 0 else {
            throw PillCycleError.invalidDateRange
        }
        
        var records: [PillRecord] = []
        records.reserveCapacity(totalDays)
        
        for day in 1...totalDays {
            let dayOffset = day - 1
            guard let dayDate = timeProvider.date(byAdding: .day, value: dayOffset, to: startDate) else {
                continue
            }
            
            // 날짜+시각 결합 (HH:mm 포맷)
            guard let scheduledDateTime = Date.combine(
                dayDate,
                with: scheduledTime,
                using: .time24Hour,
                calendar: cal,
                timeZone: timeProvider.timeZone
            ) else {
                throw PillCycleError.invalidTimeFormat
            }
            
            let dayStart = timeProvider.startOfDay(for: dayDate)
            
            let status: PillStatus
            if day > activeDays {
                status = .rest
            } else if dayStart > todayStart {
                status = .scheduled
            } else if cal.isDate(dayStart, inSameDayAs: todayStart) {
                status = .todayNotTaken
            } else {
                // 과거 일자: 기본값을 복용 완료로 표기 (도메인 정책에 맞게 조정 가능)
                status = .taken
            }
            
            let takenAt: Date? = (status == .taken) ? scheduledDateTime : nil
            
            let record = PillRecord(
                id: UUID(),
                cycleDay: day,
                status: status,
                scheduledDateTime: scheduledDateTime,
                takenAt: takenAt,
                memo: "",
                createdAt: now,
                updatedAt: now
            )
            records.append(record)
        }
        
        return PillCycle(
            id: UUID(),
            cycleNumber: 1,                 // 필요 시 외부에서 주입/증분
            startDate: startDate,
            activeDays: activeDays,
            breakDays: breakDays,
            scheduledTime: scheduledTime,   // 문자열 그대로 보존 (표시/편집용)
            records: records,
            createdAt: now
        )
    }
}
