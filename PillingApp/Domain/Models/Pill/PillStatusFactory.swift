import Foundation

final class PillStatusFactory {
    private let timeProvider: TimeProvider

    init(timeProvider: TimeProvider) {
        self.timeProvider = timeProvider
    }

    func createStatus(
        scheduledDate: Date,
        actionDate: Date? = nil,
        evaluationDate: Date = Date(),
        isRestDay: Bool = false
    ) -> PillStatusModel {

        let timeContext = determineTimeContext(
            scheduledDate: scheduledDate,
            evaluationDate: evaluationDate
        )

        if isRestDay {
            return PillStatusModel(
                baseStatus: .rest,
                timeContext: timeContext,
                medicalTiming: .onTime,
                scheduledDate: scheduledDate,
                actionDate: actionDate
            )
        }

        let timeElapsed = evaluationDate.timeIntervalSince(scheduledDate)
        let medicalTiming = determineMedicalTiming(timeElapsed: timeElapsed)

        let baseStatus = determineBaseStatus(
            medicalTiming: medicalTiming,
            actionDate: actionDate,
            scheduledDate: scheduledDate
        )

        return PillStatusModel(
            baseStatus: baseStatus,
            timeContext: timeContext,
            medicalTiming: medicalTiming,
            scheduledDate: scheduledDate,
            actionDate: actionDate
        )
    }

    private func determineTimeContext(scheduledDate: Date, evaluationDate: Date) -> TimeContext {
        let scheduledDay = timeProvider.startOfDay(for: scheduledDate)
        let today = timeProvider.startOfDay(for: evaluationDate)

        if scheduledDay < today { return .past }
        if scheduledDay > today { return .future }
        return .present
    }

    private func determineMedicalTiming(timeElapsed: TimeInterval) -> MedicalTiming {
        switch timeElapsed {
        case ..<TimeThreshold.tooEarly:
            return .tooEarly
        case TimeThreshold.tooEarly..<0:
            return .upcoming
        case 0..<TimeThreshold.normal:
            return .onTime
        case TimeThreshold.normal..<TimeThreshold.delayed:
            return .slightDelay
        case TimeThreshold.delayed..<TimeThreshold.critical:
            return .moderate
        case TimeThreshold.critical..<TimeThreshold.fullyMissed:
            return .recent
        default:
            return .missed
        }
    }

    private func determineBaseStatus(
        medicalTiming: MedicalTiming,
        actionDate: Date?,
        scheduledDate: Date
    ) -> PillStatus {

        if let actionDate = actionDate {
            let actionTimeDiff = actionDate.timeIntervalSince(scheduledDate)

            if actionTimeDiff < TimeThreshold.tooEarly {
                return .takenTooEarly
            } else if abs(actionTimeDiff) <= TimeThreshold.normal {
                return .taken
            } else {
                return .takenDelayed
            }
        }

        switch medicalTiming {
        case .tooEarly, .upcoming:
            return .scheduled
        case .onTime, .slightDelay, .moderate:
            return .notTaken
        case .recent:
            return .recentlyMissed
        case .missed:
            return .missed
        }
    }
}
