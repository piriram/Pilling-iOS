//
//  RecordChartViewModel.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 11/6/25.
//

import RxSwift
import RxCocoa

// MARK: - ViewModel
final class StatisticsViewModel {
    
    struct Input {
        let viewDidLoad: Observable<Void>
        let leftArrowTapped: Observable<Void>
        let rightArrowTapped: Observable<Void>
        let periodButtonTapped: Observable<Void>
    }
    
    struct Output {
        let currentPeriodData: Observable<PeriodRecordDTO>
        let isLeftArrowEnabled: Observable<Bool>
        let isRightArrowEnabled: Observable<Bool>
        let periodList: Observable<[PeriodRecordDTO]>
    }
    
    private let disposeBag = DisposeBag()
    private let currentIndexSubject = BehaviorSubject<Int>(value: 0)
    private let mockDataList: [PeriodRecordDTO] = [
        PeriodRecordDTO(
            startDate: "9월 1일",
            endDate: "10월 1일",
            completionRate: 85,
            medicineName: "야즈",
            records: [
                RecordItemDTO(category: "정시에 복용했어요", percentage: 45, days: 10, colorHex: "#99D94C"),
                RecordItemDTO(category: "조금 늦었어요", percentage: 40, days: 9, colorHex: "#4C8033"),
                RecordItemDTO(category: "미복용 및 2알 복용", percentage: 30, days: 3, colorHex: "#B3B3B3")
            ],
            skippedCount: 2,
            isEmpty: false
        ),
        PeriodRecordDTO(
            startDate: "10월 1일",
            endDate: "11월 1일",
            completionRate: 0,
            medicineName: "야즈",
            records: [],
            skippedCount: 0,
            isEmpty: true
        ),
        PeriodRecordDTO(
            startDate: "11월 1일",
            endDate: "12월 1일",
            completionRate: 95,
            medicineName: "야즈",
            records: [
                RecordItemDTO(category: "정시에 복용했어요", percentage: 60, days: 15, colorHex: "#99D94C"),
                RecordItemDTO(category: "조금 늦었어요", percentage: 35, days: 8, colorHex: "#4C8033"),
                RecordItemDTO(category: "미복용 및 2알 복용", percentage: 20, days: 1, colorHex: "#B3B3B3")
            ],
            skippedCount: 1,
            isEmpty: false
        )
    ]
    
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .subscribe()
            .disposed(by: disposeBag)
        
        input.leftArrowTapped
            .withLatestFrom(currentIndexSubject)
            .filter { $0 > 0 }
            .map { $0 - 1 }
            .bind(to: currentIndexSubject)
            .disposed(by: disposeBag)
        
        input.rightArrowTapped
            .withLatestFrom(currentIndexSubject)
            .filter { [weak self] index in
                guard let self = self else { return false }
                return index < self.mockDataList.count - 1
            }
            .map { $0 + 1 }
            .bind(to: currentIndexSubject)
            .disposed(by: disposeBag)
        
        let currentPeriodData = currentIndexSubject
            .map { [weak self] index -> PeriodRecordDTO in
                guard let self = self else { return self!.mockDataList[0] }
                return self.mockDataList[index]
            }
        
        let isLeftArrowEnabled = currentIndexSubject
            .map { $0 > 0 }
        
        let isRightArrowEnabled = currentIndexSubject
            .map { [weak self] index in
                guard let self = self else { return false }
                return index < self.mockDataList.count - 1
            }
        
        let periodList = input.periodButtonTapped
            .map { [weak self] _ -> [PeriodRecordDTO] in
                guard let self = self else { return [] }
                return self.mockDataList
            }
        
        return Output(
            currentPeriodData: currentPeriodData,
            isLeftArrowEnabled: isLeftArrowEnabled,
            isRightArrowEnabled: isRightArrowEnabled,
            periodList: periodList
        )
    }
    
    func selectPeriod(at index: Int) {
        currentIndexSubject.onNext(index)
    }
    
    func getCurrentIndex() -> Int {
        return (try? currentIndexSubject.value()) ?? 0
    }
}
