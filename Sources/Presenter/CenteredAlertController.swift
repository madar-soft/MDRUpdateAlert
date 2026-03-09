//
//  CenteredAlertController.swift
//  MDRUpdateAlert
//
//  Created by Belal Samy on 03/03/2026.
//

import Foundation
import UIKit

final class CenteredAlertController: UIAlertController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        swizzleLabels()
    }
    
    private func swizzleLabels() {
        // Replace every UILabel in the hierarchy with our locked subclass
        view.allSubviews
            .compactMap { $0 as? UILabel }
            .forEach { label in
                // Directly override textAlignment before anything else touches it
                label.textAlignment = .center
                object_setClass(label, CenterLockedLabel.self)
            }
    }
}

// A UILabel subclass that physically cannot have its alignment changed
private final class CenterLockedLabel: UILabel {
    override var textAlignment: NSTextAlignment {
        get { .center }
        set { super.textAlignment = .center } // Ignore any value, always center
    }
}

extension UIView {
    var allSubviews: [UIView] {
        subviews + subviews.flatMap { $0.allSubviews }
    }
}
