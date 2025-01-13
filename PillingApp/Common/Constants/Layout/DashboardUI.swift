import Foundation

// MARK: - DashboardUI

enum DashboardUI {
    
    enum CharacterImage: String {
        case todayAfter = "icon_takingAfter"
        case takingBeforeTwo = "icon_takingBeforeTwo"
        case takingBefore = "icon_takingBefore"
        case warning = "icon_noTaking"
        case rest = "icon_rest"
        case groomy = "icon_2hour"
        case fire = "icon_4hour"
        case success = "icon_good"
    }
    
    enum MessageIconImage: String {
        case notTaken = "notTaken"
        case taken = "taken"
        case missed = "missed"
        case rest = "rest"
    }
}
