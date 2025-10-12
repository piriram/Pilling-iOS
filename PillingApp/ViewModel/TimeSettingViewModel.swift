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
        let navigateToDashboard: Driver<Void>
        let dismissView: Driver<Void>
    }
    
    // MARK: - Properties
    
    private let settingsRepository: UserSettingsRepositoryProtocol
    private let disposeBag = DisposeBag()
    
    private let selectedTime = BehaviorRelay<Date>(value: Date())
    private let isAlarmEnabled = BehaviorRelay<Bool>(value: true)
    private let isHealthEnabled = BehaviorRelay<Bool>(value: true)
    
    // MARK: - Initialization
    
    init(settingsRepository: UserSettingsRepositoryProtocol) {
        self.settingsRepository = settingsRepository
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
        
        let navigateToDashboard = input.completeButtonTapped
            .flatMapLatest { [weak self] _ -> Observable<Void> in
                guard let self = self else { return .empty() }
                return self.saveSettings()
            }
            .asDriver(onErrorJustReturn: ())
        
        let dismissView = input.backButtonTapped
            .asDriver(onErrorJustReturn: ())
        
        return Output(
            showTimePicker: showTimePicker,
            navigateToDashboard: navigateToDashboard,
            dismissView: dismissView
        )
    }
    
    // MARK: - Public Methods
    
    func updateTime(_ date: Date) {
        selectedTime.accept(date)
    }
    
    // MARK: - Private Methods
    
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
}
