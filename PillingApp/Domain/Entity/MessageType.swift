import Foundation

/// 메시지 타입 enum
enum MessageType {
    case empty
    case resting
    case waiting
    case plantingSeed
    case success
    case groomy
    case fire
    case pilledTwo
    case todayAfter
    case takingBeforeTwo
    case takingBefore
    case warning
    case takenDelayedOk
    case takenTooEarly
    case takenDoubleComplete
    case beforeStart(daysUntilStart: Int)
    
    var text: String {
        switch self {
        case .empty:
            return "약을 설정해주세요"
        case .resting:
            return "오늘은 잔디도 휴식중"
        case .waiting:
            return "저를 잊었나요...?"
        case .plantingSeed:
            return "오늘의 잔디를 심어주세요"
        case .success:
            return "꾸준히 잔디를 심어주세요."
        case .groomy:
            return "잔디는 2시간을 초과하지 않게 심어주세요!"
        case .fire:
            return "복용 시간이 4시간 이상 지났어요"
        case .pilledTwo:
            return "오늘은 두알을 복용하세요."
        case .todayAfter:
            return "잔디가 잘 자라고 있어요"
        case .takingBeforeTwo:
            return "어제 미복용했다면 오늘은 2알!!"
        case .takingBefore:
            return "매일 2시간 이내의 같은 시간에 복용해주세요."
        case .warning:
            return "한알을 더 먹어야 해요"
        case .takenDelayedOk:
            return "2시간 지났지만 괜찮아요!"
        case .takenTooEarly:
            return "예정보다 2시간 이상 일찍 복용했어요"
        case .takenDoubleComplete:
            return "내일의 잔디도 부탁해요."
        case .beforeStart(let daysUntilStart):
            if daysUntilStart == 0 {
                return "오늘부터 복용을 시작해요"
            } else if daysUntilStart == 1 {
                return "내일부터 복용을 시작해요"
            } else {
                return "복용 시작까지 \(daysUntilStart)일 남았어요"
            }
        }
    }
    
    var widgetText: String? {
        switch self {
        case .plantingSeed:
            return "잔디를 심어보세요!"
        case .todayAfter:
            return "잔디 심기 완료!"
        case .waiting:
            return "잔디가 기다려요"
        case .groomy:
            return "2시간 지났어요!"
        case .fire:
            return "4시간 지났어요!"
        case .resting:
            return "지금은 쉬는 시간"
        default:
            return nil
        }
    }
    
    var characterImageName: String {
        switch self {
        case .empty:
            return "icon_plant"
        case .resting:
            return "icon_rest"
        case .waiting:
            return "icon_noTaking"
        case .plantingSeed:
            return "icon_takingBefore"
        case .success:
            return "icon_good"
        case .groomy:
            return "icon_2hour"
        case .fire:
            return "icon_4hour"
        case .pilledTwo:
            return "icon_takingBeforeTwo"
        case .todayAfter:
            return "icon_takingAfter"
        case .takingBeforeTwo:
            return "icon_takingBeforeTwo"
        case .takingBefore:
            return "icon_takingBefore"
        case .warning:
            return "icon_takingBeforeTwo"
        case .takenDelayedOk:
            return "icon_takingAfter"
        case .takenTooEarly:
            return "icon_takingAfter"
        case .takenDoubleComplete:
            return "icon_takingAfter"
        case .beforeStart:
            return "icon_plant"
        }
    }
    
    var iconImageName: String {
        switch self {
        case .empty, .resting:
            return "rest"
        case .waiting:
            return "missed"
        case .plantingSeed, .pilledTwo, .fire, .takingBeforeTwo, .warning:
            return "notTaken"
        case .success, .todayAfter, .takingBefore, .takenDelayedOk, .takenTooEarly, .takenDoubleComplete:
            return "taken"
        case .groomy:
            return "missed"
        case .beforeStart:
            return "rest"
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
    
    func toResult() -> MessageResult {
        return MessageResult(
            text: text,
            widgetText: widgetText,
            characterImageName: characterImageName,
            iconImageName: iconImageName,
            backgroundImageName: backgroundImageName
        )
    }
}
