//
//  CacheValidator.swift
//  MDRUpdateAlert
//
//  Created by Belal Samy on 19/02/2026.
//

import Foundation

struct CacheValidator {
    let timing: UpdateTimingConfig

    func isCacheValid(_ cache: CachedUpdateConfig, now: Date = Date()) -> Bool {
        now.timeIntervalSince(cache.savedAt) < timing.cacheExpiry
    }
}
