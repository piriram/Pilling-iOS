//
//  CoreDataError.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/21/25.
//

import Foundation

// MARK: - CoreDataError

enum CoreDataError: Error {
    case contextNotAvailable
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
    case invalidData
}
