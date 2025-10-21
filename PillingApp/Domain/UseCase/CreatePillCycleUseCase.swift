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
            
            let cycle = self.createCycle(
                pillInfo: pillInfo,
                startDate: startDate,
                scheduledTime: scheduledTime
            )
            
            return self.cycleRepository.saveCycle(cycle)
                .map { cycle }
        }
    }
    
    // MARK: - Private Methods
    
    private func createCycle(
        pillInfo: PillInfo,
        startDate: Date,
        scheduledTime: String
    ) -> PillCycle {
        let now = timeProvider.now
        let today = timeProvider.startOfDay(for: now)
        
        let activeDays = pillInfo.takingDays
        let breakDays = pillInfo.breakDays
        let totalDays = activeDays + breakDays
        
        var records: [PillRecord] = []
        
        for day in 1...totalDays {
            let dayOffset = day - 1
            guard let dayDate = timeProvider.date(byAdding: .day, value: dayOffset, to: startDate) else {
                continue
            }
            
            let scheduledDateTime = combineDateAndTime(
                date: dayDate,
                timeString: scheduledTime
            )
            
            let dayDateStartOfDay = timeProvider.startOfDay(for: dayDate)
            
            let status: PillStatus
            if day > activeDays {
                status = .rest
            } else if dayDateStartOfDay > today {
                status = .scheduled
            } else if dayDateStartOfDay == today {
                status = .todayNotTaken
            } else {
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
        
        // timeZoneIdentifier 제거 (기존 PillCycle 구조 유지)
        return PillCycle(
            id: UUID(),
            cycleNumber: 1,
            startDate: startDate,
            activeDays: activeDays,
            breakDays: breakDays,
            scheduledTime: scheduledTime,
            records: records,
            createdAt: now
        )
    }
    
    private func combineDateAndTime(date: Date, timeString: String) -> Date {
        let calendar = timeProvider.calendar
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        timeFormatter.timeZone = timeProvider.timeZone
        
        guard let timeDate = timeFormatter.date(from: timeString) else {
            return date
        }
        
        let timeComponents = calendar.dateComponents([.hour, .minute], from: timeDate)
        
        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        combined.timeZone = timeProvider.timeZone
        
        return calendar.date(from: combined) ?? date
    }
}

// MARK: - PillCycleError

enum PillCycleError: Error {
    case deallocated
    case invalidTimeFormat
    case invalidDateRange
    
    var localizedDescription: String {
        switch self {
        case .deallocated:
            return "UseCase가 해제되었습니다"
        case .invalidTimeFormat:
            return "시간 형식이 올바르지 않습니다"
        case .invalidDateRange:
            return "날짜 범위가 유효하지 않습니다"
        }
    }
}
