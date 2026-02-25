//
//  UpdateManager.swift
//  MDRUpdateAlert
//
//  Created by Belal Samy on 19/02/2026.
//

//MARK: - Protocol

public protocol UpdateManaging {
    func checkForUpdate(currentVersion: String, offlineMode: Bool, updateUrl: String, allowSkip: Bool) async -> UpdateState
    func resetSession() async
}

//MARK: - Implementation
 
public final class UpdateManager: UpdateManaging {
    private let provider: UpdateConfigProvider
    private let decisionEngine: UpdateDecisionEngine
    private let reminderEngine: UpdateReminderEngine?
    private let presenter: UpdateAlertPresenting?
    
    public init(
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
            if await provider.isAppUpdated {
                // App Updated Successfully 🎉
                await presenter?.presentAppUpdatedAlert()
            }
            
            return .none
        }
        
        print("=========== MDRUpdateAlert ===================")
        print("---------- Current App Data -----------------")
        print(" * currentVersion => \(currentVersion)")
        print(" * Offline Mode => \(offlineMode)")
        print(" * updateUrl => \(updateUrl)")
        print("---------- Remote or Cached Config ----------")
        print(" - Latest version: \(config.latestVersion)")
        print(" - Minimum version: \(config.minimumVersion)")
        print(" - Manager Override: \(config.managerOverride)")

        // evaluate decision
        let state = decisionEngine.evaluate(
            config: config,
            currentVersion: currentVersion
        )
         
        print("---------- Update Decision ----------")
        print(" - Update Status: \(state)")
        print("==============================================")

        guard state != .none else { return .none }
        
        // Allow to skip, if state not forced
        if allowSkip && state != .forced {
            return .none
        }
        
        // Check if we should show based on reminder timing
        if let reminderEngine = reminderEngine, reminderEngine.shouldShowAlert(for: state) {
            // present alert
            await presenter?.presentAlert(
                for: state,
                updateURL: updateUrl,
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
    
    public func resetSession() async {
        await provider.resetSession()
        reminderEngine?.resetSessionState()
    }
}
