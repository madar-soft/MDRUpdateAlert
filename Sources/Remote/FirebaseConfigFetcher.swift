//
//  FirebaseConfigFetcher.swift
//  MDRUpdateAlert
//
//  Created by Belal Samy on 19/02/2026.
//

import Foundation
import FirebaseRemoteConfig

final class FirebaseConfigFetcher: UpdateRemoteFetching {
    
    private let remoteConfig: RemoteConfig
    
    init() {
        self.remoteConfig = RemoteConfig.remoteConfig()
        
        // Optional: Configure for development
        #if DEBUG
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings
        #endif
    }
    
    func fetchRemoteConfig() async throws -> UpdateRemoteConfig {
        try await remoteConfig.fetchAndActivate()
        
        return UpdateRemoteConfig(
            latestVersion: remoteConfig["latest_version"].stringValue ?? "",
            minimumVersion: remoteConfig["minimum_version"].stringValue ?? "",
            managerOverride: remoteConfig["manager_override"].stringValue ?? ""
        )
    }
}
