import Foundation
import RxSwift
import RxCocoa

// MARK: - DashboardViewModel

final class DashboardViewModel {

    private let fetchDashboardDataUseCase: FetchDashboardDataUseCaseProtocol
    private let takePillUseCase: TakePillUseCaseProtocol
    private let updatePillStatusUseCase: UpdatePillStatusUseCaseProtocol
    private let calculateDashboardMessageUseCase: CalculateDashboardMessageUseCaseProtocol
    private let userDefaultsManager: UserDefaultsManagerProtocol
    private let settingsRepository: UserDefaultsProtocol
    private let notificationManager: NotificationManagerProtocol

    private let disposeBag = DisposeBag()
    private let calendar = Calendar.current

    // MARK: - Outputs

    let settings = BehaviorRelay<UserSettings>(value: .default)
    let currentCycle = BehaviorRelay<Cycle?>(value: nil)
    let items = BehaviorRelay<[DayItem]>(value: [])
    let dashboardMessage = BehaviorRelay<DashboardMessage?>(value: nil)
    let canTakePill = BehaviorRelay<Bool>(value: false)
    let pillInfo = BehaviorRelay<PillInfo?>(value: nil)
    let showRetryAlert = PublishRelay<Void>()
    let showNewCycleAlert = PublishRelay<Void>()
    
    // MARK: - Initialization
    
    init(
        fetchDashboardDataUseCase: FetchDashboardDataUseCaseProtocol,
        takePillUseCase: TakePillUseCaseProtocol,
        updatePillStatusUseCase: UpdatePillStatusUseCaseProtocol,
        calculateDashboardMessageUseCase: CalculateDashboardMessageUseCaseProtocol,
        userDefaultsManager: UserDefaultsManagerProtocol,
        settingsRepository: UserDefaultsProtocol,
        notificationManager: NotificationManagerProtocol
    ) {
        self.fetchDashboardDataUseCase = fetchDashboardDataUseCase
        self.takePillUseCase = takePillUseCase
        self.updatePillStatusUseCase = updatePillStatusUseCase
        self.calculateDashboardMessageUseCase = calculateDashboardMessageUseCase
        self.userDefaultsManager = userDefaultsManager
        self.settingsRepository = settingsRepository
        self.notificationManager = notificationManager


        loadDashboardData()
        loadPillInfo()
    }
    
    // MARK: - Private Methods
    
    private func autoMarkPastScheduledAsMissed() {
        guard let cycle = currentCycle.value else { return }
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        
        for (index, record) in cycle.records.enumerated() {
            if record.scheduledDateTime < startOfToday {
                if case .scheduled = record.status {
                    updatePillStatusUseCase
                        .execute(
                            cycle: cycle,
                            recordIndex: index,
                            newStatus: .missed,
                            memo: nil,
                            takenAt: nil
                        )
                        .subscribe(onNext: { [weak self] updatedCycle in
                            self?.currentCycle.accept(updatedCycle)
                            self?.updateItems()
                            self?.updateDashboardMessage()
                            self?.updateCanTakePill()
                        })
                        .disposed(by: disposeBag)
                }
            }
        }
    }
    
    private func loadPillInfo() {
        if let info = userDefaultsManager.loadPillInfo() {
            pillInfo.accept(info)
        } else{
            print("pillInfo 불로오기 실패")
        }
    }
    
