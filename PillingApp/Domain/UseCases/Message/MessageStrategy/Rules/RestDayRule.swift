import Foundation

final class RestDayRule: MessageRule {
    let priority = 75

    func shouldEvaluate(context: MessageContext) -> Bool {
        let isRest = context.todayStatus?.baseStatus == .rest
        print("      [RestDayRule] 오늘=\(context.todayStatus?.baseStatus.rawValue ?? "nil"), 휴약일=\(isRest)")
        return isRest
    }

    func evaluate(context: MessageContext) -> MessageType? {
        print("      [RestDayRule] → .resting")
        return .resting
    }
}
