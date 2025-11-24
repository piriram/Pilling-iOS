import Foundation

final class RestDayRule: MessageRule {
    let priority = 75

    func shouldEvaluate(context: MessageContext) -> Bool {
        context.todayStatus?.baseStatus == .rest
    }

    func evaluate(context: MessageContext) -> MessageType? {
        return .resting
    }
}
