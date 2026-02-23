//
//  UserDefaultsReminderStore.swift
//  MDRUpdateAlert
//
//  Created by Belal Samy on 23/02/2026.
//

import Foundation

//MARK: - Protocol

public protocol UpdateReminderStoring {
    func lastShownDate() -> Date?
    func saveShownDate(_ date: Date)
}

//MARK: - Implementation

public final class UserDefaultsReminderStore: UpdateReminderStoring {
    
    // Properties
    
    private let userDefaults: UserDefaults
    private let lastShownKey = "com.madarupdater.lastShownDate"
    
    // Init
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // Methods
    
    public func lastShownDate() -> Date? {
        return userDefaults.object(forKey: lastShownKey) as? Date
    }
    
    public func saveShownDate(_ date: Date) {
        userDefaults.set(date, forKey: lastShownKey)
    }
}
