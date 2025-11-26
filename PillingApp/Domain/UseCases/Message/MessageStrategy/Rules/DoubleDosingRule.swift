import Foundation

final class DoubleDosingRule: MessageRule {
    let priority = 200
    
    func shouldEvaluate(context: MessageContext) -> Bool {
        guard let yesterday = context.yesterdayStatus else {
            print("      [DoubleDosingRule] 어제 상태 없음")
            return false
        }
        
        let timeSinceMissed = context.currentDate.timeIntervalSince(yesterday.scheduledDate)
        let isNotTaken = !yesterday.isTaken
        let isWithinWindow = timeSinceMissed < TimeThreshold.critical + TimeThreshold.fullyMissed
        
        print("      [DoubleDosingRule] 어제복용=\(!isNotTaken), 시간차=\(timeSinceMissed/3600)h, 윈도우내=\(isWithinWindow)")
        
        return isNotTaken && isWithinWindow
    }
    
    func evaluate(context: MessageContext) -> MessageType? {
        guard let todayStatus = context.todayStatus,
              let yesterdayStatus = context.yesterdayStatus else { return nil }
        
        let timeSinceYesterday = context.currentDate.timeIntervalSince(yesterdayStatus.scheduledDate)
        
        print("      [DoubleDosingRule] 오늘상태=\(todayStatus.baseStatus.rawValue), medicalTiming=\(todayStatus.medicalTiming.rawValue)")
        print("      [DoubleDosingRule] 오늘복용=\(todayStatus.isTaken ? "함" : "안함")")
        
        if timeSinceYesterday < TimeThreshold.critical + TimeThreshold.fullyMissed {
            if todayStatus.baseStatus == .takenDouble {
                print("      [DoubleDosingRule] → .takenDoubleComplete")
                return .takenDoubleComplete
            }
            
            if !todayStatus.isTaken &&
                (todayStatus.medicalTiming == .onTime ||
                 todayStatus.medicalTiming == .upcoming ||
                 todayStatus.medicalTiming == .slightDelay) {
                print("      [DoubleDosingRule] → .pilledTwo")
                return .pilledTwo
            }
        }
        
        if todayStatus.baseStatus == .takenDouble{
            return .takenDoubleComplete
        }
        
        if todayStatus.isTaken && todayStatus.baseStatus != .takenDouble{
            return .morePill
        }
        print("      [DoubleDosingRule] → 조건 미충족")
        return nil
    }
}
