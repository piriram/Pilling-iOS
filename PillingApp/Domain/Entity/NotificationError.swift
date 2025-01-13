import Foundation

enum NotificationError: Error {
    case permissionDenied
    case schedulingFailed
    case invalidTime
}
