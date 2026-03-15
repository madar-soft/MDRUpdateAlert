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
    private let latestVersionFirebaseKey: String
    private let minimumVersionFirebaseKey: String
    private let managerOverrideFirebaseKey: String
    
    init(
        latestVersionFirebaseKey: String = "latest_version",
        minimumVersionFirebaseKey: String = "minimum_version",
        managerOverrideFirebaseKey: String = "manager_override",
    ) {
        self.remoteConfig = RemoteConfig.remoteConfig()
        self.latestVersionFirebaseKey = latestVersionFirebaseKey
        self.minimumVersionFirebaseKey = minimumVersionFirebaseKey
        self.managerOverrideFirebaseKey = managerOverrideFirebaseKey
        
        // Optional: Configure for development
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings
    }
    
    func fetchRemoteConfig() async throws -> UpdateRemoteConfig {
        try await remoteConfig.fetchAndActivate()
        
        return UpdateRemoteConfig(
            latestVersion: remoteConfig[latestVersionFirebaseKey].stringValue,
            minimumVersion: remoteConfig[minimumVersionFirebaseKey].stringValue,
            managerOverride: remoteConfig[managerOverrideFirebaseKey].stringValue
        )
    }
}
