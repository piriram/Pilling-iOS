//
//  LocalNotificationManager.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/13/25.
//

import Foundation
import UserNotifications
import RxSwift

protocol NotificationManagerProtocol {
    func requestAuthorization() -> Observable<Bool>
    func scheduleDailyNotification(at time: Date, isEnabled: Bool, message: String) -> Observable<Void>
    func cancelAllNotifications()
    func checkAuthorizationStatus() -> Observable<Bool>
}

final class LocalNotificationManager: NotificationManagerProtocol {
    // MARK: - Properties
    private let notificationCenter: UNUserNotificationCenter
    private let timeProvider: TimeProvider
    private let notificationIdentifier = "dailyPillReminder"
    
    // MARK: - Initialization
    init(
        notificationCenter: UNUserNotificationCenter = .current(),
        timeProvider: TimeProvider
    ) {
        self.notificationCenter = notificationCenter
        self.timeProvider = timeProvider
    }
    
    // MARK: - NotificationManagerProtocol
    
    func requestAuthorization() -> Observable<Bool> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(NotificationError.schedulingFailed)
                return Disposables.create()
            }
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
            self.notificationCenter.requestAuthorization(options: options) { granted, error in
                if let error = error {
                    observer.onError(error)
                    return
                }
                observer.onNext(granted)
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
    
    func scheduleDailyNotification(at time: Date, isEnabled: Bool, message: String) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(NotificationError.schedulingFailed)
                return Disposables.create()
            }
            
            // 기존 알림 제거
            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: [self.notificationIdentifier])
            
            guard isEnabled else {
                observer.onNext(())
                observer.onCompleted()
                return Disposables.create()
            }
            
            // 알림 콘텐츠
            let content = UNMutableNotificationContent()
            content.title = "잔디 타임"
            content.body = message
            content.sound = .default
            content.badge = 1
            
            let cal = self.timeProvider.calendar
            var comps = cal.dateComponents([.hour, .minute], from: time)
            comps.calendar = cal
            comps.timeZone = self.timeProvider.timeZone
            
            // 매일 반복 트리거
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            
            let request = UNNotificationRequest(
                identifier: self.notificationIdentifier,
                content: content,
                trigger: trigger
            )
            
            self.notificationCenter.add(request) { error in
                if let error = error {
                    observer.onError(error)
                    return
                }
                observer.onNext(())
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
    
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }
    
    func checkAuthorizationStatus() -> Observable<Bool> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(NotificationError.schedulingFailed)
                return Disposables.create()
            }
            self.notificationCenter.getNotificationSettings { settings in
                // (선택) 임시 허용도 포함하고 싶으면 .provisional 도 true 로 처리
                let allowed: Bool
                switch settings.authorizationStatus {
                case .authorized, .provisional: allowed = true
                default: allowed = false
                }
                observer.onNext(allowed)
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
}



