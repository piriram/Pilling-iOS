import UIKit
import SnapKit
import RxSwift
import RxCocoa

// MARK: - Presentation/Common/Constants/AppColor.swift

public enum AppColor {
    public static let bg = UIColor.systemBackground
    public static let card = UIColor.secondarySystemBackground
    public static let pillGreen = UIColor(red: 0.72, green: 0.91, blue: 0.53, alpha: 1.0)
    public static let pillBrown = UIColor(red: 0.66, green: 0.60, blue: 0.49, alpha: 1.0)
    public static let pillGray = UIColor(red: 0.90, green: 0.90, blue: 0.90, alpha: 1.0)
    public static let pillWhite = UIColor.white
    public static let pillBorder = UIColor.black
    public static let text = UIColor.label
    public static let subtext = UIColor.secondaryLabel
}

// MARK: - Presentation/Common/Constants/DashboardUI.swift

enum DashboardUI {
    enum Icon {
        static let info = UIImage(systemName: "info.circle.fill")
        static let gear = UIImage(systemName: "gearshape")
        static let date = UIImage(systemName: "calendar")
        static let time = UIImage(systemName: "clock")
        static let leaf = UIImage(systemName: "leaf.fill")
    }
    
    enum Metric {
        static let columns: CGFloat = 7
        static let gridInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        static let cellMin: CGFloat = 32
        static let cellMax: CGFloat = 72
        static let contentInset: CGFloat = 16
        static let headerImageSide: CGFloat = 96
        static let cornerRadius: CGFloat = 16
        static let actionHeight: CGFloat = 56
        
        static func calculateGridSpacing(for width: CGFloat) -> CGFloat {
            let availableWidth = width - gridInsets.left - gridInsets.right
            let cellWidth = availableWidth / columns
            
            if UIDevice.current.userInterfaceIdiom == .pad {
                return min(max(cellWidth * 0.15, 8), 16)
            } else {
                return min(max(cellWidth * 0.12, 4), 12)
            }
        }
    }
    
    enum CharacterImage: String {
        case happy = "character_happy"
        case proud = "character_proud"
        case warning = "character_warning"
        case reminder = "character_reminder"
        case calm = "character_calm"
        case worried = "character_worried"
    }
}

// MARK: - Domain/Entities/PillStatus.swift

enum PillStatus {
    case taken
    case takenDelayed
    case takenDouble
    case missed
    case todayNotTaken
    case todayTaken
    case todayTakenDelayed
    case todayDelayed
    case scheduled
    case rest
    
    var backgroundColor: UIColor {
        switch self {
        case .taken, .takenDelayed, .todayTaken, .todayTakenDelayed:
            return AppColor.pillGreen
        case .takenDouble:
            return AppColor.pillWhite
        case .missed:
            return AppColor.pillBrown
        case .scheduled, .todayNotTaken, .todayDelayed:
            return AppColor.pillGray
        case .rest:
            return AppColor.pillWhite
        }
    }
    
    var isToday: Bool {
        switch self {
        case .todayNotTaken, .todayTaken, .todayTakenDelayed, .todayDelayed:
            return true
        default:
            return false
        }
    }
    
    var isTaken: Bool {
        switch self {
        case .taken, .takenDelayed, .takenDouble, .todayTaken, .todayTakenDelayed:
            return true
        default:
            return false
        }
    }
}

// MARK: - Domain/Entities/PillRecord.swift

struct PillRecord {
    let id: UUID
    let cycleDay: Int
    let status: PillStatus
    let scheduledDateTime: Date
    let takenAt: Date?
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - Domain/Entities/PillCycle.swift

struct PillCycle {
    let id: UUID
    let cycleNumber: Int
    let startDate: Date
    let activeDays: Int
    let breakDays: Int
    let scheduledTime: String
    var records: [PillRecord]
    let createdAt: Date
    
    var totalDays: Int { activeDays + breakDays }
    
    func isActiveDay(forDay day: Int) -> Bool {
        return day >= 1 && day <= activeDays
    }
    
    func isBreakDay(forDay day: Int) -> Bool {
        return day > activeDays && day <= totalDays
    }
}

// MARK: - Domain/Entities/UserSettings.swift

struct UserSettings {
    let scheduledTime: Date
    let notificationEnabled: Bool
    let delayThresholdMinutes: Int
    
    static var `default`: UserSettings {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: now)
        let scheduledTime = calendar.date(from: components) ?? now
        
        return UserSettings(
            scheduledTime: scheduledTime,
            notificationEnabled: true,
            delayThresholdMinutes: 120
        )
    }
}

// MARK: - Domain/Entities/DayItem.swift

struct DayItem {
    let cycleDay: Int
    let date: Date
    let status: PillStatus
}

// MARK: - Domain/Entities/DashboardMessage.swift

struct DashboardMessage {
    let text: String
    let imageName: DashboardUI.CharacterImage
}

// MARK: - Domain/RepositoryProtocols/PillCycleRepositoryProtocol.swift

protocol PillCycleRepositoryProtocol {
    func fetchCurrentCycle() -> Observable<PillCycle?>
    func saveCycle(_ cycle: PillCycle) -> Observable<Void>
    func updateRecord(_ record: PillRecord, in cycleID: UUID) -> Observable<Void>
}

// MARK: - Domain/RepositoryProtocols/UserSettingsRepositoryProtocol.swift

protocol UserSettingsRepositoryProtocol {
    func fetchSettings() -> Observable<UserSettings>
    func saveSettings(_ settings: UserSettings) -> Observable<Void>
}

// MARK: - Domain/UseCases/FetchDashboardDataUseCase.swift

protocol FetchDashboardDataUseCaseProtocol {
    func execute() -> Observable<(cycle: PillCycle?, settings: UserSettings)>
}

final class FetchDashboardDataUseCase: FetchDashboardDataUseCaseProtocol {
    private let cycleRepository: PillCycleRepositoryProtocol
    private let settingsRepository: UserSettingsRepositoryProtocol
    
