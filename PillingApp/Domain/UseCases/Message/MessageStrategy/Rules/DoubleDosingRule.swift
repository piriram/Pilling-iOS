import Foundation

final class DoubleDosingRule: MessageRule {
    let priority = 200

    func shouldEvaluate(context: MessageContext) -> Bool {
        guard let yesterday = context.yesterdayStatus else { return false }

        let timeSinceMissed = context.currentDate.timeIntervalSince(yesterday.scheduledDate)
        return !yesterday.isTaken &&
               timeSinceMissed < TimeThreshold.critical + TimeThreshold.fullyMissed
    }

    func evaluate(context: MessageContext) -> MessageType? {
        guard let todayStatus = context.todayStatus,
              let yesterdayStatus = context.yesterdayStatus else { return nil }

        let timeSinceYesterday = context.currentDate.timeIntervalSince(yesterdayStatus.scheduledDate)

        if timeSinceYesterday < TimeThreshold.critical + TimeThreshold.fullyMissed {
            if todayStatus.baseStatus == .takenDouble {
                return .takenDoubleComplete
            }

            if !todayStatus.isTaken &&
               todayStatus.medicalTiming == .onTime {
                return .pilledTwo
            }
        }

        return nil
    }
}
