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
        
        vc.present(alert, animated: true)
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
    var normalUpdateTitle: String { config.normalUpdateTitle }
    var normalUpdateMessage: String { config.normalUpdateMessage }

    var urgentUpdateTitle: String { config.urgentUpdateTitle }
    var urgentUpdateMessage: String { config.urgentUpdateMessage }
    
    var forcedUpdateTitle: String { config.forcedUpdateTitle }
    var forcedUpdateMessage: String { config.forcedUpdateMessage }
    
    var laterButtonTitle: String { config.laterButtonTitle }
    var updateButtonTitle: String { config.updateButtonTitle }

    var updatedSuccessfullyTitle: String { config.updatedSuccessfullyTitle }
    var updatedSuccessfullyMessage: String { config.updatedSuccessfullyMessage }
    var successButtonTitle: String { config.successButtonTitle }
}
