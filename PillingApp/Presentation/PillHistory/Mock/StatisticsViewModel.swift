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

    private let fetchStatisticsDataUseCase: FetchStatisticsDataUseCaseProtocol
    private let disposeBag = DisposeBag()
    private let currentIndexSubject = BehaviorSubject<Int>(value: 0)
    private let dataListSubject = BehaviorSubject<[PeriodRecordDTO]>(value: [])

    init(fetchStatisticsDataUseCase: FetchStatisticsDataUseCaseProtocol) {
        self.fetchStatisticsDataUseCase = fetchStatisticsDataUseCase
    }
    
    func transform(input: Input) -> Output {
        // Load statistics data on viewDidLoad
        input.viewDidLoad
            .flatMapLatest { [weak self] _ -> Observable<[PeriodRecordDTO]> in
                guard let self = self else { return .just([]) }
                return self.fetchStatisticsDataUseCase.execute()
                    .catch { error in
                        print("❌ Failed to fetch statistics data: \(error)")
                        return .just([])
                    }
            }
            .bind(to: dataListSubject)
            .disposed(by: disposeBag)

        input.leftArrowTapped
            .withLatestFrom(currentIndexSubject)
            .filter { $0 > 0 }
            .map { $0 - 1 }
            .bind(to: currentIndexSubject)
            .disposed(by: disposeBag)

        input.rightArrowTapped
            .withLatestFrom(Observable.combineLatest(currentIndexSubject, dataListSubject))
            .filter { index, dataList in
                return index < dataList.count - 1
            }
            .map { index, _ in index + 1 }
            .bind(to: currentIndexSubject)
            .disposed(by: disposeBag)

        let currentPeriodData = Observable.combineLatest(currentIndexSubject, dataListSubject)
            .map { index, dataList -> PeriodRecordDTO in
                guard !dataList.isEmpty, index < dataList.count else {
                    return PeriodRecordDTO(
                        startDate: "",
                        endDate: "",
                        completionRate: 0,
                        medicineName: "",
                        records: [],
                        skippedCount: 0,
                        sideEffectStats: [],
                        isEmpty: true
                    )
                }
                return dataList[index]
            }

        let isLeftArrowEnabled = currentIndexSubject
            .map { $0 > 0 }

        let isRightArrowEnabled = Observable.combineLatest(currentIndexSubject, dataListSubject)
            .map { index, dataList in
                return index < dataList.count - 1
            }

        let periodList = input.periodButtonTapped
            .withLatestFrom(dataListSubject)

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
