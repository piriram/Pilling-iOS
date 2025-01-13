import Foundation
import RxSwift
import RxCocoa

final class DatePickerBottomSheetViewModel {
    
    // MARK: - Input/Output
    
    struct Input {
        let dateChanged: AnyObserver<Date>
        let dismissRequested: AnyObserver<Void>
    }
    
    struct Output {
        let selectedDate: Signal<Date>
        let shouldDismiss: Signal<Void>
    }
    
    // MARK: - Properties
    
    let input: Input
    let output: Output
    
    private let dateChangedSubject = PublishSubject<Date>()
    private let dismissRequestedSubject = PublishSubject<Void>()
    
    private let disposeBag = DisposeBag()
    
    // MARK: - Initialization
    
    init(initialDate: Date = Date(), dateRange: DatePickerConfiguration.DateRange) {
        self.input = Input(
            dateChanged: dateChangedSubject.asObserver(),
            dismissRequested: dismissRequestedSubject.asObserver()
        )
        
        let selectedDate = dateChangedSubject
            .asSignal(onErrorSignalWith: .empty())
        
        let shouldDismiss = dismissRequestedSubject
            .asSignal(onErrorSignalWith: .empty())
        
        self.output = Output(
            selectedDate: selectedDate,
            shouldDismiss: shouldDismiss
        )
    }
}
