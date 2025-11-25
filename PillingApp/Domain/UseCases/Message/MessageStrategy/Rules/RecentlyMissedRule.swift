import Foundation

final class RecentlyMissedRule: MessageRule {
    let priority = 150

    func shouldEvaluate(context: MessageContext) -> Bool {
        let isRecentlyMissed = context.yesterdayStatus?.baseStatus == .recentlyMissed
        print("      [RecentlyMissedRule] 어제=\(context.yesterdayStatus?.baseStatus.rawValue ?? "nil"), recentlyMissed=\(isRecentlyMissed)")
        return isRecentlyMissed
    }

    func evaluate(context: MessageContext) -> MessageType? {
        if !context.todayIsTaken {
            print("      [RecentlyMissedRule] 어제 최근미복용 + 오늘 미복용 → .pilledTwo")
            return .pilledTwo
        }

        print("      [RecentlyMissedRule] 오늘 이미 복용 → nil")
        return nil
    }
}
