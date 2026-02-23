//
//  UpdateManager.swift
//  MDRUpdateAlert
//
//  Created by Belal Samy on 19/02/2026.
//

//MARK: - Protocol

public protocol UpdateManaging {
    func checkForUpdate(currentVersion: String, offlineMode: Bool, updateUrl: String) async -> UpdateState
    func resetSessionState()
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
        
        reminderEngine?.resetSessionState()
    }
    
    public func resetSessionState() {
        reminderEngine?.resetSessionState()
    }
    
    public func checkForUpdate(currentVersion: String, offlineMode: Bool, updateUrl: String) async -> UpdateState {
        print("🔍 Checking for update - Current version: \(currentVersion), Offline mode: \(offlineMode), updateURL: \(updateUrl)")
        
        // get remote (or cached) config
        guard let config = await provider.getConfig(offlineMode: offlineMode) else {
            print("❌ Failed to get config from provider (offlineMode: \(offlineMode))")
            return .none
        }
        
        print("✅ Got config from provider:")
        print("   - Latest version: \(config.latestVersion)")
        print("   - Minimum version: \(config.minimumVersion)")
        print("   - Manager Override: \(config.managerOverride)")
        
        // evaluate decision
        let state = decisionEngine.evaluate(
            config: config,
            currentVersion: currentVersion
        )
        
        print("📊 Decision engine evaluation result: \(state)")
        print("   - Current version: \(currentVersion)")
        print("   - Latest version: \(config.latestVersion)")
        
        // Version comparison details
        let currentComponents = currentVersion.split(separator: ".").map(String.init)
        let latestComponents = config.latestVersion.split(separator: ".").map(String.init)
        print("   - Version components comparison: \(currentComponents) vs \(latestComponents)")
        
        guard state != .none else {
            print("⏭️ State is .none - no update needed or decision engine returned none")
            return .none
        }
        
        // Check if we should show based on reminder timing
        if let reminderEngine = reminderEngine, reminderEngine.shouldShowAlert(for: state) {
            print("✅ Reminder engine says: should show alert for state: \(state)")
            
            // present alert
            await presenter?.presentAlert(
                for: state,
                updateURL: updateUrl,
                onLater: { [weak self] in
                    print("⏰ User tapped 'Later' - marking alert as shown")
                    self?.reminderEngine?.markAlertShown()
                }
            )
            
            print("✅ Alert presented for state: \(state)")
            return state
            
        } else {
            if reminderEngine == nil {
                print("⚠️ reminderEngine is nil")
            } else {
                print("⏭️ Reminder engine says: should NOT show alert for state: \(state)")
            }
            return .none
        }
    }
     
//    public func checkForUpdate(currentVersion: String, offlineMode: Bool, updateUrl: String) async -> UpdateState {
//        // get remote (or cached) config
//        guard let config = await provider.getConfig(offlineMode: offlineMode) else {
//            return .none
//        }
//
//        // evaluate decision
//        let state = decisionEngine.evaluate(
//            config: config,
//            currentVersion: currentVersion
//        )
//
//        guard state != .none else { return .none }
//        
//        // Check if we should show based on reminder timing
//        if let reminderEngine = reminderEngine, reminderEngine.shouldShowAlert(for: state) {
//            // present alert
//            await presenter?.presentAlert(
//                for: state,
//                updateURL: updateUrl,
//                onLater: { [weak self] in
//                    self?.reminderEngine?.markAlertShown()
//                }
//            )
//            
//            return state
//            
//        } else {
//            // no alerts
//            return .none
//        }
//    }
}
