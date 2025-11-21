import UIKit
import RxSwift
import RxCocoa
import CoreData

// MARK: - Repository
protocol CycleHistoryProtocol {
    func fetchAllCycles() throws -> [Cycle]
}

final class CycleHistoryRepository: CycleHistoryProtocol {
    private let context: NSManagedObjectContext?
    init(context: NSManagedObjectContext?) {
        self.context = context
    }
    
    func fetchAllCycles() throws -> [Cycle] {
        guard let ctx = context else { return [] }
        let request = NSFetchRequest<PillCycleEntity>(entityName: "PillCycleEntity")
        request.sortDescriptors = [
            NSSortDescriptor(key: "createdAt", ascending: false),
            NSSortDescriptor(key: "startDate", ascending: false)
        ]
        let entities = try ctx.fetch(request)
        return entities.map { $0.toDomain() }
    }
}
