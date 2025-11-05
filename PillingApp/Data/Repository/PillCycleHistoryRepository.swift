import UIKit
import RxSwift
import RxCocoa
import CoreData

// MARK: - Repository
protocol CycleHistoryProtocol {
    func fetchAllCycles() throws -> [PillCycle]
}

final class PillCycleHistoryRepository: CycleHistoryProtocol {
    private let context: NSManagedObjectContext?
    init(context: NSManagedObjectContext?) { self.context = context }
    
    func fetchAllCycles() throws -> [PillCycle] {
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
