//
//  UserSettings.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/12/25.
//

import UIKit
import RxSwift
// MARK: - Domain/RepositoryProtocols/UserSettingsRepositoryProtocol.swift

protocol UserSettingsRepositoryProtocol {
    func fetchSettings() -> Observable<UserSettings>
    func saveSettings(_ settings: UserSettings) -> Observable<Void>
}
// MARK: - Domain/Entities/UserSettings.swift

struct UserSettings {
    static let defaultNotificationMessage: String = "잔디를 심을 시간이에요🌱"
    
    let scheduledTime: Date
    let notificationEnabled: Bool
    let delayThresholdMinutes: Int
    let notificationMessage: String
    
    init(
        scheduledTime: Date,
        notificationEnabled: Bool,
        delayThresholdMinutes: Int,
        notificationMessage: String = UserSettings.defaultNotificationMessage
    ) {
        self.scheduledTime = scheduledTime
        self.notificationEnabled = notificationEnabled
        self.delayThresholdMinutes = delayThresholdMinutes
        self.notificationMessage = notificationMessage
    }
    
    static var `default`: UserSettings {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: now)
        let scheduledTime = calendar.date(from: components) ?? now
        
        return UserSettings(
            scheduledTime: scheduledTime,
            notificationEnabled: true,
            delayThresholdMinutes: 120,
            notificationMessage: UserSettings.defaultNotificationMessage
        )
    }
}


