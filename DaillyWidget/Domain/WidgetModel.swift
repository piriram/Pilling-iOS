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
    case pilledTwo
    case empty         // 데이터 없음
    
    var message: String {
        switch self {
        case .waiting:
            return NSLocalizedString("widget.message_grass_waiting", bundle: .main, comment: "")
        case .plantingSeed:
            return NSLocalizedString("widget.message_plant_grass", bundle: .main, comment: "")
        case .completed:
            return NSLocalizedString("widget.message_one_pill_complete", bundle: .main, comment: "")
        case .resting:
            return NSLocalizedString("widget.message_rest_time", bundle: .main, comment: "")
        case .empty:
            return NSLocalizedString("widget.message_setup_pill", bundle: .main, comment: "")
        case .groomy:
            return NSLocalizedString("widget.message_over_two_hours", bundle: .main, comment: "")
        case .fire:
            return NSLocalizedString("widget.message_over_four_hours", bundle: .main, comment: "")
        case .pilledTwo:
            return NSLocalizedString("widget.message_two_today", bundle: .main, comment: "")
        case .success:
            return NSLocalizedString("widget.message_today_complete", bundle: .main, comment: "")
        }
    }
    
    var iconImageName: String {
        switch self {
        case .waiting:
            return "icon_noTaking"
        case .plantingSeed:
            return "icon_takingBefore"
        case .completed:
            return "icon_takingAfter"
        case .resting:
            return "icon_rest"
        case .groomy:
            return "icon_2hour"
        case .fire:
            return "icon_4hour"
        case .success:
            return "icon_good"
        case .empty:
            return "icon_plant"
        case .pilledTwo:
            return "icon_takingBeforeTwo"
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
