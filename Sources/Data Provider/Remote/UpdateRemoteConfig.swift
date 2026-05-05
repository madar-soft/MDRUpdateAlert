//
//  UpdateRemoteConfig.swift
//  MDRUpdateAlert
//
//  Created by Belal Samy on 19/02/2026.
//

import Foundation

public struct UpdateRemoteConfig: Codable {
    public let latestVersion: String
    public let minimumVersion: String
    public let managerOverride: String
    
    public init(
        latestVersion: String,
        minimumVersion: String,
        managerOverride: String
    ) {
        self.latestVersion = latestVersion
        self.minimumVersion = minimumVersion
        self.managerOverride = managerOverride
    }
}

extension UpdateRemoteConfig: Equatable {
    public static func == (lhs: UpdateRemoteConfig, rhs: UpdateRemoteConfig) -> Bool {
        lhs.latestVersion == rhs.latestVersion &&
        lhs.minimumVersion == rhs.minimumVersion &&
        lhs.managerOverride == rhs.managerOverride
    }
}