    init(
        cycleRepository: PillCycleRepositoryProtocol,
        settingsRepository: UserSettingsRepositoryProtocol
    ) {
        self.cycleRepository = cycleRepository
        self.settingsRepository = settingsRepository
    }
    
    func execute() -> Observable<(cycle: PillCycle?, settings: UserSettings)> {
        return Observable.zip(
            cycleRepository.fetchCurrentCycle(),
            settingsRepository.fetchSettings()
        )
        .map { (cycle: $0, settings: $1) }
    }
}

// MARK: - Domain/UseCases/TakePillUseCase.swift

protocol TakePillUseCaseProtocol {
    func execute(cycle: PillCycle, settings: UserSettings) -> Observable<PillCycle>
}

final class TakePillUseCase: TakePillUseCaseProtocol {
    private let cycleRepository: PillCycleRepositoryProtocol
    
    init(cycleRepository: PillCycleRepositoryProtocol) {
        self.cycleRepository = cycleRepository
    }
    
    func execute(cycle: PillCycle, settings: UserSettings) -> Observable<PillCycle> {
        let calendar = Calendar.current
        let now = Date()
        
        guard let todayIndex = cycle.records.firstIndex(where: {
            calendar.isDate($0.scheduledDateTime, inSameDayAs: now)
        }) else {
            return .just(cycle)
        }
        
        var updatedCycle = cycle
        var record = updatedCycle.records[todayIndex]
        
        guard !record.status.isTaken else {
            return .just(cycle)
        }
        
        let timeDiff = now.timeIntervalSince(record.scheduledDateTime)
        let isWithinWindow = abs(timeDiff) <= Double(settings.delayThresholdMinutes * 60)
        let newStatus: PillStatus = isWithinWindow ? .todayTaken : .todayTakenDelayed
        
        let updatedRecord = PillRecord(
            id: record.id,
            cycleDay: record.cycleDay,
            status: newStatus,
            scheduledDateTime: record.scheduledDateTime,
            takenAt: now,
            createdAt: record.createdAt,
            updatedAt: now
        )
        
        updatedCycle.records[todayIndex] = updatedRecord
        
        return cycleRepository.updateRecord(updatedRecord, in: cycle.id)
            .map { updatedCycle }
    }
}

// MARK: - Domain/UseCases/UpdatePillStatusUseCase.swift

protocol UpdatePillStatusUseCaseProtocol {
    func execute(
        cycle: PillCycle,
        recordIndex: Int,
        newStatus: PillStatus
    ) -> Observable<PillCycle>
}

final class UpdatePillStatusUseCase: UpdatePillStatusUseCaseProtocol {
    private let cycleRepository: PillCycleRepositoryProtocol
    
    init(cycleRepository: PillCycleRepositoryProtocol) {
        self.cycleRepository = cycleRepository
    }
    
    func execute(
        cycle: PillCycle,
        recordIndex: Int,
        newStatus: PillStatus
    ) -> Observable<PillCycle> {
        guard cycle.records.indices.contains(recordIndex) else {
            return .just(cycle)
        }
        
        var updatedCycle = cycle
        var record = updatedCycle.records[recordIndex]
        let now = Date()
        
        let takenAt: Date? = newStatus.isTaken ? (record.takenAt ?? now) : nil
        
        let updatedRecord = PillRecord(
            id: record.id,
            cycleDay: record.cycleDay,
            status: newStatus,
            scheduledDateTime: record.scheduledDateTime,
            takenAt: takenAt,
            createdAt: record.createdAt,
            updatedAt: now
        )
        
        updatedCycle.records[recordIndex] = updatedRecord
        
        return cycleRepository.updateRecord(updatedRecord, in: cycle.id)
            .map { updatedCycle }
    }
}

// MARK: - Domain/UseCases/CalculateDashboardMessageUseCase.swift

protocol CalculateDashboardMessageUseCaseProtocol {
    func execute(cycle: PillCycle?, items: [DayItem]) -> DashboardMessage
}

final class CalculateDashboardMessageUseCase: CalculateDashboardMessageUseCaseProtocol {
    
    func execute(cycle: PillCycle?, items: [DayItem]) -> DashboardMessage {
        guard !items.isEmpty else {
            return DashboardMessage(text: "오늘은 잔디도 휴식중", imageName: .calm)
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        guard let todayItem = items.first(where: {
            calendar.isDate($0.date, inSameDayAs: now)
        }) else {
            return DashboardMessage(text: "오늘은 잔디도 휴식중", imageName: .calm)
        }
        
        let consecutiveMissed = calculateConsecutiveMissedDays(cycle: cycle)
        
        if consecutiveMissed >= 2 {
            return DashboardMessage(text: "저를 잊으셨나요 ㅠㅠ", imageName: .warning)
        }
        
        if let yesterdayItem = items.first(where: {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now) else {
                return false
            }
            return calendar.isDate($0.date, inSameDayAs: yesterday)
        }), case .missed = yesterdayItem.status {
            return DashboardMessage(
                text: "하루 빼먹었어요. 두알을 먹어야해요",
                imageName: .warning
            )
        }
        
        switch todayItem.status {
        case .todayTaken:
            return DashboardMessage(text: "잔디가 잘 자라고 있어요", imageName: .happy)
        case .todayTakenDelayed:
            return DashboardMessage(
                text: "규칙적인 시간에 복용해주세요 내일도 화이팅!",
                imageName: .reminder
            )
        case .todayDelayed:
            return DashboardMessage(
                text: "규칙적인 시간에 복용해주세요 내일도 화이팅!",
                imageName: .worried
            )
        case .todayNotTaken:
            return DashboardMessage(text: "오늘의 약을 빠르게 먹어주세요", imageName: .reminder)
        case .rest:
            return DashboardMessage(text: "오늘은 잔디도 휴식중", imageName: .calm)
        default:
            return DashboardMessage(text: "오늘은 잔디도 휴식중", imageName: .calm)
        }
    }
    