    private func loadDashboardData() {
        fetchDashboardDataUseCase.execute()
            .subscribe(
                onNext: { [weak self] data in
                    self?.handleSuccess(data)
                },
                onError: { [weak self] error in
                    self?.handleError(error)
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func handleSuccess(_ data: (cycle: Cycle?, settings: UserSettings)) {
        self.settings.accept(data.settings)
        self.currentCycle.accept(data.cycle)
        self.updateItems()
        self.updateDashboardMessage()
        self.updateCanTakePill()
        self.autoMarkPastScheduledAsMissed()
    }
    
    private func handleError(_ error: Error) {
        print("❌ 데이터 로드 실패: \(error)")
        self.showRetryAlert.accept(())
    }
    
    private func reloadSettings() {
        settingsRepository.fetchSettings()
            .subscribe(onNext: { [weak self] settings in
                guard let self = self else { return }
                self.settings.accept(settings)
                
                if var cycle = self.currentCycle.value {
                    cycle.scheduledTime = settings.scheduledTime.formatted(style: .time24Hour)
                    self.currentCycle.accept(cycle)
                    self.updateItems()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func updateItems() {
        guard let cycle = currentCycle.value else {
            return
        }

        let maxItems = 28
        let visibleRecords = Array(cycle.records.prefix(maxItems))
        let now = Date()
        let currentScheduledTime = settings.value.scheduledTime

        let dayItems = visibleRecords.map { record in
            var adjustedStatus = record.status.adjustedForDate(record.scheduledDateTime, calendar: calendar)
            
            if calendar.isDateInToday(record.scheduledDateTime) {
                let todayScheduledDateTime = calculateTodayScheduledTime(
                    from: currentScheduledTime,
                    calendar: calendar
                )
                
                if adjustedStatus != .rest {
                    if record.status == .takenDouble {
                        adjustedStatus = .takenDouble
                    }
                    else if !adjustedStatus.isTaken {
                        let timeInterval = now.timeIntervalSince(todayScheduledDateTime)
                        let twoHours: TimeInterval = 2 * 60 * 60
                        let fourHours: TimeInterval = 4 * 60 * 60
                        
                        if timeInterval >= fourHours {
                            adjustedStatus = .todayDelayedCritical
                        } else if timeInterval >= twoHours {
                            adjustedStatus = .todayDelayed
                        } else {
                            adjustedStatus = .todayNotTaken
                        }
                    }
                    else if let takenAt = record.takenAt {
                        adjustedStatus = calculateTakenStatus(
                            takenAt: takenAt,
                            scheduledDateTime: todayScheduledDateTime
                        )
                    }
                }
            }
            
            return DayItem(
                cycleDay: record.cycleDay,
                date: record.scheduledDateTime,
                status: adjustedStatus,
                scheduledDateTime: record.scheduledDateTime
            )
        }

        items.accept(dayItems)
    }
    
    private func calculateTodayScheduledTime(
        from scheduledTime: Date,
        calendar: Calendar
    ) -> Date {
        let now = Date()
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: scheduledTime)
        
        var combined = DateComponents()
        combined.year = todayComponents.year
        combined.month = todayComponents.month
        combined.day = todayComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        
        return calendar.date(from: combined) ?? now
    }
    
    private func calculateTakenStatus(
        takenAt: Date,
        scheduledDateTime: Date
    ) -> PillStatus {
        let timeInterval = takenAt.timeIntervalSince(scheduledDateTime)
        let twoHours: TimeInterval = 2 * 60 * 60
        
        if timeInterval < -twoHours {
            return .todayTakenTooEarly
        }
        else if timeInterval > twoHours {
            return .todayTakenDelayed
        }
        else {
            return .todayTaken
        }
    }
    
    private func updateDashboardMessage() {
        let message = calculateDashboardMessageUseCase.execute(cycle: currentCycle.value)
        dashboardMessage.accept(message)
    }
    
    private func updateCanTakePill() {
        guard let cycle = currentCycle.value else {
            canTakePill.accept(false)
            return
        }
        
        let now = Date()
        
        guard let todayRecord = cycle.records.first(where: {
            calendar.isDate($0.scheduledDateTime, inSameDayAs: now)
        }) else {
            canTakePill.accept(false)
            return
        }
        
        if case .rest = todayRecord.status {
            canTakePill.accept(false)
            return
        }
        
        let adjustedStatus = todayRecord.status.adjustedForDate(todayRecord.scheduledDateTime, calendar: calendar)
        if adjustedStatus.isTaken {
            canTakePill.accept(false)
            return
        }
        
        canTakePill.accept(true)
    }
    
    // MARK: - Public Methods (Inputs)
    
    func refreshForCurrentDate() {
        guard let cycle = currentCycle.value else {
            updateItems()
            updateDashboardMessage()
            updateCanTakePill()
            return
        }
        
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        
        let hasPastScheduled = cycle.records.contains { record in
            record.scheduledDateTime < startOfToday && record.status == .scheduled
        }
        
        if hasPastScheduled {
            autoMarkPastScheduledAsMissed()
        } else {
            updateItems()
            updateDashboardMessage()
            updateCanTakePill()
        }
    }
    
    func reloadData() {
        loadDashboardData()
    }
    
    func refreshSettings() {
        reloadSettings()
    }
    
    func takePill() {
        guard let cycle = currentCycle.value else { return }
        let takenAt = Date()

        takePillUseCase.execute(cycle: cycle, settings: settings.value, takenAt: takenAt)
            .subscribe(onNext: { [weak self] updatedCycle in
                guard let self = self else { return }
                self.currentCycle.accept(updatedCycle)
                self.updateItems()
                self.updateDashboardMessage()
                self.updateCanTakePill()

                // 알림 업데이트 (위약 기간 반영)
                self.updateNotificationMessage(with: updatedCycle)

                // 사이클 완료 확인
                self.checkCycleCompletion(updatedCycle)
            })
            .disposed(by: disposeBag)
    }
    
    func updateState(at index: Int, to newStatus: PillStatus) {
        guard let cycle = currentCycle.value else { return }
        
        updatePillStatusUseCase.execute(
            cycle: cycle,
            recordIndex: index,
            newStatus: newStatus,
            memo: nil,
            takenAt: nil
        )
        .subscribe(onNext: { [weak self] updatedCycle in
            self?.currentCycle.accept(updatedCycle)
            self?.updateItems()
            self?.updateDashboardMessage()
            self?.updateCanTakePill()
        })
        .disposed(by: disposeBag)
    }
    
    func updateState(at index: Int, to newStatus: PillStatus, memo: String?, takenAt: Date? = nil) {
        guard let cycle = currentCycle.value else {
            print("❌ updateState: cycle이 nil입니다")
            return
        }

        updatePillStatusUseCase.execute(
            cycle: cycle,
            recordIndex: index,
            newStatus: newStatus,
            memo: memo,
            takenAt: takenAt
        )
        .subscribe(
            onNext: { [weak self] updatedCycle in
                guard let self = self else { return }

                if index < updatedCycle.records.count {
                }

                self.currentCycle.accept(updatedCycle)

                self.updateItems()

                self.updateDashboardMessage()

                self.updateCanTakePill()

                // 알림 업데이트 (위약 기간 반영)
                self.updateNotificationMessage(with: updatedCycle)

                // 사이클 완료 확인
                self.checkCycleCompletion(updatedCycle)
            },
            onError: { error in
                print("❌ UseCase 에러: \(error)")
            }
        )
        .disposed(by: disposeBag)
    }

    // MARK: - Notification & Cycle Completion

    private func updateNotificationMessage(with cycle: Cycle) {
        let currentSettings = settings.value
        notificationManager.scheduleDailyNotification(
            at: currentSettings.scheduledTime,
            isEnabled: currentSettings.notificationEnabled,
            message: currentSettings.notificationMessage,
            cycle: cycle
        )
        .subscribe()
        .disposed(by: disposeBag)
    }

    private func checkCycleCompletion(_ cycle: Cycle) {
        if cycle.isCycleCompleted() {
            showNewCycleAlert.accept(())
        }
    }
}
