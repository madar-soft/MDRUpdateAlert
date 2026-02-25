//
//  CacheValidator.swift
//  MDRUpdateAlert
//
//  Created by Belal Samy on 19/02/2026.
//

import Foundation

struct CacheValidator {
    let timing: UpdateTimingConfig
     
    func isValid(_ cache: CachedUpdateConfig) -> Bool {
        return Date().timeIntervalSince(cache.savedAt) < timing.cacheExpiry
    }
}
