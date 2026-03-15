//
//  UpdateDecisionEngine.swift
//  MDRUpdateAlert
//
//  Created by Belal Samy on 19/02/2026.
//

import Foundation

public struct UpdateDecisionEngine {
    
    public init() {}

    public func evaluate(config: UpdateRemoteConfig, currentVersion: String) -> UpdateState {
        let current = Version(currentVersion)
        let latest = Version(config.latestVersion)
        let minimum = Version(config.minimumVersion)
        
        // No update needed — user is already up to date
        // Override is irrelevant if there's nothing to update
        if current >= latest {
            return .none
        }
        
        // Manager override (highest priority)
        switch config.managerOverride {
        case "3": return .forced
        case "2": return .urgent
        case "1": return .normal
        default: break
        }

        // Minimum version check
        if current < minimum {
            return .forced
        }

        // Latest version check
        if current < latest {
            return .normal
        }

        // No update needed
        return .none
    }
}
