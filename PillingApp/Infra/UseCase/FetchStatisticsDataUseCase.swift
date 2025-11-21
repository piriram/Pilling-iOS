//
//  FetchStatisticsDataUseCase.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 11/17/25.
//

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
        // 🔍 [디버깅] 사이클 -> 기간 레코드 변환 시작
        print("🔍 [FetchStatisticsDataUseCase] mapCycleToPeriodRecord 호출")
        print("   🆔 cycle.id: \(cycle.id)")
        print("   📅 activeDays: \(cycle.activeDays)")
        print("   📅 totalDays: \(cycle.totalDays)")
        print("   📊 전체 레코드 수: \(cycle.records.count)")

        let calendar = Calendar.current

        // Calculate date range
        let startDate = cycle.startDate
        let endDate = calendar.date(byAdding: .day, value: cycle.totalDays - 1, to: startDate) ?? startDate

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.dateFormat = "M월 d일"

        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)

        // Filter only active days (exclude rest days)
        let activeDayRecords = cycle.records.filter { record in
            record.cycleDay <= cycle.activeDays
        }

        print("   📊 Active Day 레코드 수: \(activeDayRecords.count)")
        for (index, record) in activeDayRecords.enumerated() {
            print("      [\(index)] cycleDay: \(record.cycleDay), status: \(record.status), memo: '\(record.memo)'")
        }

        // Check if period is empty (no records or all scheduled)
        let isEmpty = activeDayRecords.isEmpty || activeDayRecords.allSatisfy { $0.status == .scheduled || $0.status == .rest }

        if isEmpty {
            return PeriodRecordDTO(
                startDate: startDateString,
                endDate: endDateString,
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
            let adjustedStatus = record.status.adjustedForDate(record.scheduledDateTime, calendar: calendar)

            switch adjustedStatus {
            case .taken, .todayTaken:
                onTimeCount += 1
                totalTaken += 1
            case .takenDelayed, .todayTakenDelayed, .takenTooEarly, .todayTakenTooEarly:
                lateCount += 1
                totalTaken += 1
            case .takenDouble:
                missedOrDoubleCount += 1
                totalTaken += 1
            case .missed, .todayDelayed, .todayDelayedCritical, .todayNotTaken, .scheduled:
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
                category: "정시에 복용했어요",
                percentage: onTimePercentage,
                days: onTimeCount,
                colorHex: "#99D94C"
            ))
        }

        if lateCount > 0 {
            recordItems.append(RecordItemDTO(
                category: "조금 늦었어요",
                percentage: latePercentage,
                days: lateCount,
                colorHex: "#4C8033"
            ))
        }

        if missedOrDoubleCount > 0 {
            recordItems.append(RecordItemDTO(
                category: "미복용 및 2알 복용",
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
            completionRate: completionRate,
            medicineName: pillInfo?.name ?? "",
            records: recordItems,
            skippedCount: 0, // Hard-coded as requested
            sideEffectStats: sideEffectStats,
            isEmpty: false
        )
    }

    private func calculateSideEffectStats(from records: [DayRecord]) -> [SideEffectStatDTO] {
        // 🔍 [디버깅] 부작용 통계 계산 시작
        print("🔍 [FetchStatisticsDataUseCase] calculateSideEffectStats 호출")
        print("   📊 전달받은 records.count: \(records.count)")

        // Get side effect tags from UserDefaults
        let sideEffectTags = userDefaultsManager.loadSideEffectTags()
        let tagMap = Dictionary(uniqueKeysWithValues: sideEffectTags.map { ($0.id, $0.name) })

        print("   🏷️ 등록된 부작용 태그 수: \(sideEffectTags.count)")
        print("   🏷️ 태그 맵: \(tagMap)")

        // Count side effect occurrences and collect saved tag names
        var sideEffectCounts: [String: Int] = [:]
        var savedTagNames: [String: String] = [:]  // tagId -> 저장된 이름 (삭제된 태그 대비)

        for (index, record) in records.enumerated() {
            print("   📝 [\(index)] record.memo: '\(record.memo)'")

            let parsedMemo = PillRecordMemo.fromJSONString(record.memo)
            print("      📦 parsedMemo.text: '\(parsedMemo.text)'")
            print("      🏷️ parsedMemo.sideEffectIds: \(parsedMemo.sideEffectIds)")
            print("      📛 parsedMemo.sideEffectNames: \(parsedMemo.sideEffectNames ?? [:])")

            for tagId in parsedMemo.sideEffectIds {
                sideEffectCounts[tagId, default: 0] += 1
                print("         ➕ tagId '\(tagId)' 카운트: \(sideEffectCounts[tagId]!)")

                // 저장된 태그 이름 보존 (삭제된 태그 대비)
                if let savedName = parsedMemo.sideEffectNames?[tagId] {
                    savedTagNames[tagId] = savedName
                    print("         📛 저장된 이름: '\(savedName)'")
                }
            }
        }

        print("   📊 최종 sideEffectCounts: \(sideEffectCounts)")
        print("   📛 최종 savedTagNames: \(savedTagNames)")

        // Convert to SideEffectStatDTO and sort by count (descending)
        let result = sideEffectCounts
            .map { (tagId, count) -> SideEffectStatDTO in
                // 우선순위: 1) 저장된 이름, 2) 현재 태그 이름, 3) "삭제된 부작용"
                let tagName: String
                if let savedName = savedTagNames[tagId] {
                    tagName = savedName
                    print("   ✅ 통계 생성 (저장된 이름 사용): \(tagName) - \(count)회")
                } else if let currentName = tagMap[tagId] {
                    tagName = currentName
                    print("   ✅ 통계 생성 (현재 태그 이름 사용): \(tagName) - \(count)회")
                } else {
                    tagName = "삭제된 부작용"
                    print("   ⚠️ tagId '\(tagId)'에 해당하는 태그 이름을 찾을 수 없음 -> '삭제된 부작용'으로 표시")
                }
                return SideEffectStatDTO(tagId: tagId, tagName: tagName, count: count)
            }
            .sorted { $0.count > $1.count }

        print("   🎯 최종 반환 결과 개수: \(result.count)")
        for stat in result {
            print("      - \(stat.tagName): \(stat.count)회")
        }

        return result
    }
}
