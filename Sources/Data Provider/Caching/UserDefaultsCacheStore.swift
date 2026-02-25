//
//  UserDefaultsCacheStore.swift
//  MDRUpdateAlert
//
//  Created by Belal Samy on 23/02/2026.
//

import Foundation

//MARK: - Protocol

public protocol UpdateCacheStoring {
    func load() -> CachedUpdateConfig?
    func save(_ config: CachedUpdateConfig)
    func clear()
}

//MARK: - Implementation

public final class UserDefaultsCacheStore: UpdateCacheStoring {
    
    // Properties
    
    private let userDefaults: UserDefaults
    private let cacheKey = "com.madarupdater.cached.config"
    
    // Init
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // Methods
    
    public func load() -> CachedUpdateConfig? {
        guard let data = userDefaults.data(forKey: cacheKey) else {
            return nil
        }
        
        return try? JSONDecoder().decode(CachedUpdateConfig.self, from: data)
    }
    
    public func save(_ config: CachedUpdateConfig) {
        guard let data = try? JSONEncoder().encode(config) else { return }
        userDefaults.set(data, forKey: cacheKey)
    }
    
    public func clear() {
        userDefaults.removeObject(forKey: cacheKey)
    }
}
