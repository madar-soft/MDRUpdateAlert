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
        onLater: @escaping () -> Void
    )
    
    func presentAppUpdatedAlert()
}

//MARK: - Implementation

@MainActor
final class UpdateAlertPresenter: UpdateAlertPresenting {
 
    private let viewControllerProvider: () -> UIViewController?
    private let isArabic: Bool

    private var isPresenting = false
    
    init(viewControllerProvider: @escaping () -> UIViewController?, isArabic: Bool) {
        self.viewControllerProvider = viewControllerProvider
        self.isArabic = isArabic
    }

    func presentAlert(
        for state: UpdateState,
        updateURL: String,
        onLater: @escaping () -> Void
    ) {
        guard state != .none else { return }
        guard let vc = viewControllerProvider() else { return }
        
        // If already presenting an alert, ignore this one completely
        guard !isPresenting else { return }
        isPresenting = true

        let config = makeConfig(for: state)
        
        let alert = UIAlertController(
            title: config.title,
            message: config.message,
            preferredStyle: .alert
        )
        
        if config.showsLater {
            alert.addAction(UIAlertAction(title: laterButtonTitle, style: .cancel) { [weak self] _ in
                self?.isPresenting = false // Reset flag
                onLater()
            })
        }
         
        alert.addAction(UIAlertAction(title: updateButtonTitle, style: .default) { [weak self] _ in
            self?.isPresenting = false // Reset flag
            guard let url = URL(string: updateURL), UIApplication.shared.canOpenURL(url) else { return }
            UIApplication.shared.open(url)
        })
        
        DispatchQueue.main.async {
            vc.present(alert, animated: true)
        }
    }
    
    func presentAppUpdatedAlert() {
        guard let vc = viewControllerProvider() else { return }
        
        // If already presenting an alert, ignore this one completely
        guard !isPresenting else { return }
        isPresenting = true

        let alert = UIAlertController(
            title: updatedSuccessfullyTitle,
            message: updatedSuccessfullyMessage,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: successButtonTitle, style: .default) { [weak self] _ in
            self?.isPresenting = false // Reset flag
        })
        
        DispatchQueue.main.async {
            vc.present(alert, animated: true)
        }
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
    // Alert Buttons
    var laterButtonTitle: String {
        isArabic ? "لاحقاً" : "Later"
    }
    
    var updateButtonTitle: String {
        isArabic ? "تحديث الآن" : "Update Now"
    }
    
    var successButtonTitle: String {
        isArabic ? "حسناً" : "OK"
    }
    
    // Alert Titles
    var normalUpdateTitle: String {
        isArabic ? "تحديث متوفر" : "Update Available"
    }
    
    var urgentUpdateTitle: String {
        isArabic ? "تحديث موصى به" : "Update Recommended"
    }
    
    var forcedUpdateTitle: String {
        isArabic ? "تحديث إلزامي" : "Update Required"
    }
    
    var updatedSuccessfullyTitle: String {
        isArabic ? "🎉 تم تحديث التطبيق بنجاح" : "App Updated Successfully 🎉"
    }
    
    // Alert Messages
    var normalUpdateMessage: String {
        isArabic ? "نسخة أحدث من التطبيق متوفرة." : "A newer version is available."
    }
    
    var urgentUpdateMessage: String {
        isArabic ? "يرجى التحديث للحصول على أفضل تجربة." : "Please update for the best experience."
    }
    
    var forcedUpdateMessage: String {
        isArabic ? "يجب عليك التحديث لمواصلة استخدام التطبيق." : "You must update to continue using the app."
    }
    
    var updatedSuccessfullyMessage: String {
        isArabic
        ? "شكراً لتحديث التطبيق. استمتع بأحدث المزايا والتحسينات."
        : "Thanks for updating! Enjoy the latest features and improvements."
    }
}
