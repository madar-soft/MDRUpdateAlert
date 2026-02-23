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
}

//MARK: - Implementation

@MainActor
final class UpdateAlertPresenter: UpdateAlertPresenting {
 
    private let viewControllerProvider: () -> UIViewController?
    private let isArabic: Bool

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

        let config = makeConfig(for: state)

        let alert = UIAlertController(
            title: config.title,
            message: config.message,
            preferredStyle: .alert
        )
        
        if config.showsLater {
            alert.addAction(UIAlertAction(title: laterButtonTitle, style: .cancel) { _ in
                onLater()
            })
        }
        
        alert.addAction(UIAlertAction(title: updateButtonTitle, style: .default) { _ in
            guard let url = URL(string: updateURL), UIApplication.shared.canOpenURL(url) else { return }
            UIApplication.shared.open(url)
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
    var laterButtonTitle: String {
        isArabic ? "لاحقاً" : "Later"
    }
    
    var updateButtonTitle: String {
        isArabic ? "تحديث الآن" : "Update Now"
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
}
