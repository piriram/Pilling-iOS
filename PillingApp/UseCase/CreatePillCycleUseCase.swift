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
    
    init(cycleRepository: PillCycleRepositoryProtocol) {
        self.cycleRepository = cycleRepository
    }
    
    func execute(
        pillInfo: PillInfo,
        startDate: Date,
        scheduledTime: String
    ) -> Observable<PillCycle> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(NSError(domain: "CreatePillCycleUseCase", code: -1))
                return Disposables.create()
            }
            
            let calendar = Calendar.current
            let now = Date()
            
            let activeDays = pillInfo.takingDays
            let breakDays = pillInfo.breakDays
            let totalDays = activeDays + breakDays
            
            var records: [PillRecord] = []
            
            for day in 1...totalDays {
                let dayOffset = day - 1
                guard let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else {
                    continue
                }
                
                let scheduledDateTime = self.combineDateAndTime(date: dayDate, timeString: scheduledTime)
                
                let status: PillStatus
                if day > activeDays {
                    // 휴약 기간
                    status = .rest
                } else {
                    let isToday = calendar.isDate(dayDate, inSameDayAs: now)
                    let isFuture = dayDate > calendar.startOfDay(for: now)
                    
                    if isFuture {
                        status = .scheduled
                    } else if isToday {
                        status = .todayNotTaken
                    } else {
                        status = .missed
                    }
                }
                
                let record = PillRecord(
                    id: UUID(),
                    cycleDay: day,
                    status: status,
                    scheduledDateTime: scheduledDateTime,
                    takenAt: nil,
                    createdAt: now,
                    updatedAt: now
                )
                records.append(record)
            }
            
            let cycle = PillCycle(
                id: UUID(),
                cycleNumber: 1,
                startDate: startDate,
                activeDays: activeDays,
                breakDays: breakDays,
                scheduledTime: scheduledTime,
                records: records,
                createdAt: now
            )
            
            // CoreData에 저장
            self.cycleRepository.saveCycle(cycle)
                .subscribe(
                    onNext: {
                        observer.onNext(cycle)
                        observer.onCompleted()
                    },
                    onError: { error in
                        observer.onError(error)
                    }
                )
                .dispose()
            
            return Disposables.create()
        }
    }
    
    // MARK: - Private Methods
    
    private func combineDateAndTime(date: Date, timeString: String) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
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
        
        return calendar.date(from: combined) ?? date
    }
}
