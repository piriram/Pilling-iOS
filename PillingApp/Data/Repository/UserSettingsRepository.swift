//
//  UserSettingsRepository.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/12/25.
//

import Foundation
import RxSwift

final class UserDefaultsUserSettingsRepository: UserSettingsRepositoryProtocol {
    private let userDefaults: UserDefaults
    
    private enum Keys {
        static let scheduledTime = "scheduledTime"
        static let notificationEnabled = "notificationEnabled"
        static let delayThresholdMinutes = "delayThresholdMinutes"
        static let notificationMessage = "notificationMessage"
    }
    
    // 기본값을 Repository에서 직접 정의
    private enum DefaultValues {
        static let scheduledTime: Date = {
            var components = DateComponents()
            components.hour = 9
            components.minute = 0
            return Calendar.current.date(from: components) ?? Date()
        }()
        static let notificationEnabled = true
        static let delayThresholdMinutes = 30
        static let notificationMessage = "알약 복용 시간입니다"
    }
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func fetchSettings() -> Observable<UserSettings> {
        let scheduledTime: Date
        if let timeInterval = userDefaults.object(forKey: Keys.scheduledTime) as? TimeInterval {
            scheduledTime = Date(timeIntervalSince1970: timeInterval)
        } else {
            scheduledTime = DefaultValues.scheduledTime
        }
        
        let notificationEnabled = userDefaults.object(forKey: Keys.notificationEnabled) as? Bool
            ?? DefaultValues.notificationEnabled
        let delayThresholdMinutes = userDefaults.object(forKey: Keys.delayThresholdMinutes) as? Int
            ?? DefaultValues.delayThresholdMinutes
        let notificationMessage = userDefaults.string(forKey: Keys.notificationMessage)
            ?? DefaultValues.notificationMessage
        
        let settings = UserSettings(
            scheduledTime: scheduledTime,
            notificationEnabled: notificationEnabled,
            delayThresholdMinutes: delayThresholdMinutes,
            notificationMessage: notificationMessage
        )
        
        return .just(settings)
    }
    
    func saveSettings(_ settings: UserSettings) -> Observable<Void> {
        userDefaults.set(settings.scheduledTime.timeIntervalSince1970, forKey: Keys.scheduledTime)
        userDefaults.set(settings.notificationEnabled, forKey: Keys.notificationEnabled)
        userDefaults.set(settings.delayThresholdMinutes, forKey: Keys.delayThresholdMinutes)
        userDefaults.set(settings.notificationMessage, forKey: Keys.notificationMessage)
        return .just(())
    }
}
