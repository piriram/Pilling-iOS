//
//  CalculateDashboardMessageUseCase.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/12/25.
//

import Foundation
import RxSwift
import UIKit

// MARK: - CalculateDashboardMessageUseCaseProtocol

protocol CalculateDashboardMessageUseCaseProtocol {
    func execute(cycle: PillCycle?, items: [DayItem]) -> DashboardMessage
}

// MARK: - CalculateDashboardMessageUseCase

final class CalculateDashboardMessageUseCase: CalculateDashboardMessageUseCaseProtocol {
    
    private let timeProvider: TimeProvider
    
    init(timeProvider: TimeProvider) {
        self.timeProvider = timeProvider
    }
    
    func execute(cycle: PillCycle?, items: [DayItem]) -> DashboardMessage {
        guard !items.isEmpty else {
            return DashboardMessage(text: "...", imageName: .rest, icon: .rest)
        }
        
        guard let todayItem = findRelevantItem(items: items) else {
            // 오늘 아이템이 없는데 어제 아이템이 12시간 초과한 경우 체크
            if let yesterdayItem = getYesterdayItem(items: items) {
                let now = timeProvider.now
                let twelveHours: TimeInterval = 12 * 60 * 60
                let timeSinceScheduled = now.timeIntervalSince(yesterdayItem.date)
                
                if timeSinceScheduled >= twelveHours,
                   !yesterdayItem.status.isTaken,
                   yesterdayItem.status != .rest {
                    return DashboardMessage(
                        text: "오늘은 두알을 복용하세요.",
                        imageName: .fire,
                        icon: .notTaken
                    )
                }
            }
            
            return DashboardMessage(text: "오늘은 잔디도 휴식중", imageName: .rest, icon: .rest)
        }
        
        if todayItem.status == .todayDelayed ||
           todayItem.status == .todayDelayedCritical ||
           todayItem.status == .todayNotTaken ||
           todayItem.status == .todayTakenDelayed ||
           todayItem.status == .todayTakenTooEarly ||
           todayItem.status == .todayTaken {
            let consecutiveMissed = calculateConsecutiveMissedDays(cycle: cycle)
            
            print("todayItem.status: \(todayItem.status), conservativeMissed: \(consecutiveMissed)")
            
            if consecutiveMissed >= 2,
               (todayItem.status == .todayTaken ||
                todayItem.status == .todayTakenDelayed ||
                todayItem.status == .todayTakenTooEarly) {
                return DashboardMessage(
                    text: "꾸준히 잔디를 심어주세요.",
                    imageName: .takingBefore,
                    icon: .taken
                )
            }
            
            if consecutiveMissed >= 2 {
                return DashboardMessage(
                    text: "저를 잊었나요...?",
                    imageName: .warning,
                    icon: .missed
                )
            }
            
            if let yesterdayItem = getYesterdayItem(items: items) {
                if case .missed = yesterdayItem.status,
                   consecutiveMissed == 1,
                   (todayItem.status == .todayTaken ||
                    todayItem.status == .todayTakenDelayed ||
                    todayItem.status == .todayTakenTooEarly) {
                    return DashboardMessage(
                        text: "한알을 더 먹어야 해요",
                        imageName: .takingBeforeTwo,
                        icon: .notTaken
                    )
                }
                
                if case .missed = yesterdayItem.status,
                   case .takenDouble = todayItem.status {
                    // 오늘 2알 복용으로 보정한 경우
                } else if case .missed = yesterdayItem.status,
                          (todayItem.status == .todayTaken ||
                           todayItem.status == .todayDelayed ||
                           todayItem.status == .todayDelayedCritical ||
                           todayItem.status == .takenTooEarly) {
                    return DashboardMessage(
                        text: "한알을 더 먹어야 해요",
                        imageName: .takingBeforeTwo,
                        icon: .notTaken
                    )
                } else if case .missed = yesterdayItem.status {
                    return DashboardMessage(
                        text: "오늘은 두알을 복용하세요.",
                        imageName: .fire,
                        icon: .notTaken
                    )
                }
            }
        }
        
        switch todayItem.status {
        case .todayTaken:
            return DashboardMessage(
                text: "잔디가 잘 자라고 있어요",
                imageName: .todayAfter,
                icon: .taken
            )
            
        case .todayTakenDelayed:
            return DashboardMessage(
                text: "2시간 조금 지났지만 괜찮아요!",
                imageName: .todayAfter,
                icon: .taken
            )
            
        case .todayTakenTooEarly:
            return DashboardMessage(
                text: "예정보다 2시간 이상 일찍 복용했어요",
                imageName: .todayAfter,
                icon: .taken
            )
            
        case .todayDelayed:
            return DashboardMessage(
                text: "잔디는 2시간을 초과하지 않게 심어주세요!",
                imageName: .groomy,
                icon: .missed
            )
            
        case .todayDelayedCritical:
            return DashboardMessage(
                text: "복용 시간이 4시간 이상 지났어요",
                imageName: .fire,
                icon: .notTaken
            )
            
        case .takenDouble:
            return DashboardMessage(
                text: "내일의 잔디도 부탁해요.",
                imageName: .todayAfter,
                icon: .taken
            )
            
        case .todayNotTaken:
            return DashboardMessage(
                text: "오늘의 잔디를 심어주세요",
                imageName: .takingBefore,
                icon: .notTaken
            )
            
        case .taken, .takenDelayed, .missed, .scheduled, .takenTooEarly:
            return DashboardMessage(
                text: "...",
                imageName: .rest,
                icon: .rest
            )
            
        case .rest:
            return DashboardMessage(
                text: "오늘은 잔디도 휴식중",
                imageName: .rest,
                icon: .rest
            )
        }
    }
    
