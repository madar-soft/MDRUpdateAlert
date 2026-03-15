//
//  UpdateAlertPresenter.swift
//  MDRUpdateAlert
//
//  Created by Belal Samy on 19/02/2026.
//

import UIKit

//MARK: - Protocol

@MainActor
public protocol UpdateAlertPresenting {
    func presentAlert(
        for state: UpdateState,
        updateURL: String,
        onUpdate: @escaping () -> Void,
        onLater: @escaping () -> Void
    )
    
    func presentAppUpdatedAlert()
}

//MARK: - Implementation

@MainActor
final class UpdateAlertPresenter: UpdateAlertPresenting {
 
    private let viewControllerProvider: () -> UIViewController?
    private let config: AppUpdateManager.Config
    
    private var isPresenting = false
    
    init(viewControllerProvider: @escaping () -> UIViewController?, config: AppUpdateManager.Config) {
        self.viewControllerProvider = viewControllerProvider
        self.config = config
    }

    func presentAlert(
        for state: UpdateState,
        updateURL: String,
        onUpdate: @escaping () -> Void,
        onLater: @escaping () -> Void
    ) {
        guard state != .none else { return }
        guard let vc = viewControllerProvider() else { return }
        
        // If already presenting an alert, ignore this one completely
        guard !isPresenting else { return }
        isPresenting = true

        let alertConfig = makeConfig(for: state)
        
        let alert = CenteredAlertController(
            title: alertConfig.title,
            message: alertConfig.message,
            preferredStyle: .alert
        )
        
        if alertConfig.showsLater {
            alert.addAction(UIAlertAction(title: laterButtonTitle, style: .cancel) { [weak self] _ in
                self?.isPresenting = false // Reset flag
                onLater()
            })
        }
         
        alert.addAction(UIAlertAction(title: updateButtonTitle, style: .default) { [weak self] _ in
            self?.isPresenting = false // Reset flag
            onUpdate()
            
            guard let url = URL(string: updateURL), UIApplication.shared.canOpenURL(url) else { return }
            UIApplication.shared.open(url)
        })
        
        guard self.isAllowed(for: state, on: vc) else {
            self.isPresenting = false
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self, self.isPresenting else { return }
            vc.present(alert, animated: true)
        }
    }
    
    func presentAppUpdatedAlert() {
        guard let vc = viewControllerProvider() else { return }
        
        // If already presenting an alert, ignore this one completely
        guard !isPresenting else { return }
        isPresenting = true

        let alert = CenteredAlertController(
            title: updatedSuccessfullyTitle,
            message: updatedSuccessfullyMessage,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: successButtonTitle, style: .default) { [weak self] _ in
            self?.isPresenting = false // Reset flag
        })
        
        vc.present(alert, animated: true)
    }
     
    private func isAllowed(for state: UpdateState, on vc: UIViewController) -> Bool {
        guard state != .forced else { return true }
        let vcName = String(describing: type(of: vc))
        return !AppUpdateManager.shared.protectedScreens.contains(vcName)
    }
}

// MARK: - Private

private extension UpdateAlertPresenter {
    struct AlertConfig {
        let title: String
        let message: String
        let showsLater: Bool
    }

    func makeConfig(for state: UpdateState) -> AlertConfig {
        switch state {
        case .normal:
            return .init(
                title: normalUpdateTitle,
                message: normalUpdateMessage,
                showsLater: true
            )
        case .urgent:
            return .init(
                title: urgentUpdateTitle,
                message: urgentUpdateMessage,
                showsLater: true
            )
        case .forced:
            return .init(
                title: forcedUpdateTitle,
                message: forcedUpdateMessage,
                showsLater: false
            )
        case .none:
            return .init(title: "", message: "", showsLater: false)
        }
    }
}


//MARK: - Localized Strings

private extension UpdateAlertPresenter {
    // Fallback to default Localization Generator
    func localized(ar: String, en: String) -> String {
        AppUpdateManager.shared.isArabic ? ar : en
    }
    
    // Normal
    var normalUpdateTitle: String { config.normalUpdateTitle ?? localized(
        ar: "تحديث متوفر",
        en: "Update Available")
    }
    
    var normalUpdateMessage: String { config.normalUpdateMessage ?? localized(
        ar: "نسخة أحدث من التطبيق متوفرة.",
        en: "A newer version is available.")
    }

    // Urgent
    var urgentUpdateTitle: String { config.urgentUpdateTitle ?? localized(
        ar: "تحديث موصى به",
        en: "Update Recommended")
    }
    
    var urgentUpdateMessage: String { config.urgentUpdateMessage ?? localized(
        ar: "يرجى التحديث للحصول على أفضل تجربة.",
        en: "Please update for the best experience.")
    }
    
    // Forced
    var forcedUpdateTitle: String { config.forcedUpdateTitle ?? localized(
        ar: "تحديث إلزامي",
        en: "Update Required")
    }
    
    var forcedUpdateMessage: String { config.forcedUpdateMessage ?? localized(
        ar: "يجب عليك التحديث لمواصلة استخدام التطبيق.",
        en: "You must update to continue using the app.")
    }
    
    // Buttons
    var laterButtonTitle: String { config.laterButtonTitle ?? localized(
        ar: "لاحقاً",
        en: "Later")
    }
    
    var updateButtonTitle: String { config.updateButtonTitle ?? localized(
        ar: "تحديث الآن",
        en: "Update Now")
    }

    // Success
    var updatedSuccessfullyTitle: String { config.updatedSuccessfullyTitle ?? localized(
        ar: "🎉 تم تحديث التطبيق بنجاح",
        en: "App Updated Successfully 🎉")
    }
    
    var updatedSuccessfullyMessage: String { config.updatedSuccessfullyMessage ?? localized(
        ar: "شكراً لتحديث التطبيق. استمتع بأحدث المزايا والتحسينات.",
        en: "Thanks for updating! Enjoy the latest features and improvements."
    ) }
    
    var successButtonTitle: String { config.successButtonTitle ?? localized(
        ar: "حسناً",
        en: "OK")
    }
}







