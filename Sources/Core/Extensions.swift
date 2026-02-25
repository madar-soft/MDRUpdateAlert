//
//  Extensions.swift
//  MDRUpdateAlert
//
//  Created by Belal Samy on 24/02/2026.
//

import Foundation

// MARK: - Bundle Extension

extension Bundle {
    var versionString: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}
