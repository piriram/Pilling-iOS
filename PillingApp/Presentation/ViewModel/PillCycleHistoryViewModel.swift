import UIKit
import RxSwift
import RxCocoa
import CoreData

// MARK: - ViewModel
final class CycleHistoryViewModel {
    let items = BehaviorRelay<[Cycle]>(value: [])
    private let repository: CycleHistoryRepository
    
    init(context: NSManagedObjectContext?) {
        self.repository = CycleHistoryRepository(context: context)
    }
    
    func loadData() {
        do {
            var cycles = try repository.fetchAllCycles()
            cycles.sort { lhs, rhs in
                if lhs.createdAt != rhs.createdAt { return lhs.createdAt > rhs.createdAt }
                return lhs.startDate > rhs.startDate
            }
            items.accept(cycles)
        } catch {
            // print("Fetch cycles failed: \(error)")
        }
    }
}
