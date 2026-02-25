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
    
    // fetch only once per session
    private var didFetchThisSession = false
    
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
        
        // ===================================================
        // STEP 1: Try cache first (always)
        // ===================================================
        
        if let cached = cacheStore.load() {
            let cache = validator.validate(cached, currentAppVersion: currentVersion)
             
            switch cache {
            case .valid:
                // Cache is valid - use it
                return cached.config
                
            case .appUpdated:
                // App already updated - clear cache
                isAppUpdated = true
                cacheStore.clear()
                return nil
                
            case .expired, .appDowngraded:
                // Cache expired - we'll try to fetch if online
                break
            }
            
            // Cache expired but offline - return expired cache as fallback
            if offlineMode {
                return cached.config
            }
        }
        
        // ===================================================
        // STEP 2: No valid cache, check if we're offline
        // ===================================================
        
        if offlineMode {
            return nil
        }
         
        // ===================================================
        // STEP 3: Try to fetch from remote (ONCE per session)
        // ===================================================
        
        // If we already fetched this session, don't fetch again
        // just used cached config, in this case
        guard !didFetchThisSession else {
            return cacheStore.load()?.config
        }
        
        do {
            let remote = try await remoteFetcher.fetchRemoteConfig()
            // => Save to cache
            cacheStore.save(CachedUpdateConfig(appVersion: currentVersion, config: remote))
            didFetchThisSession = true // Mark that we've fetched this session
            return remote
            
        } catch {
            // Fetch failed => fallback to cache
            return cacheStore.load()?.config
        }
    }
    
    // Call this when app starts a new session (cold launch)
    public func resetSession() {
        didFetchThisSession = false
    }
}
