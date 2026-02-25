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
        
        if !didFetchThisSession {
            do {
                let remote = try await remoteFetcher.fetchRemoteConfig()
                
                // Check if app is already up to date
                let comparison = currentVersion.compare(remote.latestVersion, options: .numeric)
                isAppUpdated = (comparison != .orderedAscending)  // Current >= remote
                 
                // Save to cache
                cacheStore.save(CachedUpdateConfig(
                    appVersion: currentVersion,
                    config: remote,
                    savedAt: Date()
                ))
                
                didFetchThisSession = true
                return remote
                
            } catch {
                print("Failed to fetch remote config: \(error)")
                // Fetch failed - fall through to cache check
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
    
    private func isVersion(_ version1: String, newerThan version2: String) -> Bool {
        return version1.compare(version2, options: .numeric) == .orderedDescending
    }
    
    // Call this when app starts a new session (cold launch)
    public func resetSession() {
        didFetchThisSession = false
    }
}
