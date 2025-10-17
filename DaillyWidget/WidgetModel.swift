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
    case empty         // 데이터 없음
    
    var message: String {
        switch self {
        case .waiting:
            return "잔디가 기다려요"
        case .plantingSeed:
            return "잔디를 심어보세요!"
        case .completed:
            return "잔디 심기 완료"
        case .resting:
            return "지금은 쉬는 시간"
        case .empty:
            return "..."
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
        case .empty:
            return "widget_icon_rest"
        }
    }
    
    var backgroundImageName: String {
        switch self {
        case .waiting:
            return "widget_background_warning"
        case .plantingSeed, .completed, .resting, .empty:
            return "widget_background_normal"
        }
    }
}
