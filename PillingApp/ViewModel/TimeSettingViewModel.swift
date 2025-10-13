//
//  TimeSettingViewModel.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/13/25.
//

import Foundation
import RxSwift
import RxCocoa

final class TimeSettingViewModel {
    
    // MARK: - Input/Output
    
    struct Input {
        let backButtonTapped: Observable<Void>
        let timeSettingButtonTapped: Observable<Void>
        let alarmToggleChanged: Observable<Bool>
        let healthToggleChanged: Observable<Bool>
        let completeButtonTapped: Observable<Void>
    }
    
    struct Output {
        let showTimePicker: Driver<Void>
        let showSettingComplete: Driver<Void>
        let dismissView: Driver<Void>
        let showError: Driver<String>
    }
    
    // MARK: - Properties
    
    private let settingsRepository: UserSettingsRepositoryProtocol
    private let notificationManager: NotificationManagerProtocol
    private let disposeBag = DisposeBag()
    
    private let selectedTime = BehaviorRelay<Date>(value: Date())
    private let isAlarmEnabled = BehaviorRelay<Bool>(value: true)
    private let isHealthEnabled = BehaviorRelay<Bool>(value: true)
    
    // MARK: - Initialization
    
    init(
        settingsRepository: UserSettingsRepositoryProtocol,
        notificationManager: NotificationManagerProtocol
    ) {
        self.settingsRepository = settingsRepository
        self.notificationManager = notificationManager
    }
    
    // MARK: - Transform
    
    func transform(input: Input) -> Output {
        let showTimePicker = input.timeSettingButtonTapped
            .asDriver(onErrorJustReturn: ())
        
        input.alarmToggleChanged
            .bind(to: isAlarmEnabled)
            .disposed(by: disposeBag)
        
        input.healthToggleChanged
            .bind(to: isHealthEnabled)
            .disposed(by: disposeBag)
        
        let errorTracker = PublishSubject<String>()
        
        let showSettingComplete = input.completeButtonTapped
            .flatMapLatest { [weak self] _ -> Observable<Void> in
                guard let self = self else { return .empty() }
                return self.setupNotificationAndSaveSettings()
                    .catch { error in
                        let errorMessage = self.handleError(error)
                        errorTracker.onNext(errorMessage)
                        return .empty()
                    }
            }
            .asDriver(onErrorJustReturn: ())
        
        let dismissView = input.backButtonTapped
            .asDriver(onErrorJustReturn: ())
        
        let showError = errorTracker
            .asDriver(onErrorJustReturn: "알 수 없는 오류가 발생했습니다.")
        
        return Output(
            showTimePicker: showTimePicker,
            showSettingComplete: showSettingComplete,
            dismissView: dismissView,
            showError: showError
        )
    }
    
    // MARK: - Public Methods
    
    func updateTime(_ date: Date) {
        selectedTime.accept(date)
    }
    
    // MARK: - Private Methods
    
    private func setupNotificationAndSaveSettings() -> Observable<Void> {
        // 1. 알림 권한 요청
        return notificationManager.requestAuthorization()
            .flatMap { [weak self] granted -> Observable<Void> in
                guard let self = self else { return .empty() }
                
                // 권한이 거부되면 에러 발생
                guard granted else {
                    return .error(NotificationError.permissionDenied)
                }
                
                // 2. 알림 스케줄링
                return self.notificationManager.scheduleDailyNotification(
                    at: self.selectedTime.value,
                    isEnabled: self.isAlarmEnabled.value
                )
            }
            .flatMap { [weak self] _ -> Observable<Void> in
                guard let self = self else { return .empty() }
                
                // 3. 설정 저장
                return self.saveSettings()
            }
    }
    
    private func saveSettings() -> Observable<Void> {
        return settingsRepository.fetchSettings()
            .flatMap { [weak self] currentSettings -> Observable<Void> in
                guard let self = self else { return .empty() }
                
                let updatedSettings = UserSettings(
                    scheduledTime: self.selectedTime.value,
                    notificationEnabled: self.isAlarmEnabled.value,
                    delayThresholdMinutes: currentSettings.delayThresholdMinutes
                )
                
                return self.settingsRepository.saveSettings(updatedSettings)
            }
    }
    
    private func handleError(_ error: Error) -> String {
        if let notificationError = error as? NotificationError {
            switch notificationError {
            case .permissionDenied:
                return "알림 권한이 필요합니다.\n설정에서 알림을 허용해주세요."
            case .schedulingFailed:
                return "알림 설정에 실패했습니다.\n다시 시도해주세요."
            case .invalidTime:
                return "유효하지 않은 시간입니다."
            }
        }
        return "오류가 발생했습니다.\n다시 시도해주세요."
    }
}
