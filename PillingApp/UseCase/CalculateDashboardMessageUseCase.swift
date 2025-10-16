//
//  CalculateDashboardMessageUseCase.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/12/25.
//

import Foundation
import RxSwift

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
            return DashboardMessage(text: "...", imageName: .rest)
        }
        
        guard let todayItem = findTodayItem(items: items) else {
            return DashboardMessage(text: "오늘은 잔디도 휴식중", imageName: .rest)
        }
        
        if todayItem.status == .todayDelayed || todayItem.status == .todayNotTaken {
            let consecutiveMissed = calculateConsecutiveMissedDays(cycle: cycle)
            
            if consecutiveMissed >= 2 {
                return DashboardMessage(
                    text: "저를 잊었나요...?",
                    imageName: .warning
                )
            }
            
            if let yesterdayItem = getYesterdayItem(items: items) {
                if case .missed = yesterdayItem.status, case .takenDouble = todayItem.status {
                    // 오늘 2알 복용으로 보정한 경우
                } else if case .missed = yesterdayItem.status, case .todayTaken = todayItem.status {
                    return DashboardMessage(
                        text: "한알을 더 먹어야 해요",
                        imageName: .takingBefore
                    )
                } else if case .missed = yesterdayItem.status {
                    return DashboardMessage(
                        text: "오늘은 두알을 복용하세요.",
                        imageName: .takingBefore
                    )
                }
            }
        }
        
        switch todayItem.status {
        case .todayTaken:
            return DashboardMessage(
                text: "잔디가 잘 자라고 있어요",
                imageName: .todayAfter
            )
            
        case .todayTakenDelayed:
            return DashboardMessage(
                text: "2시간 조금 지났지만 괜찮아요!\n피임 효과는 유지돼요",
                imageName: .todayAfter
            )
            
        case .todayDelayed:
            return DashboardMessage(
                text: "2시간이 지났어요!\n빨리 복용해주세요",
                imageName: .warning
            )
            
        case .takenDouble:
            return DashboardMessage(
                text: "오늘 2알 복용 완료!\n보정까지 잘하셨어요",
                imageName: .todayAfter
            )
            
        case .todayNotTaken:
            return DashboardMessage(
                text: "예정시간 전/2시간 이내예요. 잊지 말고 복용해주세요",
                imageName: .takingBefore
            )
            
        case .taken, .takenDelayed, .missed, .scheduled:
            return DashboardMessage(
                text: "오늘은 잔디도 휴식중",
                imageName: .rest
            )
            
        case .rest:
            return DashboardMessage(
                text: "오늘은 잔디도 휴식중",
                imageName: .rest
            )
        }
    }
    
    // MARK: - Private Methods
    
    private func findTodayItem(items: [DayItem]) -> DayItem? {
        let now = timeProvider.now
        return items.first { timeProvider.isDate($0.date, inSameDayAs: now) }
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
            
            if case .missed = record.status {
                count += 1
            } else if record.status.isTaken {
                break
            }
        }
        
        return count
    }
}
