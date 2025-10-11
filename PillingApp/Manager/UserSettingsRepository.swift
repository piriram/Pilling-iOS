//
//  UserSettingsRepository.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/12/25.
//

import Foundation
import RxSwift
// MARK: - Data/Repositories/UserDefaultsUserSettingsRepository.swift

final class UserDefaultsUserSettingsRepository: UserSettingsRepositoryProtocol {
    private let userDefaults: UserDefaults
    
    private enum Keys {
        static let scheduledTime = "scheduledTime"
        static let notificationEnabled = "notificationEnabled"
        static let delayThresholdMinutes = "delayThresholdMinutes"
    }
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func fetchSettings() -> Observable<UserSettings> {
        let scheduledTime: Date
        if let timeInterval = userDefaults.object(forKey: Keys.scheduledTime) as? TimeInterval {
            scheduledTime = Date(timeIntervalSince1970: timeInterval)
        } else {
            scheduledTime = UserSettings.default.scheduledTime
        }
        
        let notificationEnabled = userDefaults.object(forKey: Keys.notificationEnabled) as? Bool
            ?? UserSettings.default.notificationEnabled
        let delayThresholdMinutes = userDefaults.object(forKey: Keys.delayThresholdMinutes) as? Int
            ?? UserSettings.default.delayThresholdMinutes
        
        let settings = UserSettings(
            scheduledTime: scheduledTime,
            notificationEnabled: notificationEnabled,
            delayThresholdMinutes: delayThresholdMinutes
        )
        
        return .just(settings)
    }
    
    func saveSettings(_ settings: UserSettings) -> Observable<Void> {
        userDefaults.set(settings.scheduledTime.timeIntervalSince1970, forKey: Keys.scheduledTime)
        userDefaults.set(settings.notificationEnabled, forKey: Keys.notificationEnabled)
        userDefaults.set(settings.delayThresholdMinutes, forKey: Keys.delayThresholdMinutes)
        return .just(())
    }
}
