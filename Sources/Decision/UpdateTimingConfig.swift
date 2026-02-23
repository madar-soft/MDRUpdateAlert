//
//  UpdateTimingConfig.swift
//  MDRUpdateAlert
//
//  Created by Belal Samy on 19/02/2026.
//

import Foundation

public struct UpdateTimingConfig {
    public let cacheExpiry: TimeInterval
    public let normalReminderInterval: TimeInterval
    
    public init(
        cacheExpiry: TimeInterval = 24 * 60 * 60,            // 24h
        normalReminderInterval: TimeInterval = 72 * 60 * 60, // 72h
    ) {
        self.cacheExpiry = cacheExpiry
        self.normalReminderInterval = normalReminderInterval
    }
}