    // MARK: - Private Methods
    
    private func findRelevantItem(items: [DayItem]) -> DayItem? {
        let now = timeProvider.now
        
        // 1. 오늘 날짜의 아이템 찾기
        if let todayItem = items.first(where: { timeProvider.isDate($0.date, inSameDayAs: now) }) {
            return todayItem
        }
        
        // 2. 어제 아이템이 12시간 윈도우 내인지 확인
        guard let yesterday = timeProvider.date(byAdding: .day, value: -1, to: now),
              let yesterdayItem = items.first(where: { timeProvider.isDate($0.date, inSameDayAs: yesterday) }) else {
            return nil
        }
        
        // 어제 복용 예정 시간으로부터 12시간 이내인지 확인
        let twelveHours: TimeInterval = 12 * 60 * 60
        let timeSinceScheduled = now.timeIntervalSince(yesterdayItem.date)
        
        if timeSinceScheduled < twelveHours,
           !yesterdayItem.status.isTaken,
           yesterdayItem.status != .rest {
            return yesterdayItem
        }
        
        return nil
    }
    
    private func getYesterdayItem(items: [DayItem]) -> DayItem? {
        let now = timeProvider.now
        guard let yesterday = timeProvider.date(byAdding: .day, value: -1, to: now) else {
            return nil
        }
        return items.first { timeProvider.isDate($0.date, inSameDayAs: yesterday) }
    }
    
    private func calculateConsecutiveMissedDays(cycle: PillCycle?) -> Int {
        guard let cycle = cycle else { return 0 }
        
        let now = timeProvider.now
        let today = timeProvider.startOfDay(for: now)
        
        var count = 0
        
        for record in cycle.records.reversed() {
            let recordDay = timeProvider.startOfDay(for: record.scheduledDateTime)
            
            guard recordDay < today else { continue }
            
            if case .rest = record.status {
                continue
            }
            
            // 12시간 윈도우 체크
            let twelveHours: TimeInterval = 12 * 60 * 60
            let timeSinceScheduled = now.timeIntervalSince(record.scheduledDateTime)
            
            if timeSinceScheduled >= twelveHours, !record.status.isTaken {
                count += 1
            } else if record.status.isTaken {
                break
            }
        }
        
        return count
    }
}
