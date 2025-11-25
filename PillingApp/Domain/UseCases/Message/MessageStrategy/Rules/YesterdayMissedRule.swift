import Foundation

final class YesterdayMissedRule: MessageRule {
    let priority = 300

    func shouldEvaluate(context: MessageContext) -> Bool {
        guard let yesterday = context.yesterdayStatus else {
            print("      [YesterdayMissedRule] 어제 상태 없음")
            return false
        }
        let isMissed = yesterday.baseStatus == .missed
        let isOnlyOneDay = context.consecutiveMissedDays == 1
        print("      [YesterdayMissedRule] 어제=\(yesterday.baseStatus.rawValue), missed=\(isMissed), 연속=\(context.consecutiveMissedDays)일")
        return isMissed && isOnlyOneDay
    }

    func evaluate(context: MessageContext) -> MessageType? {
        guard let todayStatus = context.todayStatus else { return nil }

        if todayStatus.baseStatus == .takenDouble {
            print("      [YesterdayMissedRule] 오늘 2알 복용 → .takingBefore")
            return .takingBefore
        }

        if todayStatus.isTaken && todayStatus.baseStatus != .takenDouble {
            print("      [YesterdayMissedRule] 어제 놓치고 오늘 1알만 복용 → .warning")
            return .warning
        }

        if !todayStatus.isTaken {
            print("      [YesterdayMissedRule] 어제 놓침 + 오늘 미복용 → .pilledTwo")
            return .pilledTwo
        }

        print("      [YesterdayMissedRule] → nil")
        return nil
    }
}
