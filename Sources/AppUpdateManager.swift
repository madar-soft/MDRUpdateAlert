//
//  AppUpdateManager.swift
//  MDRUpdateAlert
//
//  Created by Belal Samy on 19/02/2026.
//

import Foundation
import UIKit

public class AppUpdateManager {
    
    // MARK: - Singleton
    
    public static let shared = AppUpdateManager()
    private init() {}
    
    // MARK: - Properties
    
    private var updateManager: UpdateManaging?
    private var config: Config?
    
    public var isArabic: Bool = true
    public var protectedScreens: Set<String> = []

    // MARK: - Public Config
     
    public struct Config {
        
        // Must Have ================================
        
        public let appStoreID: String
        
        // Optional =================================
        
        // Timing
        public let cacheExpiry: TimeInterval
        public let normalReminderInterval: TimeInterval
        
        // Firebase Keys
        public let latestVersionFirebaseKey: String
        public let minimumVersionFirebaseKey: String
        public let managerOverrideFirebaseKey: String
        
        // Alert Strings
        public let normalUpdateTitle: String?
        public let normalUpdateMessage: String?

        public let urgentUpdateTitle: String?
        public let urgentUpdateMessage: String?
        
        public let forcedUpdateTitle: String?
        public let forcedUpdateMessage: String?
        
        public let laterButtonTitle: String?
        public let updateButtonTitle: String?

        public let updatedSuccessfullyTitle: String?
        public let updatedSuccessfullyMessage: String?
        public let successButtonTitle: String?
        
        public init(
            appStoreID: String,
            cacheExpiry: TimeInterval = 24 * 60 * 60,             // 1 day
            normalReminderInterval: TimeInterval = 120 * 60 * 60, // 5 days
            
            latestVersionFirebaseKey: String = "latest_version",
            minimumVersionFirebaseKey: String = "minimum_version",
            managerOverrideFirebaseKey: String = "manager_override",
            
            normalUpdateTitle: String? = nil,
            normalUpdateMessage: String? = nil,
            
            urgentUpdateTitle: String? = nil,
            urgentUpdateMessage: String? = nil,
            
            forcedUpdateTitle: String? = nil,
            forcedUpdateMessage: String? = nil,
            
            laterButtonTitle: String? = nil,
            updateButtonTitle: String? = nil,
            
            updatedSuccessfullyTitle: String? = nil,
            updatedSuccessfullyMessage: String? = nil,
            successButtonTitle: String? = nil
        ) {
            self.appStoreID = appStoreID
            self.cacheExpiry = cacheExpiry
            self.normalReminderInterval = normalReminderInterval
            
            self.latestVersionFirebaseKey = latestVersionFirebaseKey
            self.minimumVersionFirebaseKey = minimumVersionFirebaseKey
            self.managerOverrideFirebaseKey = managerOverrideFirebaseKey
            
            // Normal
            self.normalUpdateTitle = normalUpdateTitle
            self.normalUpdateMessage = normalUpdateMessage
            // Urgent
            self.urgentUpdateTitle = urgentUpdateTitle
            self.urgentUpdateMessage = urgentUpdateMessage
            // Forced
            self.forcedUpdateTitle = forcedUpdateTitle
            self.forcedUpdateMessage = forcedUpdateMessage
            // Buttons
            self.laterButtonTitle = laterButtonTitle
            self.updateButtonTitle = updateButtonTitle
            // Success
            self.updatedSuccessfullyTitle = updatedSuccessfullyTitle
            self.updatedSuccessfullyMessage = updatedSuccessfullyMessage
            self.successButtonTitle = successButtonTitle
        }
        
        var appStoreURL: String {
            "https://apps.apple.com/app/id\(appStoreID)"
        }
    }
    
    // MARK: - Setup
    
    @MainActor @discardableResult
    public func setup(with config: Config) -> Self {
        self.config = config
        
        guard !config.appStoreID.isEmpty else {
            fatalError("MDRUpdateAlert: appStoreID is required")
        }
        
        let timing = UpdateTimingConfig(
            cacheExpiry: config.cacheExpiry,
            normalReminderInterval: config.normalReminderInterval
        )
         
        // Create provider with Firebase fetcher
        let provider = UpdateConfigProvider(
            cacheStore: UserDefaultsCacheStore(),
            remoteFetcher: FirebaseConfigFetcher(
                latestVersionFirebaseKey: config.latestVersionFirebaseKey,
                minimumVersionFirebaseKey: config.minimumVersionFirebaseKey,
                managerOverrideFirebaseKey: config.managerOverrideFirebaseKey
            ),
            timing: timing
        )
        
        // Setup reminder engine
        let reminderEngine = UpdateReminderEngine(
            store: UserDefaultsReminderStore(),
            timing: timing
        )
        
        // Setup presenter
        let presenter = UpdateAlertPresenter(
            viewControllerProvider: { [weak self] in
                self?.topViewController()
            }, config: config
        )
        
        // Create update manager
        self.updateManager = UpdateManager(
            provider: provider,
            reminderEngine: reminderEngine,
            presenter: presenter
        )
        
        // Reset session state on setup (app cold launch)
        updateManager?.resetSession()
        
        return self
    }
    
    // MARK: - Public API
    
    public func checkForUpdate(allowSkip: Bool = false) async -> UpdateState {
        guard let manager = updateManager, let config = config else {
            fatalError("AppUpdateManager: Call setup() first")
        }
        
        let currentVersion = Bundle.main.versionString
        let isOffline = !NetworkReachability.shared.isConnected
        
        // Task.detached moves Firebase fetching off the main thread entirely
        // presenter inside still dispatches to @MainActor, so UI updates remain safe
        return await Task.detached(priority: .background) {
            await manager.checkForUpdate(
                currentVersion: currentVersion,
                offlineMode: isOffline,
                updateUrl: config.appStoreURL,
                allowSkip: allowSkip
            )
        }.value
    }
 
    public func checkForUpdate(completion: @escaping (UpdateState) -> Void) {
        Task {
            let state = await checkForUpdate()
            await MainActor.run {
                completion(state)
            }
        }
    }
    
    // MARK: - View Controller Helpers
    
    @MainActor
    private func topViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }

        return findTopViewController(from: root)
    }
    
    @MainActor
    private func findTopViewController(from viewController: UIViewController) -> UIViewController {
        if let presented = viewController.presentedViewController {
            return findTopViewController(from: presented)
        }

        if let navigation = viewController as? UINavigationController,
           let visible = navigation.visibleViewController {
            return findTopViewController(from: visible)
        }

        if let tabBar = viewController as? UITabBarController,
           let selected = tabBar.selectedViewController {
            return findTopViewController(from: selected)
        }

        return viewController
    }
}

