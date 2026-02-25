//
//  UpdateReminderEngine.swift
//  MDRUpdateAlert
//
//  Created by Belal Samy on 19/02/2026.
//

import Foundation

//MARK: - Protocol

public protocol UpdateReminderEngine: AnyObject {
    func shouldShowAlert(for state: UpdateState) -> Bool
    func markAlertShown(for state: UpdateState)
    func resetSessionState()
}

//MARK: - Implementation

import UIKit

final class DefaultUpdateReminderEngine: UpdateReminderEngine {
    private let store: UpdateReminderStoring
    private let timing: UpdateTimingConfig
    private let now: () -> Date
    
    // Track if urgent alert was shown in current session
    private var urgentShownInSession: Bool = false
    private var lastState: UpdateState = .none  // Track last state

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
        lastState = state  // Store the state for markAlertShown
        
        switch state {
        case .forced:
            return true // ALWAYS show, no questions asked
            
        case .urgent:
            if urgentShownInSession { return false }
            return true // show only once per session
            
        case .normal:
            guard let lastShown = store.lastShownDate() else { return true } // First time
             
            let timeSinceLastShown = now().timeIntervalSince(lastShown)
            return timeSinceLastShown >= timing.normalReminderInterval // show every "x" days (default 5 days)
            
        case .none:
            return false // Never show
        }
    }
    
    func markAlertShown(for state: UpdateState) {
        let currentDate = now()
        store.saveShownDate(currentDate)
        
        // If it was an urgent alert, mark it as shown in this session
        if state == .urgent {
            urgentShownInSession = true
        }
    }
    
    func resetSessionState() {
        // Called on app cold launch to reset the session flag
        urgentShownInSession = false
    }
}
