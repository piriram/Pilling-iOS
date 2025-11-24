import Foundation

final class RecentlyMissedRule: MessageRule {
    let priority = 150

    func shouldEvaluate(context: MessageContext) -> Bool {
        context.yesterdayStatus?.baseStatus == .recentlyMissed
    }

    func evaluate(context: MessageContext) -> MessageType? {
        if !context.todayIsTaken {
            return .pilledTwo
        }

        return nil
    }
}
