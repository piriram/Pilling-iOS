//
//  WidgetModel.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/17/25.
//

import Foundation

// MARK: - WidgetDisplayData

struct WidgetDisplayData {
    let cycleDay: Int
    let message: String
    let iconImageName: String
    let backgroundImageName: String
}

// MARK: - WidgetMessageType

enum WidgetMessageType {
    case waiting       // 잔디가 기다려요
    case plantingSeed  // 잔디를 심어보세요!
    case completed     // 잔디 심기 완료
    case resting       // 지금은 쉬는 시간
    case groomy
    case fire
    case success
    case yesterdayMissed
    case oneMorePill
    case empty         // 데이터 없음
    
    var message: String {
        switch self {
        case .waiting:
            return "잔디가 기다려요"
        case .plantingSeed:
            return "잔디를 심어보세요!"
        case .completed:
            return "한알 심기 완료"
        case .resting:
            return "지금은 쉬는 시간"
        case .empty:
            return "약을 설정해주세요"
        case .groomy:
            return "2시간 지났어요"
        case .fire:
            return "4시간 지났어요!"
        case .yesterdayMissed:
            return "오늘은 두알"
        case .oneMorePill:
            return "하나더"
        case .success:
            return "오늘 복용 완료."
        }
    }
    
    var iconImageName: String {
        switch self {
        case .waiting:
            return "widget_icon_waiting"
        case .plantingSeed:
            return "widget_icon_plant"
        case .completed:
            return "widget_icon_completed"
        case .resting:
            return "widget_icon_rest"
        case .groomy:
            return "widget_icon_groomy"
        case .fire,.yesterdayMissed:
            return "widget_icon_fire"
        case .success:
            return "widget_icon_success"
        case .empty:
            return "widget_icon_rest"
        case .oneMorePill:
            return "widget_icon_two"
        }
    }
    
    var backgroundImageName: String {
        switch self {
        case .waiting:
            return "widget_background_warning"
        case .groomy:
            return "widget_background_groomy"
        case .fire:
            return "widget_background_fire"
        default:
            return "widget_background_normal"
        }
    }
}
