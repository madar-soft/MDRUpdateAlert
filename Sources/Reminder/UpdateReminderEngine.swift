//
//  UpdateReminderEngine.swift
//  MDRUpdateAlert
//
//  Created by Belal Samy on 19/02/2026.
//

import Foundation

//MARK: - Protocol

public protocol UpdateReminderEngineProtocol: AnyObject {
    func shouldShowAlert(for state: UpdateState) -> Bool
    func markAlertShown(for state: UpdateState)
}

//MARK: - Implementation

final class UpdateReminderEngine: UpdateReminderEngineProtocol {
    private let store: UpdateReminderStoring
    private let timing: UpdateTimingConfig
    private let now: () -> Date
    
    init(
        store: UpdateReminderStoring,
        timing: UpdateTimingConfig,
        now: @escaping () -> Date = Date.init
    ) {
        self.store = store
        self.timing = timing
        self.now = now
    }
    
    func shouldShowAlert(for state: UpdateState) -> Bool {
        switch state {
        case .forced:
            return true // ALWAYS show, no questions asked
        
        case .urgent:
            return true // SHOW IT every new session for urgency
            
        case .normal:
            guard let lastShown = store.lastShownDate() else { return true } // First time
             
            let timeSinceLastShown = now().timeIntervalSince(lastShown)
            return timeSinceLastShown >= timing.normalReminderInterval // show every "x" days (default 5 days)
            
        case .none:
            return false // Never show
        }
    }
     
    func markAlertShown(for state: UpdateState) {
        switch state {
        case .normal:
            store.saveShownDate(now()) // store it to show update alert every "x" days
        
        case .urgent:
            break // once per sesssion, handled by UpdateManager.hasShownAlertThisSession
        
        case .forced, .none:
            break // No tracking needed
        }
    }
}
