//
//  UpdateManager.swift
//  MDRUpdateAlert
//
//  Created by Belal Samy on 19/02/2026.
//

//MARK: - Protocol

public protocol UpdateManaging {
    func checkForUpdate(currentVersion: String, offlineMode: Bool, updateUrl: String, allowSkip: Bool) async -> UpdateState
    func resetSession()
}

//MARK: - Implementation
 
public final class UpdateManager: UpdateManaging {
    private let provider: UpdateConfigProvider
    private let decisionEngine: UpdateDecisionEngine
    private let reminderEngine: UpdateReminderEngine?
    private let presenter: UpdateAlertPresenting?
    
    private var hasShownAlertThisSession = false
    
    init(
        provider: UpdateConfigProvider,
        decisionEngine: UpdateDecisionEngine = .init(),
        reminderEngine: UpdateReminderEngine? = nil,
        presenter: UpdateAlertPresenting? = nil
    ) {
        self.provider = provider
        self.decisionEngine = decisionEngine
        self.reminderEngine = reminderEngine
        self.presenter = presenter
    }
    
    public func checkForUpdate(currentVersion: String, offlineMode: Bool, updateUrl: String,
                               allowSkip: Bool) async -> UpdateState {
        
        // get remote (or cached) config
        guard let config = await provider.getConfig(offlineMode: offlineMode) else {
            // App Updated Successfully 🎉
            if await provider.isAppUpdated && !allowSkip {
                await presenter?.presentAppUpdatedAlert()
            }
            
            return .none
        }
        
        // evaluate decision
        let state = decisionEngine.evaluate(
            config: config,
            currentVersion: currentVersion
        )
        
        guard state != .none else {
            return .none
        }
         
        // Allow to skip, if state not forced
        if allowSkip && state != .forced {
            return .none
        }
        
        // Allow only once per session, if state not forced
        if hasShownAlertThisSession && state != .forced {
            return state
        }
        
        // Check if we should show based on reminder timing
        if let reminderEngine = reminderEngine, reminderEngine.shouldShowAlert(for: state) {
            await presenter?.presentAlert(
                for: state, updateURL: updateUrl,
                onPresented: { [weak self] in
                    self?.hasShownAlertThisSession = true // <<<
                },
                onUpdate: { [weak self] in
                    self?.reminderEngine?.markAlertShown(for: state)
                },
                onLater: { [weak self] in
                    self?.reminderEngine?.markAlertShown(for: state)
                }
            )
            
            return state
            
        } else {
            // no alerts
            return .none
        }
    }
    
    public func resetSession() {
        hasShownAlertThisSession = false
    }
}



