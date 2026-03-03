//
//  CenteredAlertController.swift
//  MDRUpdateAlert
//
//  Created by Belal Samy on 03/03/2026.
//

import Foundation
import UIKit

final class CenteredAlertController: UIAlertController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        centerLabels()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        centerLabels()
    }
    
    private func centerLabels() {
        view.allSubviews
            .compactMap { $0 as? UILabel }
            .forEach { $0.textAlignment = .center }
    }
}

extension UIView {
    var allSubviews: [UIView] {
        subviews + subviews.flatMap { $0.allSubviews }
    }
}
