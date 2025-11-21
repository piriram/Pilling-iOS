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
        let dataChanged: Observable<Void>  // 데이터 변경 알림
    }

    struct Output {
        let currentPeriodData: Observable<PeriodRecordDTO>
        let isLeftArrowEnabled: Observable<Bool>
        let isRightArrowEnabled: Observable<Bool>
        let periodList: Observable<[PeriodRecordDTO]>
        let pageControlState: Observable<(currentIndex: Int, totalCount: Int)>  // 페이지 컨트롤용
    }

    private let fetchStatisticsDataUseCase: FetchStatisticsDataUseCaseProtocol
    private let disposeBag = DisposeBag()
    private let currentIndexSubject = BehaviorSubject<Int>(value: 0)
    private let dataListSubject = BehaviorSubject<[PeriodRecordDTO]>(value: [])

    init(fetchStatisticsDataUseCase: FetchStatisticsDataUseCaseProtocol) {
        self.fetchStatisticsDataUseCase = fetchStatisticsDataUseCase
    }
    
    func transform(input: Input) -> Output {
        // Load statistics data on viewDidLoad or when data changes
        Observable.merge(
            input.viewDidLoad,
            input.dataChanged
        )
        .do(onNext: { _ in
            print("🔍 [StatisticsViewModel] 데이터 로드 트리거")
        })
        .flatMapLatest { [weak self] _ -> Observable<[PeriodRecordDTO]> in
            guard let self = self else { return .just([]) }
            return self.fetchStatisticsDataUseCase.execute()
                .do(onNext: { periodList in
                    // 🔍 [디버깅] UseCase에서 받은 데이터
                    print("🔍 [StatisticsViewModel] UseCase에서 받은 데이터")
                    print("   📊 periodList.count: \(periodList.count)")
                    for (index, period) in periodList.enumerated() {
                        print("   📅 [\(index)] startDate: \(period.startDate), endDate: \(period.endDate)")
                        print("      🏷️ sideEffectStats.count: \(period.sideEffectStats.count)")
                        for stat in period.sideEffectStats {
                            print("         - \(stat.tagName): \(stat.count)회")
                        }
                    }
                })
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
                    print("🔍 [StatisticsViewModel] currentPeriodData - 빈 데이터 반환")
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
                let period = dataList[index]
                // 🔍 [디버깅] 현재 표시할 period 데이터
                print("🔍 [StatisticsViewModel] currentPeriodData 생성")
                print("   📊 index: \(index), dataList.count: \(dataList.count)")
                print("   📅 period.startDate: \(period.startDate), endDate: \(period.endDate)")
                print("   🏷️ period.sideEffectStats.count: \(period.sideEffectStats.count)")
                for stat in period.sideEffectStats {
                    print("      - \(stat.tagName): \(stat.count)회")
                }
                return period
            }

        let isLeftArrowEnabled = currentIndexSubject
            .map { $0 > 0 }

        let isRightArrowEnabled = Observable.combineLatest(currentIndexSubject, dataListSubject)
            .map { index, dataList in
                return index < dataList.count - 1
            }

        let periodList = input.periodButtonTapped
            .withLatestFrom(dataListSubject)

        // 페이지 컨트롤 상태 (현재 인덱스, 전체 개수)
        let pageControlState = Observable.combineLatest(currentIndexSubject, dataListSubject)
            .map { (currentIndex: $0, totalCount: $1.count) }
            .do(onNext: { state in
                print("🔍 [StatisticsViewModel] pageControlState 업데이트")
                print("   📄 currentIndex: \(state.currentIndex), totalCount: \(state.totalCount)")
            })

        return Output(
            currentPeriodData: currentPeriodData,
            isLeftArrowEnabled: isLeftArrowEnabled,
            isRightArrowEnabled: isRightArrowEnabled,
            periodList: periodList,
            pageControlState: pageControlState
        )
    }

    func selectPeriod(at index: Int) {
        currentIndexSubject.onNext(index)
    }

    func getCurrentIndex() -> Int {
        return (try? currentIndexSubject.value()) ?? 0
    }
}
