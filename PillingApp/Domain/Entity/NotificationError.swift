//
//  NotificationError.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 11/6/25.
//

import Foundation

enum NotificationError: Error {
    case permissionDenied
    case schedulingFailed
    case invalidTime
}
