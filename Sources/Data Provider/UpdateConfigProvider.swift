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
    private let cacheValidator: CacheValidator
    
    // fetch only once per session
    private var didFetchThisSession = false
    private var isFetching = false

    //MARK: - Init
    
    public init(
        cacheStore: UpdateCacheStoring,
        remoteFetcher: UpdateRemoteFetching,
        timing: UpdateTimingConfig = .init()
    ) {
        self.cacheStore = cacheStore
        self.remoteFetcher = remoteFetcher
        self.cacheValidator = CacheValidator(timing: timing)
    }
    
    //MARK: - Methods
    
    public func getConfig(offlineMode: Bool) async -> UpdateRemoteConfig? {
        isAppUpdated = false
        
        // ===================================================
        // STEP 1: If offline, check if we have valid cache
        // ===================================================
        
        if offlineMode {
            guard let cached = cacheStore.load(), cacheValidator.isValid(cached) else {
                return nil  // No valid cache when offline
            }
            
            return cached.config
        }
        
        // ===================================================
        // STEP 2: Try to fetch from remote (ONCE per session)
        // ===================================================
        
        // Wait if fetch is in progress — don't race with stale cache
        while isFetching {
            try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1s
        }
        
        if !didFetchThisSession {
            isFetching = true
            didFetchThisSession = true
            
            // Snapshot the OLD cached version BEFORE fetching/saving anything
            let previouslyCachedVersion = cacheStore.load()?.appVersion
            
            do {
                let remote = try await remoteFetcher.fetchRemoteConfig()
                isFetching = false

                print("🔥 Firebase fetched — latest: \(remote.latestVersion), min: \(remote.minimumVersion), override: \(remote.managerOverride)")

                // Check if app is already up to date
                if !remote.latestVersion.isEmpty {
                    let appStore = Version(remote.latestVersion)
                    let current = Version(currentVersion)
                    
                    if current >= appStore {
                        if let oldVersion = previouslyCachedVersion {
                            let cachedAppVersion = Version(oldVersion)
                            if current > cachedAppVersion {
                                // Mark updated BEFORE saving new cache
                                isAppUpdated = true
                                cacheStore.clear()
                                return nil
                            }
                        }
                    }
                }
                
                // Save to cache only after the update check
                cacheStore.save(CachedUpdateConfig(
                    appVersion: currentVersion,
                    config: remote,
                    savedAt: Date()
                ))
                
                return remote
                
            } catch {
                print("🔥 Firebase Failed to fetch update remote config: \(error)")
                // Fetch failed - fall through to cache check
                isFetching = false
                didFetchThisSession = false
            }
        }
        
        // ===================================================
        // STEP 3: Return cache if valid
        // ===================================================
        
        guard let cached = cacheStore.load(), cacheValidator.isValid(cached) else {
            return nil  // No valid cache
        }
        
        return cached.config
    }
    
    // MARK: - Helpers
    
    public func clearCache() {
        self.cacheStore.clear()
    }
}
