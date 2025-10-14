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
            let today = calendar.startOfDay(for: now)
            
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
                let dayDateStartOfDay = calendar.startOfDay(for: dayDate)
                
                let status: PillStatus
                if day > activeDays {
                    // 휴약 기간
                    status = .rest
                } else if dayDateStartOfDay > today {
                    // 미래 날짜
                    status = .scheduled
                } else if dayDateStartOfDay == today {
                    // 오늘
                    status = .todayNotTaken
                } else {
                    // 과거 날짜 - 모두 정상 복용으로 가정
                    status = .taken
                }
                
                // taken 상태면 takenAt에 해당 날짜의 scheduledDateTime 설정
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

