//
//  CoreDataManager.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/12/25.
//

import UIKit
import RxSwift
// MARK: - Data/DataSources/CoreDataManager.swift

// CoreData Stack 관리
// 실제 구현은 CoreData 모델 설정 후 작성
final class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    // TODO: NSPersistentContainer 설정
    // TODO: NSManagedObjectContext 관리
    // TODO: CRUD 메서드 구현
}
// MARK: - Data/Repositories/CoreDataPillCycleRepository.swift

final class CoreDataPillCycleRepository: PillCycleRepositoryProtocol {
    private let coreDataManager: CoreDataManager
    
    init(coreDataManager: CoreDataManager) {
        self.coreDataManager = coreDataManager
    }
    
    func fetchCurrentCycle() -> Observable<PillCycle?> {
        // TODO: CoreData에서 현재 사이클 조회
        // 임시로 Mock 데이터 반환
        return .just(createMockCycle())
    }
    
    func saveCycle(_ cycle: PillCycle) -> Observable<Void> {
        // TODO: CoreData에 사이클 저장
        return .just(())
    }
    
    func updateRecord(_ record: PillRecord, in cycleID: UUID) -> Observable<Void> {
        // TODO: CoreData에서 레코드 업데이트
        return .just(())
    }
    
    // MARK: - Mock Data (임시)
    
    private func createMockCycle() -> PillCycle {
        let calendar = Calendar.current
        let now = Date()
        
        guard let startDate = calendar.date(byAdding: .day, value: -7, to: now) else {
            fatalError("Failed to calculate start date")
        }
        
        let activeDays = 21
        let breakDays = 7
        let totalDays = activeDays + breakDays
        
        let mockPattern: [Int: PillStatus] = [
            1: .taken,
            2: .taken,
            3: .missed,
            4: .takenDouble,
            5: .taken,
            6: .taken,
            7: .taken,
            8: .todayNotTaken
        ]
        
        var records: [PillRecord] = []
        let scheduledTime = UserSettings.default.scheduledTime
        
        for day in 1...totalDays {
            let dayOffset = day - 1
            guard let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else {
                continue
            }
            
            let scheduledDateTime = combineDateAndTime(date: dayDate, time: scheduledTime)
            
            let status: PillStatus
            if let mockStatus = mockPattern[day] {
                status = mockStatus
            } else {
                status = calculateStatus(
                    for: dayDate,
                    cycleDay: day,
                    scheduledDateTime: scheduledDateTime,
                    activeDays: activeDays,
                    totalDays: totalDays,
                    settings: .default
                )
            }
            
            let takenAt: Date? = status.isTaken ? dayDate : nil
            
            let record = PillRecord(
                id: UUID(),
                cycleDay: day,
                status: status,
                scheduledDateTime: scheduledDateTime,
                takenAt: takenAt,
                createdAt: now,
                updatedAt: now
            )
            records.append(record)
        }
        
        return PillCycle(
            id: UUID(),
            cycleNumber: 1,
            startDate: startDate,
            activeDays: activeDays,
            breakDays: breakDays,
            scheduledTime: timeString(from: scheduledTime),
            records: records,
            createdAt: now
        )
    }
    
    private func calculateStatus(
        for date: Date,
        cycleDay: Int,
        scheduledDateTime: Date,
        activeDays: Int,
        totalDays: Int,
        settings: UserSettings
    ) -> PillStatus {
        let calendar = Calendar.current
        let now = Date()
        
        if cycleDay > activeDays {
            return .rest
        }
        
        let isToday = calendar.isDate(date, inSameDayAs: now)
        let isFuture = date > calendar.startOfDay(for: now)
        
        if isFuture {
            return .scheduled
        }
        
        if isToday {
            let timeDiff = now.timeIntervalSince(scheduledDateTime)
            let isWithinWindow = abs(timeDiff) <= Double(settings.delayThresholdMinutes * 60)
            
            if isWithinWindow {
                return .todayNotTaken
            } else {
                return .todayDelayed
            }
        }
        
        return .missed
    }
    
    private func combineDateAndTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        
        return calendar.date(from: combined) ?? date
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
