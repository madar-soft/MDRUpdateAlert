//
//  Version.swift
//  MDRUpdateAlert
//
//  Created by Belal Samy on 19/02/2026.
//

import Foundation

struct Version: Comparable {
    let components: [Int]

    init(_ string: String) {
        let cleaned = string
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\"", with: "")

        self.components = cleaned
            .split(separator: ".")
            .map { Int($0) ?? 0 }
    }


    static func < (lhs: Version, rhs: Version) -> Bool {
        let maxCount = max(lhs.components.count, rhs.components.count)

        for i in 0..<maxCount {
            let l = i < lhs.components.count ? lhs.components[i] : 0
            let r = i < rhs.components.count ? rhs.components[i] : 0
            if l != r { return l < r }
        }

        return false
    }
}

// MARK: - Bundle Extension

extension Bundle {
    var versionString: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}