    private func calculateConsecutiveMissedDays(cycle: PillCycle?) -> Int {
        guard let cycle = cycle else { return 0 }
        
        let calendar = Calendar.current
        let now = Date()
        
        var count = 0
        for record in cycle.records.reversed() {
            let isPastOrToday = record.scheduledDateTime <= now
            guard isPastOrToday else { continue }
            
            let isNotTaken: Bool = {
                switch record.status {
                case .missed:
                    return true
                case .todayDelayed, .todayNotTaken:
                    return calendar.isDate(record.scheduledDateTime, inSameDayAs: now)
                default:
                    return false
                }
            }()
            
            if isNotTaken {
                count += 1
            } else {
                break
            }
        }
        
        return count
    }
}

// MARK: - Data/DataSources/CoreDataManager.swift

// CoreData Stack 관리
// 실제 구현은 CoreData 모델 설정 후 작성
final class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    // TODO: NSPersistentContainer 설정
    // TODO: NSManagedObjectContext 관리
    // TODO: CRUD 메서드 구현
}

// MARK: - Data/Repositories/CoreDataPillCycleRepository.swift

final class CoreDataPillCycleRepository: PillCycleRepositoryProtocol {
    private let coreDataManager: CoreDataManager
    
    init(coreDataManager: CoreDataManager) {
        self.coreDataManager = coreDataManager
    }
    
    func fetchCurrentCycle() -> Observable<PillCycle?> {
        // TODO: CoreData에서 현재 사이클 조회
        // 임시로 Mock 데이터 반환
        return .just(createMockCycle())
    }
    
    func saveCycle(_ cycle: PillCycle) -> Observable<Void> {
        // TODO: CoreData에 사이클 저장
        return .just(())
    }
    
    func updateRecord(_ record: PillRecord, in cycleID: UUID) -> Observable<Void> {
        // TODO: CoreData에서 레코드 업데이트
        return .just(())
    }
    
    // MARK: - Mock Data (임시)
    
    private func createMockCycle() -> PillCycle {
        let calendar = Calendar.current
        let now = Date()
        
        guard let startDate = calendar.date(byAdding: .day, value: -7, to: now) else {
            fatalError("Failed to calculate start date")
        }
        
        let activeDays = 21
        let breakDays = 7
        let totalDays = activeDays + breakDays
        
        let mockPattern: [Int: PillStatus] = [
            1: .taken,
            2: .taken,
            3: .missed,
            4: .takenDouble,
            5: .taken,
            6: .taken,
            7: .taken,
            8: .todayNotTaken
        ]
        
        var records: [PillRecord] = []
        let scheduledTime = UserSettings.default.scheduledTime
        
        for day in 1...totalDays {
            let dayOffset = day - 1
            guard let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else {
                continue
            }
            
            let scheduledDateTime = combineDateAndTime(date: dayDate, time: scheduledTime)
            
            let status: PillStatus
            if let mockStatus = mockPattern[day] {
                status = mockStatus
            } else {
                status = calculateStatus(
                    for: dayDate,
                    cycleDay: day,
                    scheduledDateTime: scheduledDateTime,
                    activeDays: activeDays,
                    totalDays: totalDays,
                    settings: .default
                )
            }
            
            let takenAt: Date? = status.isTaken ? dayDate : nil
            
            let record = PillRecord(
                id: UUID(),
                cycleDay: day,
                status: status,
                scheduledDateTime: scheduledDateTime,
                takenAt: takenAt,
                createdAt: now,
                updatedAt: now
            )
            records.append(record)
        }
        
        return PillCycle(
            id: UUID(),
            cycleNumber: 1,
            startDate: startDate,
            activeDays: activeDays,
            breakDays: breakDays,
            scheduledTime: timeString(from: scheduledTime),
            records: records,
            createdAt: now
        )
    }
    
    private func calculateStatus(
        for date: Date,
        cycleDay: Int,
        scheduledDateTime: Date,
        activeDays: Int,
        totalDays: Int,
        settings: UserSettings
    ) -> PillStatus {
        let calendar = Calendar.current
        let now = Date()
        
        if cycleDay > activeDays {
            return .rest
        }
        
        let isToday = calendar.isDate(date, inSameDayAs: now)
        let isFuture = date > calendar.startOfDay(for: now)
        
        if isFuture {
            return .scheduled
        }
        
        if isToday {
            let timeDiff = now.timeIntervalSince(scheduledDateTime)
            let isWithinWindow = abs(timeDiff) <= Double(settings.delayThresholdMinutes * 60)
            
            if isWithinWindow {
                return .todayNotTaken
            } else {
                return .todayDelayed
            }
        }
        
        return .missed
    }
    
    private func combineDateAndTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        
        return calendar.date(from: combined) ?? date
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

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

// MARK: - DI/DIContainer.swift

final class DIContainer {
    static let shared = DIContainer()
    
    private init() {}
    
    // MARK: - DataSources
    
    private lazy var coreDataManager: CoreDataManager = {
        return CoreDataManager.shared
    }()
    
    // MARK: - Repositories
    
    func makePillCycleRepository() -> PillCycleRepositoryProtocol {
        return CoreDataPillCycleRepository(coreDataManager: coreDataManager)
    }
    
    func makeUserSettingsRepository() -> UserSettingsRepositoryProtocol {
        return UserDefaultsUserSettingsRepository()
    }
    
    // MARK: - UseCases
    
    func makeFetchDashboardDataUseCase() -> FetchDashboardDataUseCaseProtocol {
        return FetchDashboardDataUseCase(
            cycleRepository: makePillCycleRepository(),
            settingsRepository: makeUserSettingsRepository()
        )
    }
    
    func makeTakePillUseCase() -> TakePillUseCaseProtocol {
        return TakePillUseCase(cycleRepository: makePillCycleRepository())
    }
    
