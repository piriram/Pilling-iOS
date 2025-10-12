//
//  CalculateDashboardMessageUseCase.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/12/25.
//

import Foundation
import RxSwift
// MARK: - Domain/UseCases/CalculateDashboardMessageUseCase.swift

protocol CalculateDashboardMessageUseCaseProtocol {
    func execute(cycle: PillCycle?, items: [DayItem]) -> DashboardMessage
}

final class CalculateDashboardMessageUseCase: CalculateDashboardMessageUseCaseProtocol {
    
    func execute(cycle: PillCycle?, items: [DayItem]) -> DashboardMessage {
        guard !items.isEmpty else {
            return DashboardMessage(text: "오늘은 잔디도 휴식중", imageName: .rest)
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        guard let todayItem = items.first(where: {
            calendar.isDate($0.date, inSameDayAs: now)
        }) else {
            return DashboardMessage(text: "오늘은 잔디도 휴식중", imageName: .rest)
        }
        
        let consecutiveMissed = calculateConsecutiveMissedDays(cycle: cycle)
        
        if consecutiveMissed >= 2 {
            return DashboardMessage(text: "저를 잊으셨나요 ㅠㅠ", imageName: .warning)
        }
        
        // 자동 감지: 실제로 오늘 2번 복용 버튼을 누른 경우
        if let cycle = cycle {
            let todaysTakenCount = cycle.records.filter { record in
                calendar.isDate(record.scheduledDateTime, inSameDayAs: now)
            }.filter { record in
                switch record.status {
                case .todayTaken, .todayTakenDelayed:
                    return true
                default:
                    return false
                }
            }.count
            if todaysTakenCount >= 2 {
                return DashboardMessage(
                    text: "오늘 2알 복용 완료! 보정까지 잘하셨어요",
                    imageName: .todayAfter
                )
            }
        }
        
        if let yesterdayItem = items.first(where: {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now) else {
                return false
            }
            return calendar.isDate($0.date, inSameDayAs: yesterday)
        }), case .missed = yesterdayItem.status {
            return DashboardMessage(
                text: "하루 빼먹었어요. 두알을 먹어야해요",
                imageName: .warning
            )
        }
        
        switch todayItem.status {
        case .todayTaken:
            return DashboardMessage(text: "잔디가 잘 자라고 있어요", imageName: .todayAfter)
        case .todayTakenDelayed:
            return DashboardMessage(
                text: "todayTakenDelayed",
                imageName: .todayAfter
            )
        case .todayDelayed:
            return DashboardMessage(
                text: "todayDelayed",
                imageName: .todayAfter
            )
        case .takenDouble:
            return DashboardMessage(
                text: "오늘 2알 복용 완료! 보정까지 잘하셨어요",
                imageName: .takingBeforeTwo
            )
        case .todayNotTaken:
            return DashboardMessage(text: "오늘의 약을 빠르게 먹어주세요", imageName: .takingBefore)
        case .rest:
            return DashboardMessage(text: "오늘은 잔디도 휴식중", imageName: .rest)
        default:
            return DashboardMessage(text: "default", imageName: .rest)
        }
    }
    
    private func calculateConsecutiveMissedDays(cycle: PillCycle?) -> Int {
        guard let cycle = cycle else { return 0 }
        
        let calendar = Calendar.current
        let now = Date()
        
        var count = 0
        for record in cycle.records.reversed() {
            let isPastOrToday = record.scheduledDateTime <= now
            guard isPastOrToday else { continue }
            
            let isNotTaken: Bool = {
                switch record.status {
                case .missed:
                    return true
                case .todayDelayed, .todayNotTaken:
                    return calendar.isDate(record.scheduledDateTime, inSameDayAs: now)
                default:
                    return false
                }
            }()
            
            if isNotTaken {
                count += 1
            } else {
                break
            }
        }
        
        return count
    }
}
