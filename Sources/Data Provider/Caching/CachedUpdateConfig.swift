//
//  CachedUpdateConfig.swift
//  MDRUpdateAlert
//
//  Created by Belal Samy on 19/02/2026.
//

import Foundation

public struct CachedUpdateConfig: Codable {
    public let appVersion: String
    public let config: UpdateRemoteConfig
    public let savedAt: Date
    
    public init(appVersion: String, config: UpdateRemoteConfig, savedAt: Date = Date()) {
        self.appVersion = appVersion
        self.config = config
        self.savedAt = savedAt
    }
}
