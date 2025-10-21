//
//  UserSettings.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/12/25.
//

import Foundation
import RxSwift

protocol UserSettingsRepositoryProtocol {
    func fetchSettings() -> Observable<UserSettings>
    func saveSettings(_ settings: UserSettings) -> Observable<Void>
}

struct UserSettings: Equatable {
    static let defaultNotificationMessage = "잔디를 심을 시간이에요🌱"
    
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
}

extension UserSettings {
    /// 앱 전역 타임존/캘린더와 일치하는 기본 설정을 생성
    static func makeDefault(using timeProvider: TimeProvider) -> UserSettings {
        let now = timeProvider.now
        let cal = timeProvider.calendar
        // 시/분만 유지해 같은 ‘오늘 시간’으로 고정
        let comps = cal.dateComponents([.hour, .minute], from: now)
        let scheduled = cal.date(from: comps) ?? now
        
        return UserSettings(
            scheduledTime: scheduled,
            notificationEnabled: true,
            delayThresholdMinutes: 120,
            notificationMessage: UserSettings.defaultNotificationMessage
        )
    }
    
    /// (선택) 하위호환용: 내부적으로 SystemTimeProvider로 위임
    @available(*, deprecated, message: "Use makeDefault(using:) with a TimeProvider")
    static var `default`: UserSettings {
        return makeDefault(using: SystemTimeProvider())
    }
}
