import Foundation

enum DateFormatStyle {
    case timeShort             // 시스템 로케일 기반 시간 (짧은 형식)
    case timeMedium            // 시스템 로케일 기반 시간 (중간 형식)
    case time24Hour            // "09:00" (24시간)
    case time12Hour            // "9:00 AM" (12시간)
    case fullDate              // 시스템 로케일 기반 전체 날짜
    case shortDate             // 시스템 로케일 기반 짧은 날짜
    case mediumDate            // 시스템 로케일 기반 중간 날짜
    case yearMonthDay          // "2025-10-21" (ISO)
    case yearMonthDayPoint     // "2025.10.21"
    case dateTimeShort         // "MM.dd HH:mm"
    case monthDay              // 시스템 로케일 기반 월일
    case custom(String)
    
    var formatString: String? {
        switch self {
        case .time24Hour:
            return "HH:mm"
        case .time12Hour:
            return "h:mm a"
        case .yearMonthDay:
            return "yyyy-MM-dd"
        case .yearMonthDayPoint:
            return "yyyy.MM.dd"
        case .dateTimeShort:
            return "MM.dd HH:mm"
        case .custom(let format):
            return format
        default:
            return nil
        }
    }
    
    var dateStyle: DateFormatter.Style? {
        switch self {
        case .fullDate:
            return .long
        case .shortDate:
            return .short
        case .mediumDate:
            return .medium
        default:
            return nil
        }
    }
    
    var timeStyle: DateFormatter.Style? {
        switch self {
        case .timeShort:
            return .short
        case .timeMedium:
            return .medium
        default:
            return nil
        }
    }
}

extension Date {
    func formatted(
        style: DateFormatStyle,
        timeZone: TimeZone = .current
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.timeZone = timeZone
        
        if let formatString = style.formatString {
            formatter.dateFormat = formatString
        } else {
            formatter.dateStyle = style.dateStyle ?? .none
            formatter.timeStyle = style.timeStyle ?? .none
        }
        
        return formatter.string(from: self)
    }
}