    func makeUpdatePillStatusUseCase() -> UpdatePillStatusUseCaseProtocol {
        return UpdatePillStatusUseCase(cycleRepository: makePillCycleRepository())
    }
    
    func makeCalculateDashboardMessageUseCase() -> CalculateDashboardMessageUseCaseProtocol {
        return CalculateDashboardMessageUseCase()
    }
    
    // MARK: - ViewModels
    
    func makeDashboardViewModel() -> DashboardViewModel {
        return DashboardViewModel(
            fetchDashboardDataUseCase: makeFetchDashboardDataUseCase(),
            takePillUseCase: makeTakePillUseCase(),
            updatePillStatusUseCase: makeUpdatePillStatusUseCase(),
            calculateDashboardMessageUseCase: makeCalculateDashboardMessageUseCase()
        )
    }
}

// MARK: - Presentation/Dashboard/ViewModels/DashboardViewModel.swift

final class DashboardViewModel {
    
    private let fetchDashboardDataUseCase: FetchDashboardDataUseCaseProtocol
    private let takePillUseCase: TakePillUseCaseProtocol
    private let updatePillStatusUseCase: UpdatePillStatusUseCaseProtocol
    private let calculateDashboardMessageUseCase: CalculateDashboardMessageUseCaseProtocol
    
    private let disposeBag = DisposeBag()
    
    // MARK: - Outputs
    
    let settings = BehaviorRelay<UserSettings>(value: .default)
    let currentCycle = BehaviorRelay<PillCycle?>(value: nil)
    let items = BehaviorRelay<[DayItem]>(value: [])
    let dashboardMessage = BehaviorRelay<DashboardMessage?>(value: nil)
    let canTakePill = BehaviorRelay<Bool>(value: false)
    
    // MARK: - Initialization
    
    init(
        fetchDashboardDataUseCase: FetchDashboardDataUseCaseProtocol,
        takePillUseCase: TakePillUseCaseProtocol,
        updatePillStatusUseCase: UpdatePillStatusUseCaseProtocol,
        calculateDashboardMessageUseCase: CalculateDashboardMessageUseCaseProtocol
    ) {
        self.fetchDashboardDataUseCase = fetchDashboardDataUseCase
        self.takePillUseCase = takePillUseCase
        self.updatePillStatusUseCase = updatePillStatusUseCase
        self.calculateDashboardMessageUseCase = calculateDashboardMessageUseCase
        
        loadDashboardData()
    }
    
    // MARK: - Private Methods
    
    private func loadDashboardData() {
        fetchDashboardDataUseCase.execute()
            .subscribe(onNext: { [weak self] data in
                self?.settings.accept(data.settings)
                self?.currentCycle.accept(data.cycle)
                self?.updateItems()
                self?.updateDashboardMessage()
                self?.updateCanTakePill()
            })
            .disposed(by: disposeBag)
    }
    
    private func updateItems() {
        guard let cycle = currentCycle.value else { return }
        
        let dayItems = cycle.records.map { record in
            DayItem(
                cycleDay: record.cycleDay,
                date: record.scheduledDateTime,
                status: record.status
            )
        }
        
        items.accept(dayItems)
    }
    
    private func updateDashboardMessage() {
        let message = calculateDashboardMessageUseCase.execute(
            cycle: currentCycle.value,
            items: items.value
        )
        dashboardMessage.accept(message)
    }
    
    private func updateCanTakePill() {
        guard let cycle = currentCycle.value else {
            canTakePill.accept(false)
            return
        }
        
        let calendar = Calendar.current
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
        
        if todayRecord.status.isTaken {
            canTakePill.accept(false)
            return
        }
        
        canTakePill.accept(true)
    }
    
    // MARK: - Public Methods (Inputs)
    
    func takePill() {
        guard let cycle = currentCycle.value else { return }
        
        takePillUseCase.execute(cycle: cycle, settings: settings.value)
            .subscribe(onNext: { [weak self] updatedCycle in
                self?.currentCycle.accept(updatedCycle)
                self?.updateItems()
                self?.updateDashboardMessage()
                self?.updateCanTakePill()
            })
            .disposed(by: disposeBag)
    }
    
    func updateState(at index: Int, to newStatus: PillStatus) {
        guard let cycle = currentCycle.value else { return }
        
        updatePillStatusUseCase.execute(
            cycle: cycle,
            recordIndex: index,
            newStatus: newStatus
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

// MARK: - Presentation/Dashboard/Views/CalendarCell.swift

final class CalendarCell: UICollectionViewCell {
    static let identifier = "CalendarCell"
    
    private let backgroundShapeView = UIView()
    private let capsuleContainer = UIView()
    private let capsule1 = UIView()
    private let capsule2 = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let cornerRadius = min(bounds.width, bounds.height) * 0.25
        backgroundShapeView.layer.cornerRadius = cornerRadius
    }
    
    private func setupViews() {
        contentView.addSubview(backgroundShapeView)
        backgroundShapeView.addSubview(capsuleContainer)
        capsuleContainer.addSubview(capsule1)
        capsuleContainer.addSubview(capsule2)
        
        backgroundShapeView.layer.masksToBounds = true
        backgroundShapeView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        capsuleContainer.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalToSuperview()
        }
        
        capsule1.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.bottom.equalToSuperview()
            make.width.equalTo(capsule1.snp.height).multipliedBy(0.4)
        }
        
        capsule2.snp.makeConstraints { make in
            make.leading.equalTo(capsule1.snp.trailing).offset(2)
            make.trailing.equalToSuperview()
            make.top.bottom.equalToSuperview()
            make.width.equalTo(capsule1)
        }
        
        capsule1.layer.cornerRadius = 10
        capsule2.layer.cornerRadius = 10
        capsule1.backgroundColor = AppColor.pillGreen
        capsule2.backgroundColor = AppColor.pillGreen
        
        capsuleContainer.isHidden = true
        contentView.backgroundColor = .clear
    }
    
