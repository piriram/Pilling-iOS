import Foundation

enum AnalyticsEvent {
    // 약 복용 관련
    case pillTaken(date: Date, status: PillStatus)
    case pillStatusChanged(from: PillStatus, to: PillStatus)

    // 사이클 관련
    case cycleCreated(duration: Int, startDate: Date)
    case cycleCompleted(totalDays: Int)

    // 부작용 관련
    case sideEffectAdded(tag: String, date: Date)
    case sideEffectRemoved(tag: String)

    // 화면 진입
    case screenViewed(screenName: String)

    // 설정 변경
    case settingsChanged(type: String, value: String)

    // MARK: - 이벤트명 (Firebase 전송용)
    var name: String {
        switch self {
        case .pillTaken:
            return "pill_taken"
        case .pillStatusChanged:
            return "pill_status_changed"
        case .cycleCreated:
            return "cycle_created"
        case .cycleCompleted:
            return "cycle_completed"
        case .sideEffectAdded:
            return "side_effect_added"
        case .sideEffectRemoved:
            return "side_effect_removed"
        case .screenViewed:
            return "screen_viewed"
        case .settingsChanged:
            return "settings_changed"
        }
    }

    // MARK: - 파라미터 (Firebase 전송용)
    var parameters: [String: Any] {
        switch self {
        case .pillTaken(let date, let status):
            return [
                "date": ISO8601DateFormatter().string(from: date),
                "status": status.rawValue
            ]

        case .pillStatusChanged(let from, let to):
            return [
                "from_status": from.rawValue,
                "to_status": to.rawValue,
                "timestamp": Date().timeIntervalSince1970
            ]

        case .cycleCreated(let duration, let startDate):
            return [
                "duration_days": duration,
                "start_date": ISO8601DateFormatter().string(from: startDate)
            ]

        case .cycleCompleted(let totalDays):
            return [
                "total_days": totalDays,
                "completion_date": ISO8601DateFormatter().string(from: Date())
            ]

        case .sideEffectAdded(let tag, let date):
            return [
                "tag": tag,
                "date": ISO8601DateFormatter().string(from: date)
            ]

        case .sideEffectRemoved(let tag):
            return [
                "tag": tag
            ]

        case .screenViewed(let screenName):
            return [
                "screen_name": screenName
            ]

        case .settingsChanged(let type, let value):
            return [
                "setting_type": type,
                "setting_value": value
            ]
        }
    }
}
