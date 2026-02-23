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
}
