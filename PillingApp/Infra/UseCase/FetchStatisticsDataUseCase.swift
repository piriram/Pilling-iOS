import RxSwift
import Foundation

protocol FetchStatisticsDataUseCaseProtocol {
    func execute() -> Observable<[PeriodRecordDTO]>
}

//MARK: - 모든 사이클 히스토리를 통계 데이터로 변환하는 유스케이스
final class FetchStatisticsDataUseCase: FetchStatisticsDataUseCaseProtocol {
    private let cycleHistoryRepository: CycleHistoryProtocol
    private let userDefaultsManager: UserDefaultsManagerProtocol

    init(
        cycleHistoryRepository: CycleHistoryProtocol,
        userDefaultsManager: UserDefaultsManagerProtocol
    ) {
        self.cycleHistoryRepository = cycleHistoryRepository
        self.userDefaultsManager = userDefaultsManager
    }

    func execute() -> Observable<[PeriodRecordDTO]> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(NSError(domain: "FetchStatisticsDataUseCase", code: -1))
                return Disposables.create()
            }

            do {
                let cycles = try self.cycleHistoryRepository.fetchAllCycles()
                let pillInfo = self.userDefaultsManager.loadPillInfo()

                let periodRecords = cycles.map { cycle in
                    self.mapCycleToPeriodRecord(cycle: cycle, pillInfo: pillInfo)
                }

                observer.onNext(periodRecords)
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }

            return Disposables.create()
        }
    }

    private func mapCycleToPeriodRecord(cycle: Cycle, pillInfo: PillInfo?) -> PeriodRecordDTO {
        let calendar = Calendar.current

        // Calculate date range
        let startDate = cycle.startDate
        let endDate = calendar.date(byAdding: .day, value: cycle.totalDays - 1, to: startDate) ?? startDate

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current

        // Full date format (for sheet)
        let startDateString: String
        let endDateString: String
        let startDateShortString: String
        let endDateShortString: String

        if Locale.current.language.languageCode?.identifier == "en" {
            // 영어: 년/월/일 (시트용)
            dateFormatter.dateFormat = "yyyy/MM/dd"
            startDateString = dateFormatter.string(from: startDate)
            endDateString = dateFormatter.string(from: endDate)

            // 영어: 월/일 (버튼용)
            dateFormatter.dateFormat = "MM/dd"
            startDateShortString = dateFormatter.string(from: startDate)
            endDateShortString = dateFormatter.string(from: endDate)
        } else {
            // 한글: 월/일 (공통)
            dateFormatter.setLocalizedDateFormatFromTemplate("MMMMd")
            startDateString = dateFormatter.string(from: startDate)
            endDateString = dateFormatter.string(from: endDate)
            startDateShortString = startDateString
            endDateShortString = endDateString
        }

        // Filter only active days (exclude rest days)
        let activeDayRecords = cycle.records.filter { record in
            record.cycleDay <= cycle.activeDays
        }

        // Check if period is empty (no records or all scheduled)
        let isEmpty = activeDayRecords.isEmpty || activeDayRecords.allSatisfy { $0.status == .scheduled || $0.status == .rest }

        if isEmpty {
            return PeriodRecordDTO(
                startDate: startDateString,
                endDate: endDateString,
                startDateShort: startDateShortString,
                endDateShort: endDateShortString,
                completionRate: 0,
                medicineName: pillInfo?.name ?? "",
                records: [],
                skippedCount: 0,
                sideEffectStats: [],
                isEmpty: true
            )
        }

        // Calculate statistics by category
        var onTimeCount = 0
        var lateCount = 0
        var missedOrDoubleCount = 0
        var totalTaken = 0

        for record in activeDayRecords {
            switch record.status {
            case .taken:
                onTimeCount += 1
                totalTaken += 1
            case .takenDelayed, .takenTooEarly:
                lateCount += 1
                totalTaken += 1
            case .takenDouble:
                missedOrDoubleCount += 1
                totalTaken += 1
            case .missed, .recentlyMissed, .notTaken, .scheduled:
                missedOrDoubleCount += 1
            case .rest:
                break
            }
        }

        let totalActiveDays = activeDayRecords.count
        let completionRate = totalActiveDays > 0 ? Int((Double(totalTaken) / Double(totalActiveDays)) * 100) : 0

        // Calculate percentages
        let onTimePercentage = totalActiveDays > 0 ? Int((Double(onTimeCount) / Double(totalActiveDays)) * 100) : 0
        let latePercentage = totalActiveDays > 0 ? Int((Double(lateCount) / Double(totalActiveDays)) * 100) : 0
        let missedPercentage = totalActiveDays > 0 ? Int((Double(missedOrDoubleCount) / Double(totalActiveDays)) * 100) : 0

        var recordItems: [RecordItemDTO] = []

        if onTimeCount > 0 {
            recordItems.append(RecordItemDTO(
                category: AppStrings.Statistics.categoryOnTime,
                percentage: onTimePercentage,
                days: onTimeCount,
                colorHex: "#99D94C"
            ))
        }

        if lateCount > 0 {
            recordItems.append(RecordItemDTO(
                category: AppStrings.Statistics.categoryDelayed,
                percentage: latePercentage,
                days: lateCount,
                colorHex: "#4C8033"
            ))
        }

        if missedOrDoubleCount > 0 {
            recordItems.append(RecordItemDTO(
                category: AppStrings.Statistics.categoryMissedOrDouble,
                percentage: missedPercentage,
                days: missedOrDoubleCount,
                colorHex: "#B3B3B3"
            ))
        }

        // Calculate side effect statistics
        let sideEffectStats = calculateSideEffectStats(from: activeDayRecords)

        return PeriodRecordDTO(
            startDate: startDateString,
            endDate: endDateString,
            startDateShort: startDateShortString,
            endDateShort: endDateShortString,
            completionRate: completionRate,
            medicineName: pillInfo?.name ?? "",
            records: recordItems,
            skippedCount: 0, // Hard-coded as requested
            sideEffectStats: sideEffectStats,
            isEmpty: false
        )
    }

    private func calculateSideEffectStats(from records: [DayRecord]) -> [SideEffectStatDTO] {
        // Get side effect tags from UserDefaults
        let sideEffectTags = userDefaultsManager.loadSideEffectTags()
        let tagMap = Dictionary(uniqueKeysWithValues: sideEffectTags.map { ($0.id, $0.name) })

        // Count side effect occurrences and collect saved tag names
        var sideEffectCounts: [String: Int] = [:]
        var savedTagNames: [String: String] = [:]  // tagId -> 저장된 이름 (삭제된 태그 대비)

        for record in records {
            let parsedMemo = PillRecordMemo.fromJSONString(record.memo)

            for tagId in parsedMemo.sideEffectIds {
                sideEffectCounts[tagId, default: 0] += 1

                // 저장된 태그 이름 보존 (삭제된 태그 대비)
                if let savedName = parsedMemo.sideEffectNames?[tagId] {
                    savedTagNames[tagId] = savedName
                }
            }
        }

        // Convert to SideEffectStatDTO and sort by count (descending)
        let result = sideEffectCounts
            .map { (tagId, count) -> SideEffectStatDTO in
                // 우선순위: 1) 현재 태그 이름, 2) 저장된 이름, 3) "삭제된 부작용"
                let tagName: String
                if let currentName = tagMap[tagId] {
                    // 현재 태그가 존재하면 현재 이름 사용 (태그 이름이 변경되었을 수 있음)
                    tagName = currentName
                } else if let savedName = savedTagNames[tagId] {
                    // 태그가 삭제되었지만 저장된 이름이 있으면 사용
                    tagName = savedName
                } else {
                    // 저장된 이름도 없으면 fallback
                    tagName = AppStrings.Statistics.deletedSideEffect
                }
                return SideEffectStatDTO(tagId: tagId, tagName: tagName, count: count)
            }
            .sorted { $0.count > $1.count }

        return result
    }
}
