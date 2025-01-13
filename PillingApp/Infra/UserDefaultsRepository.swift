import Foundation
import RxSwift

// MARK: - Data/Repositories/UserDefaultsUserSettingsRepository.swift

final class UserDefaultsRepository: UserDefaultsProtocol {
    private let userDefaults: UserDefaults
    
    private enum Keys {
        static let scheduledTime = "scheduledTime"
        static let notificationEnabled = "notificationEnabled"
        static let delayThresholdMinutes = "delayThresholdMinutes"
        static let notificationMessage = "notificationMessage"
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
        let notificationMessage = userDefaults.string(forKey: Keys.notificationMessage)
            ?? UserSettings.default.notificationMessage
        
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
