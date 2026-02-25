//
//  UpdateConfigProvider.swift
//  MDRUpdateAlert
//
//  Created by Belal Samy on 19/02/2026.
//

import Foundation

//MARK: - Protocol

public protocol UpdateRemoteFetching {
    func fetchRemoteConfig() async throws -> UpdateRemoteConfig
}

//MARK: - Implementation

public actor UpdateConfigProvider {
    
    //MARK: - Properties
    
    private let currentVersion = Bundle.main.versionString
    private(set) var isAppUpdated: Bool = false
     
    private let cacheStore: UpdateCacheStoring
    private let remoteFetcher: UpdateRemoteFetching
    private let validator: CacheValidator

    //MARK: - Init
    
    public init(
        cacheStore: UpdateCacheStoring,
        remoteFetcher: UpdateRemoteFetching,
        timing: UpdateTimingConfig = .init()
    ) {
        self.cacheStore = cacheStore
        self.remoteFetcher = remoteFetcher
        self.validator = CacheValidator(timing: timing)
    }

    //MARK: - Methods
    
    public func getConfig(offlineMode: Bool) async -> UpdateRemoteConfig? {
        isAppUpdated = false
        
        /// load cache if exists ====================================================
        
        if let cached = cacheStore.load() {
            let cache = validator.validate(cached, currentAppVersion: currentVersion)
            
            switch cache {
            // Cache is Valid
            case .valid:
                return cached.config
            
            // App Updated
            case .appUpdated:
                isAppUpdated = true
                cacheStore.clear()
                return nil
                
            // Cache Expired
            case .expired, .appDowngraded:
                break
            }
            
            // cache expired but offline
            if offlineMode {
                return cached.config
            }
        }

        /// If offline and no cache ===================================================
        
        if offlineMode {
            return nil
        }

        /// try fetching from remote =================================================
        
        do {
            let remote = try await remoteFetcher.fetchRemoteConfig()
            // => Save cache
            cacheStore.save(CachedUpdateConfig(appVersion: currentVersion, config: remote))
            return remote
            
        } catch {
            // If fetch fails => fallback to cache if exists
            return cacheStore.load()?.config
        }
    }
}
