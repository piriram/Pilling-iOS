//
//  UserDefaultsManager.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/13/25.
//

import Foundation

// MARK: - UserDefaultsManagerProtocol

protocol UserDefaultsManagerProtocol {
    func savePillInfo(_ pillInfo: PillInfo)
    func savePillStartDate(_ date: Date)
    func loadPillInfo() -> PillInfo?
    func loadPillStartDate() -> Date?
    func clearPillSettings()
    func saveCurrentCycleID(_ id: UUID)
    func loadCurrentCycleID() -> UUID?
}
// MARK: - UserDefaultsKey

enum UserDefaultsKey: String {
    case pillName = "pill_name"
    case pillTakingDays = "pill_taking_days"
    case pillBreakDays = "pill_break_days"
    case pillStartDate = "pill_start_date"
    case pillInfo = "pillInfo"
    case currentCycleID = "current_cycle_id"
}

// MARK: - UserDefaultsManager

final class UserDefaultsManager: UserDefaultsManagerProtocol {
    
    // MARK: - Properties
    
    private let userDefaults: UserDefaults
    
    // MARK: - Initialization
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        migrateIfNeeded()
    }
    
    // MARK: - Migration
    
    private func migrateIfNeeded() {
        // 이미 새 방식으로 저장되어 있으면 마이그레이션 불필요
        if userDefaults.data(forKey: UserDefaultsKey.pillInfo.rawValue) != nil {
            return
        }
        
        // 기존 방식으로 저장된 데이터가 있는지 확인
        guard let name = userDefaults.string(forKey: UserDefaultsKey.pillName.rawValue),
              userDefaults.object(forKey: UserDefaultsKey.pillTakingDays.rawValue) != nil,
              userDefaults.object(forKey: UserDefaultsKey.pillBreakDays.rawValue) != nil else {
            return
        }
        
        let takingDays = userDefaults.integer(forKey: UserDefaultsKey.pillTakingDays.rawValue)
        let breakDays = userDefaults.integer(forKey: UserDefaultsKey.pillBreakDays.rawValue)
        
        let pillInfo = PillInfo(name: name, takingDays: takingDays, breakDays: breakDays)
        
        // 새 방식으로 저장
        if let encoded = try? JSONEncoder().encode(pillInfo) {
            userDefaults.set(encoded, forKey: UserDefaultsKey.pillInfo.rawValue)
            
            // 기존 키들은 삭제 (선택사항 - 남겨둬도 무방)
            userDefaults.removeObject(forKey: UserDefaultsKey.pillName.rawValue)
            userDefaults.removeObject(forKey: UserDefaultsKey.pillTakingDays.rawValue)
            userDefaults.removeObject(forKey: UserDefaultsKey.pillBreakDays.rawValue)
            
            print("✅ PillInfo 마이그레이션 완료")
        }
    }
    
    // MARK: - Save Methods
    
    func savePillInfo(_ pillInfo: PillInfo) {
        if let encoded = try? JSONEncoder().encode(pillInfo) {
            userDefaults.set(encoded, forKey: UserDefaultsKey.pillInfo.rawValue)
        }
    }
    
    func savePillStartDate(_ date: Date) {
        userDefaults.set(date, forKey: UserDefaultsKey.pillStartDate.rawValue)
    }
    
    func saveCurrentCycleID(_ id: UUID) {
        userDefaults.set(id.uuidString, forKey: UserDefaultsKey.currentCycleID.rawValue)
    }
    
    
    // MARK: - Load Methods
    
    func loadPillInfo() -> PillInfo? {
        // 새 방식으로 먼저 시도
        if let data = userDefaults.data(forKey: UserDefaultsKey.pillInfo.rawValue),
           let pillInfo = try? JSONDecoder().decode(PillInfo.self, from: data) {
            return pillInfo
        }
        
        // 혹시 마이그레이션이 안됐을 경우를 대비해 기존 방식으로도 시도
        guard let name = userDefaults.string(forKey: UserDefaultsKey.pillName.rawValue),
              userDefaults.object(forKey: UserDefaultsKey.pillTakingDays.rawValue) != nil,
              userDefaults.object(forKey: UserDefaultsKey.pillBreakDays.rawValue) != nil else {
            print("❌ PillInfo 로드 실패: 저장된 데이터가 없습니다")
            return nil
        }
        
        let takingDays = userDefaults.integer(forKey: UserDefaultsKey.pillTakingDays.rawValue)
        let breakDays = userDefaults.integer(forKey: UserDefaultsKey.pillBreakDays.rawValue)
        
        let pillInfo = PillInfo(name: name, takingDays: takingDays, breakDays: breakDays)
        
        // 기존 방식으로 불러온 경우, 새 방식으로 다시 저장
        savePillInfo(pillInfo)
        
        return pillInfo
    }
    
    func loadPillStartDate() -> Date? {
        return userDefaults.object(forKey: UserDefaultsKey.pillStartDate.rawValue) as? Date
    }
    
    func loadCurrentCycleID() -> UUID? {
        guard let uuidString = userDefaults.string(forKey: UserDefaultsKey.currentCycleID.rawValue) else {
            return nil
        }
        return UUID(uuidString: uuidString)
    }
    
    // MARK: - Clear Methods
    
    func clearPillSettings() {
        userDefaults.removeObject(forKey: UserDefaultsKey.pillInfo.rawValue)
        userDefaults.removeObject(forKey: UserDefaultsKey.pillName.rawValue)
        userDefaults.removeObject(forKey: UserDefaultsKey.pillTakingDays.rawValue)
        userDefaults.removeObject(forKey: UserDefaultsKey.pillBreakDays.rawValue)
        userDefaults.removeObject(forKey: UserDefaultsKey.pillStartDate.rawValue)
        userDefaults.removeObject(forKey: UserDefaultsKey.currentCycleID.rawValue) // ⭐️ 추가
    }
}
