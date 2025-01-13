import Foundation

// MARK: - PillCycleError

enum CycleError: Error {
    case deallocated
    case invalidTimeFormat
    case invalidDateRange
    
    var localizedDescription: String {
        switch self {
        case .deallocated:
            return "UseCase가 해제되었습니다"
        case .invalidTimeFormat:
            return "시간 형식이 올바르지 않습니다"
        case .invalidDateRange:
            return "날짜 범위가 유효하지 않습니다"
        }
    }
}