    func configure(with item: DayItem) {
        backgroundShapeView.layer.borderWidth = 0
        backgroundShapeView.layer.borderColor = UIColor.clear.cgColor
        capsuleContainer.isHidden = true
        
        backgroundShapeView.backgroundColor = item.status.backgroundColor
        
        if item.status.isToday {
            backgroundShapeView.layer.borderWidth = 2
            backgroundShapeView.layer.borderColor = AppColor.pillBorder.cgColor
        }
        
        if case .rest = item.status {
            backgroundShapeView.layer.borderWidth = 0.5
            backgroundShapeView.layer.borderColor = AppColor.pillGray.cgColor
        }
        
        if case .takenDouble = item.status {
            capsuleContainer.isHidden = false
        }
    }
}

// MARK: - Presentation/Dashboard/Views/CalendarSheetViewController.swift

final class CalendarSheetViewController: UIViewController {
    private let onSelectStatus: (PillStatus) -> Void
    private let disposeBag = DisposeBag()
    
    private lazy var containerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }()
    
    init(onSelectStatus: @escaping (PillStatus) -> Void) {
        self.onSelectStatus = onSelectStatus
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    private func setupViews() {
        view.backgroundColor = .systemBackground
        
        let titleLabel = UILabel()
        titleLabel.text = "상태 선택"
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        
        view.addSubview(containerStack)
        containerStack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        containerStack.addArrangedSubview(titleLabel)
        
        addStatusButton(title: "복용", status: .taken)
        addStatusButton(title: "지연 복용", status: .takenDelayed)
        addStatusButton(title: "2알 복용", status: .takenDouble)
        addStatusButton(title: "미복용", status: .missed)
        
        let divider = UIView()
        divider.backgroundColor = .separator
        divider.snp.makeConstraints { $0.height.equalTo(1) }
        containerStack.addArrangedSubview(divider)
        
        addStatusButton(title: "예정으로 변경", status: .scheduled, isDestructive: false)
        
        let spacer = UIView()
        spacer.snp.makeConstraints { $0.height.equalTo(12) }
        containerStack.addArrangedSubview(spacer)
    }
    
    private func addStatusButton(title: String, status: PillStatus, isDestructive: Bool = false) {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(isDestructive ? .systemRed : .label, for: .normal)
        button.contentHorizontalAlignment = .leading
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        button.backgroundColor = .secondarySystemBackground
        button.layer.cornerRadius = 12
        button.contentEdgeInsets = .init(top: 12, left: 14, bottom: 12, right: 14)
        containerStack.addArrangedSubview(button)
        
        button.rx.tap
            .bind { [weak self] in
                self?.dismiss(animated: true)
                self?.onSelectStatus(status)
            }
            .disposed(by: disposeBag)
    }
}

// MARK: - Presentation/Dashboard/Views/DashboardViewController.swift

final class DashboardViewController: UIViewController {
    
    private let viewModel: DashboardViewModel
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Components
    
    private let infoButton = UIButton(type: .system)
    private let gearButton = UIButton(type: .system)
    private let characterImageView = UIImageView()
    private let progressLabel = UILabel()
    private let totalLabel = UILabel()
    private let dateInfoStackView = UIStackView()
    private let dateIconImageView = UIImageView(image: DashboardUI.Icon.date)
    private let dateLabel = UILabel()
    private let timeIconImageView = UIImageView(image: DashboardUI.Icon.time)
    private let timeLabel = UILabel()
    
    private let messageCardView = UIView()
    private let messageIconImageView = UIImageView(image: DashboardUI.Icon.leaf)
    private let messageLabel = UILabel()
    
    private let weekdayStackView = UIStackView()
    
    private lazy var calendarCollectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: makeCompositionalLayout()
    )
    
    private let takePillButton = UIButton(type: .system)
    
    // MARK: - Initialization
    
    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        bindViewModel()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCalendarHeight(for: viewModel.items.value.count)
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        view.backgroundColor = AppColor.bg
        
        setupHeaderViews()
        setupMessageCardView()
        setupWeekdayStackView()
        setupCalendarCollectionView()
        setupTakePillButton()
        
