//
//  CachedUpdateConfig.swift
//  MDRUpdateAlert
//
//  Created by Belal Samy on 19/02/2026.
//

import Foundation

public struct CachedUpdateConfig: Codable {
    public let config: UpdateRemoteConfig
    public let savedAt: Date

    public init(config: UpdateRemoteConfig, savedAt: Date = Date()) {
        self.config = config
        self.savedAt = savedAt
    }
}
