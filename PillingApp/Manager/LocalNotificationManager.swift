//
//  LocalNotificationManager.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/13/25.
//

import Foundation
import UserNotifications
import RxSwift

final class LocalNotificationManager: NotificationManagerProtocol {
    
    // MARK: - Properties
    
    private let notificationCenter: UNUserNotificationCenter
    private let notificationIdentifier = "dailyPillReminder"
    
    // MARK: - Initialization
    
    init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
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
    
    func scheduleDailyNotification(at time: Date, isEnabled: Bool) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(NotificationError.schedulingFailed)
                return Disposables.create()
            }
            
            // 기존 알림 삭제
            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: [self.notificationIdentifier])
            
            // 알림이 비활성화된 경우 바로 완료
            guard isEnabled else {
                observer.onNext(())
                observer.onCompleted()
                return Disposables.create()
            }
            
            // 알림 콘텐츠 설정
            let content = UNMutableNotificationContent()
            content.title = "💊 복용 시간이에요!"
            content.body = "건강한 하루를 위해 약을 복용해주세요."
            content.sound = .default
            content.badge = 1
            
            // 시간 컴포넌트 추출
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: time)
            
            // 매일 반복되는 트리거 생성
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
            // 알림 요청 생성
            let request = UNNotificationRequest(
                identifier: self.notificationIdentifier,
                content: content,
                trigger: trigger
            )
            
            // 알림 등록
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
                let isAuthorized = settings.authorizationStatus == .authorized
                observer.onNext(isAuthorized)
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
}
enum NotificationError: Error {
    case permissionDenied
    case schedulingFailed
    case invalidTime
}

protocol NotificationManagerProtocol {
    func requestAuthorization() -> Observable<Bool>
    func scheduleDailyNotification(at time: Date, isEnabled: Bool) -> Observable<Void>
    func cancelAllNotifications()
    func checkAuthorizationStatus() -> Observable<Bool>
}
