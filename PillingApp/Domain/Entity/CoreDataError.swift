import Foundation

// MARK: - CoreDataError

enum CoreDataError: Error {
    case contextNotAvailable
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
    case invalidData
}
