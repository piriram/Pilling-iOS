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
        
        // 1. 휴약 기간 체크
        if case .rest = todayItem.status {
            return DashboardMessage(text: "오늘은 잔디도 휴식중", imageName: .rest)
        }
        
        // 2. 연속 미복용 체크 (48시간 초과가 2일 이상)
        let consecutiveMissed = calculateConsecutiveMissedDays(cycle: cycle)
        if consecutiveMissed >= 2 {
            return DashboardMessage(
                text: "연속 2일 이상 놓쳤어요.\n새로운 시트를 시작하고 7일간 추가 피임을 사용하세요",
                imageName: .warning
            )
        }
        
        // 3. 어제 미복용 체크 (48시간 초과)
        if let yesterdayItem = getYesterdayItem(items: items, now: now, calendar: calendar) {
            if case .missed = yesterdayItem.status {
                return DashboardMessage(
                    text: "어제 약을 놓쳤어요 (48시간 초과).\n오늘 2알을 먹어야 해요",
                    imageName: .warning
                )
            }
        }
        
        // 4. 오늘 상태에 따른 메시지
        switch todayItem.status {
        case .todayTaken:
            // 정상 복용 완료 (24시간 이내)
            return DashboardMessage(
                text: "잔디가 잘 자라고 있어요",
                imageName: .todayAfter
            )
            
        case .todayTakenDelayed:
            // 지연 복용 완료 (24~48시간)
            return DashboardMessage(
                text: "24시간 조금 지났지만 괜찮아요!\n피임 효과는 유지돼요",
                imageName: .todayAfter
            )
            
        case .todayDelayed:
            // 24시간 초과, 아직 안먹음
            return DashboardMessage(
                text: "24시간이 지났어요!\n빨리 복용해주세요 (48시간 전까지)",
                imageName: .warning
            )
            
        case .takenDouble:
            // 2알 복용 완료
            return DashboardMessage(
                text: "오늘 2알 복용 완료!\n보정까지 잘하셨어요",
                imageName: .todayAfter
            )
            
        case .todayNotTaken:
            // 아직 안먹음 (24시간 이내)
            return DashboardMessage(
                text: "오늘의 약을 빠르게 먹어주세요",
                imageName: .takingBefore
            )
            
        case .taken, .takenDelayed, .missed, .scheduled:
            // 과거 데이터는 이미 처리됨
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
    
    private func getYesterdayItem(items: [DayItem], now: Date, calendar: Calendar) -> DayItem? {
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now) else {
            return nil
        }
        return items.first(where: {
            calendar.isDate($0.date, inSameDayAs: yesterday)
        })
    }
    
    private func calculateConsecutiveMissedDays(cycle: PillCycle?) -> Int {
        guard let cycle = cycle else { return 0 }
        
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        
        var count = 0
        
        // 어제부터 과거로 역순 체크 (오늘은 제외)
        for record in cycle.records.reversed() {
            let recordDay = calendar.startOfDay(for: record.scheduledDateTime)
            
            // 오늘이거나 미래면 스킵
            guard recordDay < today else { continue }
            
            // 휴약 기간은 카운트 안함
            if case .rest = record.status {
                continue
            }
            
            // 미복용(48시간 초과) 체크
            let isMissed: Bool = {
                switch record.status {
                case .missed:
                    return true
                default:
                    return false
                }
            }()
            
            if isMissed {
                count += 1
            } else if record.status.isTaken {
                // 복용한 날이 나오면 연속 끊김
                break
            }
        }
        
        return count
    }
}
