//
//  CacheValidator.swift
//  MDRUpdateAlert
//
//  Created by Belal Samy on 19/02/2026.
//

import Foundation

enum CacheValidationResult {
    case valid
    case expired
    case appUpdated
    case appDowngraded
}

struct CacheValidator {
    let timing: UpdateTimingConfig
     
    func validate(_ cache: CachedUpdateConfig, currentAppVersion: String, now: Date = Date()) -> CacheValidationResult {
        let previous = Version(cache.appVersion)
        let current = Version(currentAppVersion)
        
        if current > previous {
            return .appUpdated
        }
         
        if current < previous {
            return .appDowngraded
        }
         
        if now.timeIntervalSince(cache.savedAt) >= timing.cacheExpiry {
            return .expired
        }
        
        return .valid
    }
}
