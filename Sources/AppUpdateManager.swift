//
//  AppUpdateManager.swift
//  MDRUpdateAlert
//
//  Created by Belal Samy on 19/02/2026.
//

import Foundation
import UIKit
import FirebaseRemoteConfig

public class AppUpdateManager {
    
    // MARK: - Singleton
    
    public static let shared = AppUpdateManager()
    private init() {}
    
    // MARK: - Properties
    
    private var updateManager: UpdateManaging?
    private var config: Config?
    
    // MARK: - Public Config
     
    public struct Config {
        
        // Must Have ================================
        
        public let appStoreID: String
        public let isArabic: Bool
        
        // Optional =================================
        
        // Timing
        public let cacheExpiry: TimeInterval
        public let normalReminderInterval: TimeInterval
        
        // Firebase Keys
        public let latestVersionFirebaseKey: String
        public let minimumVersionFirebaseKey: String
        public let managerOverrideFirebaseKey: String
        
        // Alert Strings
        public let normalUpdateTitle: String
        public let normalUpdateMessage: String

        public let urgentUpdateTitle: String
        public let urgentUpdateMessage: String
        
        public let forcedUpdateTitle: String
        public let forcedUpdateMessage: String
        
        public let laterButtonTitle: String
        public let updateButtonTitle: String

        public let updatedSuccessfullyTitle: String
        public let updatedSuccessfullyMessage: String
        public let successButtonTitle: String

        public init(
            appStoreID: String,
            isArabic: Bool,
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
            self.isArabic = isArabic
            self.cacheExpiry = cacheExpiry
            self.normalReminderInterval = normalReminderInterval
            
            self.latestVersionFirebaseKey = latestVersionFirebaseKey
            self.minimumVersionFirebaseKey = minimumVersionFirebaseKey
            self.managerOverrideFirebaseKey = managerOverrideFirebaseKey
            
            // Fallback to default Localization Generator
            func localized(ar: String, en: String) -> String {
                isArabic ? ar : en
            }
            
            // Normal
            self.normalUpdateTitle = normalUpdateTitle ??
                localized(ar: "تحديث متوفر", en: "Update Available")

            self.normalUpdateMessage = normalUpdateMessage ??
                localized(ar: "نسخة أحدث من التطبيق متوفرة.", en: "A newer version is available.")
            
            // Urgent
            self.urgentUpdateTitle = urgentUpdateTitle ??
                localized(ar: "تحديث موصى به", en: "Update Recommended")

            self.urgentUpdateMessage = urgentUpdateMessage ??
                localized(ar: "يرجى التحديث للحصول على أفضل تجربة.", en: "Please update for the best experience.")

            // Forced
            self.forcedUpdateTitle = forcedUpdateTitle ??
                localized(ar: "تحديث إلزامي", en: "Update Required")

            self.forcedUpdateMessage = forcedUpdateMessage ??
                localized(ar: "يجب عليك التحديث لمواصلة استخدام التطبيق.", en: "You must update to continue using the app.")
            
            // Buttons
            self.laterButtonTitle = laterButtonTitle ??
                localized(ar: "لاحقاً", en: "Later")

            self.updateButtonTitle = updateButtonTitle ??
                localized(ar: "تحديث الآن", en: "Update Now")

            // Success
            self.updatedSuccessfullyTitle = updatedSuccessfullyTitle ??
                localized(ar: "🎉 تم تحديث التطبيق بنجاح", en: "App Updated Successfully 🎉")
            
            self.updatedSuccessfullyMessage = updatedSuccessfullyMessage ??
                localized(
                    ar: "شكراً لتحديث التطبيق. استمتع بأحدث المزايا والتحسينات.",
                    en: "Thanks for updating! Enjoy the latest features and improvements."
                )
            
            self.successButtonTitle = successButtonTitle ??
                localized(ar: "حسناً", en: "OK")
        }
        
        var appStoreURL: String {
            "https://apps.apple.com/app/id\(appStoreID)"
        }
    }
    
    // MARK: - Setup
    
    @MainActor @discardableResult
    public func setup(with config: Config) -> Self {
        self.config = config
        
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
        Task {
            await updateManager?.resetSession()
        }
        
        return self
    }
    
    // MARK: - Public API
    
    public func checkForUpdate(allowSkip: Bool = false) async -> UpdateState {
        guard let manager = updateManager, let config = config else {
            fatalError("AppUpdateManager: Call setup() first")
        }
        
        let currentVersion = Bundle.main.versionString
        let isOffline = !NetworkReachability.shared.isConnected
         
        return await manager.checkForUpdate(
            currentVersion: currentVersion,
            offlineMode: isOffline,
            updateUrl: config.appStoreURL,
            allowSkip: allowSkip
        )
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