        addSubviews()
    }
    
    private func setupHeaderViews() {
        infoButton.setImage(DashboardUI.Icon.info, for: .normal)
        gearButton.setImage(DashboardUI.Icon.gear, for: .normal)
        
        characterImageView.contentMode = .scaleAspectFit
        
        progressLabel.font = .systemFont(ofSize: 28, weight: .bold)
        totalLabel.font = .systemFont(ofSize: 20, weight: .regular)
        totalLabel.textColor = AppColor.subtext
        
        dateLabel.textColor = AppColor.subtext
        timeLabel.textColor = AppColor.subtext
        dateIconImageView.tintColor = AppColor.subtext
        timeIconImageView.tintColor = AppColor.subtext
        
        dateInfoStackView.axis = .vertical
        dateInfoStackView.alignment = .leading
        dateInfoStackView.spacing = 4
        
        let dateLine = UIStackView(arrangedSubviews: [dateIconImageView, dateLabel])
        dateLine.axis = .horizontal
        dateLine.spacing = 6
        
        let timeLine = UIStackView(arrangedSubviews: [timeIconImageView, timeLabel])
        timeLine.axis = .horizontal
        timeLine.spacing = 6
        
        dateInfoStackView.addArrangedSubview(dateLine)
        dateInfoStackView.addArrangedSubview(timeLine)
    }
    
    private func setupMessageCardView() {
        messageCardView.backgroundColor = AppColor.card
        messageCardView.layer.cornerRadius = DashboardUI.Metric.cornerRadius
        messageIconImageView.tintColor = AppColor.pillGreen
        messageLabel.textColor = AppColor.subtext
    }
    
    private func setupWeekdayStackView() {
        weekdayStackView.axis = .horizontal
        weekdayStackView.alignment = .fill
        weekdayStackView.distribution = .fillEqually
        weekdayStackView.spacing = 0
        
        ["월", "화", "수", "목", "금", "토", "일"].forEach { weekdayText in
            let containerView = UIView()
            let label = UILabel()
            label.text = weekdayText
            label.textAlignment = .center
            label.textColor = AppColor.subtext
            label.font = .systemFont(ofSize: 13, weight: .medium)
            containerView.addSubview(label)
            label.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.leading.trailing.equalToSuperview()
            }
            weekdayStackView.addArrangedSubview(containerView)
        }
    }
    
    private func setupCalendarCollectionView() {
        calendarCollectionView.backgroundColor = .clear
        calendarCollectionView.contentInset = .zero
        calendarCollectionView.isScrollEnabled = false
        calendarCollectionView.register(
            CalendarCell.self,
            forCellWithReuseIdentifier: CalendarCell.identifier
        )
        calendarCollectionView.setCollectionViewLayout(makeCompositionalLayout(), animated: false)
    }
    
    private func setupTakePillButton() {
        takePillButton.setTitle("잔디 심기", for: .normal)
        takePillButton.setTitleColor(.label, for: .normal)
        takePillButton.backgroundColor = AppColor.pillGreen.withAlphaComponent(0.4)
        takePillButton.layer.cornerRadius = DashboardUI.Metric.cornerRadius
    }
    
    private func addSubviews() {
        view.addSubview(infoButton)
        view.addSubview(gearButton)
        view.addSubview(characterImageView)
        view.addSubview(progressLabel)
        view.addSubview(totalLabel)
        view.addSubview(dateInfoStackView)
        
        view.addSubview(messageCardView)
        messageCardView.addSubview(messageIconImageView)
        messageCardView.addSubview(messageLabel)
        
        view.addSubview(weekdayStackView)
        view.addSubview(calendarCollectionView)
        view.addSubview(takePillButton)
    }
    
    private func setupConstraints() {
        infoButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.trailing.equalToSuperview().inset(DashboardUI.Metric.contentInset + 44)
            make.width.height.equalTo(28)
        }
        
        gearButton.snp.makeConstraints { make in
            make.centerY.equalTo(infoButton)
            make.trailing.equalToSuperview().inset(DashboardUI.Metric.contentInset)
            make.width.height.equalTo(28)
        }
        
        characterImageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.equalToSuperview().inset(DashboardUI.Metric.contentInset)
            make.width.height.equalTo(DashboardUI.Metric.headerImageSide)
        }
        
        progressLabel.snp.makeConstraints { make in
            make.top.equalTo(characterImageView.snp.top).offset(8)
            make.leading.equalTo(characterImageView.snp.trailing).offset(16)
        }
        
        totalLabel.snp.makeConstraints { make in
            make.leading.equalTo(progressLabel.snp.trailing).offset(4)
            make.lastBaseline.equalTo(progressLabel)
        }
        
        dateInfoStackView.snp.makeConstraints { make in
            make.leading.equalTo(progressLabel)
            make.top.equalTo(progressLabel.snp.bottom).offset(8)
            make.trailing.lessThanOrEqualTo(gearButton.snp.leading).offset(-8)
        }
        
        messageCardView.snp.makeConstraints { make in
            make.top.equalTo(characterImageView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(DashboardUI.Metric.contentInset)
            make.height.equalTo(52)
        }
        
        messageIconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(18)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.leading.equalTo(messageIconImageView.snp.trailing).offset(8)
            make.trailing.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
        }
        
        weekdayStackView.snp.makeConstraints { make in
            make.top.equalTo(messageCardView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(DashboardUI.Metric.contentInset)
            make.height.equalTo(18)
        }
        
        calendarCollectionView.snp.makeConstraints { make in
            make.top.equalTo(weekdayStackView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(DashboardUI.Metric.contentInset)
            make.height.equalTo(200)
        }
        
        takePillButton.snp.makeConstraints { make in
            make.top.greaterThanOrEqualTo(calendarCollectionView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(DashboardUI.Metric.contentInset)
            make.height.equalTo(DashboardUI.Metric.actionHeight)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
        }
    }
    
    // MARK: - Binding
    
    private func bindViewModel() {
        viewModel.items
            .bind(to: calendarCollectionView.rx.items(
                cellIdentifier: CalendarCell.identifier,
                cellType: CalendarCell.self
            )) { _, element, cell in
                cell.configure(with: element)
            }
            .disposed(by: disposeBag)
        
        viewModel.items
            .asDriver()
            .drive(onNext: { [weak self] items in
                self?.updateCalendarHeight(for: items.count)
            })
            .disposed(by: disposeBag)
        
        viewModel.currentCycle
            .compactMap { $0 }
            .asDriver(onErrorJustReturn: viewModel.currentCycle.value!)
            .drive(onNext: { [weak self] cycle in
                self?.updateCycleUI(cycle: cycle)
            })
            .disposed(by: disposeBag)
        
        viewModel.dashboardMessage
            .compactMap { $0 }
            .asDriver(onErrorJustReturn: DashboardMessage(text: "", imageName: .calm))
            .drive(onNext: { [weak self] message in
                self?.updateMessageUI(message: message)
            })
            .disposed(by: disposeBag)
        
        viewModel.canTakePill
            .asDriver()
            .drive(onNext: { [weak self] canTake in
                self?.updateTakePillButton(canTake: canTake)
            })
            .disposed(by: disposeBag)
        
        infoButton.rx.tap
            .bind { [weak self] in
                self?.presentInfoFloatingView()
            }
            .disposed(by: disposeBag)
        
        takePillButton.rx.tap
            .bind { [weak self] in
                self?.viewModel.takePill()
            }
            .disposed(by: disposeBag)
        
        Observable.zip(
            calendarCollectionView.rx.itemSelected,
            calendarCollectionView.rx.modelSelected(DayItem.self)
        )
        .bind { [weak self] indexPath, item in
            self?.handleCellSelection(at: indexPath.item, item: item)
        }
        .disposed(by: disposeBag)
    }
    
    // MARK: - UI Updates
    
    private func updateCycleUI(cycle: PillCycle) {
        let calendar = Calendar.current
        let now = Date()
        
        let daysSinceStart = calendar.dateComponents([.day], from: cycle.startDate, to: now).day ?? 0
        let currentDay = daysSinceStart + 1
        
        progressLabel.text = "\(currentDay)일차"
        totalLabel.text = "/\(cycle.totalDays)"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd"
        let startDateString = dateFormatter.string(from: cycle.startDate)
        dateLabel.text = "시작일 \(startDateString) · \(cycle.activeDays)/\(cycle.breakDays)"
        
        timeLabel.text = cycle.scheduledTime
        
        updateWeekdayStart(from: cycle.startDate)
    }
    
    private func updateMessageUI(message: DashboardMessage) {
        messageLabel.text = message.text
        
        if let image = UIImage(named: message.imageName.rawValue) {
            characterImageView.image = image
        } else {
            characterImageView.image = UIImage(systemName: "face.smiling")
        }
    }
    
    private func updateTakePillButton(canTake: Bool) {
        guard let cycle = viewModel.currentCycle.value else { return }
        
        let calendar = Calendar.current
        let now = Date()
        
        guard let todayRecord = cycle.records.first(where: {
            calendar.isDate($0.scheduledDateTime, inSameDayAs: now)
        }) else {
            return
        }
        
        if case .rest = todayRecord.status {
            takePillButton.setTitle("휴약 기간", for: .normal)
            takePillButton.backgroundColor = AppColor.pillWhite
            takePillButton.isEnabled = false
        } else if todayRecord.status.isTaken {
            takePillButton.setTitle("심기 완료!", for: .normal)
            takePillButton.backgroundColor = AppColor.pillGray
            takePillButton.isEnabled = false
        } else if canTake {
            takePillButton.setTitle("잔디 심기", for: .normal)
            takePillButton.backgroundColor = AppColor.pillGreen.withAlphaComponent(0.4)
            takePillButton.isEnabled = true
        } else {
            takePillButton.setTitle("잔디 심기", for: .normal)
            takePillButton.backgroundColor = AppColor.pillGray
            takePillButton.isEnabled = false
        }
    }
    
    private func updateWeekdayStart(from startDate: Date) {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: startDate)
        
        let baseWeekdays = ["월", "화", "수", "목", "금", "토", "일"]
        
        let startIndex: Int = {
            switch weekday {
            case 2: return 0
            case 3: return 1
            case 4: return 2
            case 5: return 3
            case 6: return 4
            case 7: return 5
            case 1: fallthrough
            default: return 6
            }
        }()
        
        let rotatedWeekdays = Array(baseWeekdays[startIndex...]) + Array(baseWeekdays[..<startIndex])
        
        guard weekdayStackView.arrangedSubviews.count == 7 else { return }
        
        for (index, view) in weekdayStackView.arrangedSubviews.enumerated() {
            if let label = view.subviews.first(where: { $0 is UILabel }) as? UILabel {
                label.text = rotatedWeekdays[index]
            }
        }
    }
    
    private func updateCalendarHeight(for itemCount: Int) {
        let width = view.bounds.width - (DashboardUI.Metric.contentInset * 2)
        guard width > 0 else { return }
        
        let columns = Int(DashboardUI.Metric.columns)
        let rows = ceil(CGFloat(itemCount) / DashboardUI.Metric.columns)
        let insets = DashboardUI.Metric.gridInsets
        let spacing = DashboardUI.Metric.calculateGridSpacing(for: width)
        let totalSpacing = spacing * (DashboardUI.Metric.columns - 1)
        let itemSide = (width - totalSpacing) / DashboardUI.Metric.columns
        let height = insets.top + insets.bottom + rows * itemSide + (rows - 1) * spacing
        
        calendarCollectionView.snp.updateConstraints { $0.height.equalTo(height) }
        calendarCollectionView.setCollectionViewLayout(makeCompositionalLayout(), animated: false)
        view.layoutIfNeeded()
    }
    
    // MARK: - User Interactions
    
    private func handleCellSelection(at index: Int, item: DayItem) {
        if case .scheduled = item.status {
            return
        }
        if case .rest = item.status {
            return
        }
        
        let calendar = Calendar.current
        let isToday = calendar.isDate(item.date, inSameDayAs: Date())
        
        if !isToday || item.status.isTaken {
            presentCalendarSheet(for: index, item: item)
        }
    }
    
    private func presentCalendarSheet(for index: Int, item: DayItem) {
        if #available(iOS 15.0, *) {
            let viewController = CalendarSheetViewController { [weak self] chosenStatus in
                self?.viewModel.updateState(at: index, to: chosenStatus)
            }
            viewController.modalPresentationStyle = .pageSheet
            
            if let sheet = viewController.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.preferredCornerRadius = 24
                sheet.prefersGrabberVisible = true
            }
            
            present(viewController, animated: true)
            return
        }
        
        let alertController = UIAlertController(title: "상태 선택", message: nil, preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: "복용", style: .default) { [weak self] _ in
            self?.viewModel.updateState(at: index, to: .taken)
        })
        
        alertController.addAction(UIAlertAction(title: "지연 복용", style: .default) { [weak self] _ in
            self?.viewModel.updateState(at: index, to: .takenDelayed)
        })
        
        alertController.addAction(UIAlertAction(title: "2알 복용", style: .default) { [weak self] _ in
            self?.viewModel.updateState(at: index, to: .takenDouble)
        })
        
        alertController.addAction(UIAlertAction(title: "미복용", style: .default) { [weak self] _ in
            self?.viewModel.updateState(at: index, to: .missed)
        })
        
        alertController.addAction(UIAlertAction(title: "예정으로 변경", style: .default) { [weak self] _ in
            self?.viewModel.updateState(at: index, to: .scheduled)
        })
        
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        present(alertController, animated: true)
    }
    
    private func presentInfoFloatingView() {
        let dimmedBackgroundView = UIView()
        dimmedBackgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        dimmedBackgroundView.alpha = 0
        
        let floatingCardView = UIView()
        floatingCardView.backgroundColor = .systemBackground
        floatingCardView.layer.cornerRadius = 30
        floatingCardView.layer.masksToBounds = true
        
        let titleLabel = UILabel()
        titleLabel.text = "필링 가이드"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = AppColor.text
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "피임약 복용 상태를 잔디로 알려드려요!"
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = AppColor.subtext
        
        let guideStackView = UIStackView()
        guideStackView.axis = .vertical
        guideStackView.spacing = 16
        guideStackView.alignment = .leading
        
        let guideItem1 = makeGuideItem(
            iconColor: AppColor.pillGreen,
            iconType: .solid,
            text: "피임약 복용"
        )
        
        let guideItem2 = makeGuideItem(
            iconColor: AppColor.pillWhite,
            iconType: .doubleCapsule,
            text: "피임약 2알 복용"
        )
        
        let guideItem3 = makeGuideItem(
            iconColor: AppColor.pillBrown,
            iconType: .solid,
            text: "미복용"
        )
        
        let guideItem4 = makeGuideItem(
            iconColor: AppColor.pillWhite,
            iconType: .border,
            text: "휴약"
        )
        
        guideStackView.addArrangedSubview(guideItem1)
        guideStackView.addArrangedSubview(guideItem2)
        guideStackView.addArrangedSubview(guideItem3)
        guideStackView.addArrangedSubview(guideItem4)
        
        let confirmButton = UIButton(type: .system)
        confirmButton.setTitle("확인", for: .normal)
        confirmButton.setTitleColor(.label, for: .normal)
        confirmButton.backgroundColor = AppColor.pillGray
        confirmButton.layer.cornerRadius = 12
        confirmButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        
        view.addSubview(dimmedBackgroundView)
        view.addSubview(floatingCardView)
        floatingCardView.addSubview(titleLabel)
        floatingCardView.addSubview(subtitleLabel)
        floatingCardView.addSubview(guideStackView)
        floatingCardView.addSubview(confirmButton)
        
        dimmedBackgroundView.snp.makeConstraints { $0.edges.equalToSuperview() }
        floatingCardView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(316)
            make.height.equalTo(390)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(32)
            make.leading.equalToSuperview().offset(32)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(32)
        }
        guideStackView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(32)
        }
        confirmButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().inset(24)
            make.height.equalTo(52)
        }
        
        UIView.animate(withDuration: 0.3) {
            dimmedBackgroundView.alpha = 1
        }
        
        let dismissAction = { [weak self] in
            UIView.animate(withDuration: 0.3, animations: {
                dimmedBackgroundView.alpha = 0
            }) { _ in
                dimmedBackgroundView.removeFromSuperview()
                floatingCardView.removeFromSuperview()
            }
        }
        
        confirmButton.rx.tap
            .bind { dismissAction() }
            .disposed(by: disposeBag)
        
        let tapGesture = UITapGestureRecognizer()
        dimmedBackgroundView.addGestureRecognizer(tapGesture)
        tapGesture.rx.event
            .bind { _ in dismissAction() }
            .disposed(by: disposeBag)
    }
    
    private enum GuideIconType {
        case solid
        case doubleCapsule
        case border
    }
    
    private func makeGuideItem(iconColor: UIColor, iconType: GuideIconType, text: String) -> UIView {
        let containerView = UIView()
        
        let iconView = UIView()
        iconView.backgroundColor = iconColor
        iconView.layer.cornerRadius = 8
        
        switch iconType {
        case .solid:
            break
        case .doubleCapsule:
            let capsule1 = UIView()
            let capsule2 = UIView()
            capsule1.backgroundColor = AppColor.pillGreen
            capsule2.backgroundColor = AppColor.pillGreen
            capsule1.layer.cornerRadius = 4
            capsule2.layer.cornerRadius = 4
            
            iconView.addSubview(capsule1)
            iconView.addSubview(capsule2)
            
            capsule1.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(6)
                make.centerY.equalToSuperview()
                make.width.equalTo(10)
                make.height.equalTo(24)
            }
            capsule2.snp.makeConstraints { make in
                make.leading.equalTo(capsule1.snp.trailing).offset(2)
                make.centerY.equalToSuperview()
                make.width.equalTo(10)
                make.height.equalTo(24)
            }
        case .border:
            iconView.layer.borderWidth = 1
            iconView.layer.borderColor = AppColor.pillGray.cgColor
        }
        
        let textLabel = UILabel()
        textLabel.text = text
        textLabel.font = .systemFont(ofSize: 16, weight: .regular)
        textLabel.textColor = AppColor.text
        
        containerView.addSubview(iconView)
        containerView.addSubview(textLabel)
        
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }
        textLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(16)
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        containerView.snp.makeConstraints { make in
            make.height.equalTo(40)
        }
        
        return containerView
    }
    
    // MARK: - CollectionView Layout
    
    private func makeCompositionalLayout() -> UICollectionViewCompositionalLayout {
        let width = view.bounds.width - (DashboardUI.Metric.contentInset * 2)
        let columns = Int(DashboardUI.Metric.columns)
        let spacing = DashboardUI.Metric.calculateGridSpacing(for: width)
        let insets = DashboardUI.Metric.gridInsets
        
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0 / CGFloat(columns)),
            heightDimension: .fractionalWidth(1.0 / CGFloat(columns))
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(
            top: spacing / 2,
            leading: spacing / 2,
            bottom: spacing / 2,
            trailing: spacing / 2
        )
        
        let groupHeight = NSCollectionLayoutDimension.fractionalWidth(1.0 / CGFloat(columns))
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: groupHeight
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitem: item,
            count: columns
        )
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: insets.top,
            leading: 0,
            bottom: insets.bottom,
            trailing: 0
        )
        
        return UICollectionViewCompositionalLayout(section: section)
    }
}
