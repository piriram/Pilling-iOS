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

        return PeriodRecordDTO(
            startDate: startDateString,
            endDate: endDateString,
            completionRate: completionRate,
            medicineName: pillInfo?.name ?? "",
            records: recordItems,
            skippedCount: 0, // Hard-coded as requested
            isEmpty: false
        )
    }
}
