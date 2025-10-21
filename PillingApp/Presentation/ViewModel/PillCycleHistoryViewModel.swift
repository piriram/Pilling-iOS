//
//  PillCycleHistoryViewModel.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/16/25.
//

import UIKit
import RxSwift
import RxCocoa
import CoreData

// MARK: - ViewModel
final class PillCycleHistoryViewModel {
    let items = BehaviorRelay<[PillCycle]>(value: [])
    private let repository: PillCycleHistoryRepository
    
    init(context: NSManagedObjectContext?) {
        self.repository = CoreDataPillCycleHistoryRepository(context: context)
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
