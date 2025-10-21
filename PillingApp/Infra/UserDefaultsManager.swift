//
//  UserDefaultsManager.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/13/25.
//

import Foundation

// MARK: - UserDefaultsKey

enum UserDefaultsKey: String {
    case pillName = "pill_name"
    case pillTakingDays = "pill_taking_days"
    case pillBreakDays = "pill_break_days"
    case pillStartDate = "pill_start_date"
}

// MARK: - UserDefaultsManagerProtocol

protocol UserDefaultsManagerProtocol {
    func savePillInfo(_ pillInfo: PillInfo)
    func savePillStartDate(_ date: Date)
    func loadPillInfo() -> PillInfo?
    func loadPillStartDate() -> Date?
    func clearPillSettings()
}

// MARK: - UserDefaultsManager

final class UserDefaultsManager: UserDefaultsManagerProtocol {
    
    // MARK: - Properties
    
    private let userDefaults: UserDefaults
    
    // MARK: - Initialization
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // MARK: - Save Methods
    
    func savePillInfo(_ pillInfo: PillInfo) {
        userDefaults.set(pillInfo.name, forKey: UserDefaultsKey.pillName.rawValue)
        userDefaults.set(pillInfo.takingDays, forKey: UserDefaultsKey.pillTakingDays.rawValue)
        userDefaults.set(pillInfo.breakDays, forKey: UserDefaultsKey.pillBreakDays.rawValue)
    }
    
    func savePillStartDate(_ date: Date) {
        userDefaults.set(date, forKey: UserDefaultsKey.pillStartDate.rawValue)
    }
    
    // MARK: - Load Methods
    
    func loadPillInfo() -> PillInfo? {
        guard let name = userDefaults.string(forKey: UserDefaultsKey.pillName.rawValue),
              userDefaults.object(forKey: UserDefaultsKey.pillTakingDays.rawValue) != nil,
              userDefaults.object(forKey: UserDefaultsKey.pillBreakDays.rawValue) != nil else {
            return nil
        }
        
        let takingDays = userDefaults.integer(forKey: UserDefaultsKey.pillTakingDays.rawValue)
        let breakDays = userDefaults.integer(forKey: UserDefaultsKey.pillBreakDays.rawValue)
        
        return PillInfo(name: name, takingDays: takingDays, breakDays: breakDays)
    }
    
    func loadPillStartDate() -> Date? {
        return userDefaults.object(forKey: UserDefaultsKey.pillStartDate.rawValue) as? Date
    }
    
    // MARK: - Clear Methods
    
    func clearPillSettings() {
        userDefaults.removeObject(forKey: UserDefaultsKey.pillName.rawValue)
        userDefaults.removeObject(forKey: UserDefaultsKey.pillTakingDays.rawValue)
        userDefaults.removeObject(forKey: UserDefaultsKey.pillBreakDays.rawValue)
        userDefaults.removeObject(forKey: UserDefaultsKey.pillStartDate.rawValue)
    }
}
