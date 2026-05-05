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
         
        // Minimum version check
        // Override is irrelevant, version not supported
        if current < minimum {
            return config.managerOverride == "4" ? .none : .forced
        }
        
        // Manager override
        switch config.managerOverride {
        case "4": return .none
        case "3": return .forced
        case "2": return .urgent
        case "1": return .normal
        default: break
        }
        
        // Need update check
        if current < latest {
            return .normal
        }

        // No update needed
        return .none
    }
}
