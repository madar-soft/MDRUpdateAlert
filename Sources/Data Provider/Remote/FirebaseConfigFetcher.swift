//
//  FirebaseConfigFetcher.swift
//  MDRUpdateAlert
//
//  Created by Belal Samy on 19/02/2026.
//

//  Talks to Firebase Remote Config via the Objective-C runtime so the package
//  doesn't have to declare FirebaseRemoteConfig as an SPM dependency. Whatever
//  Firebase the host app installs (CocoaPods or SPM) is what we drive.
//

import Foundation
import ObjectiveC

final class FirebaseConfigFetcher: UpdateRemoteFetching {
    
    enum FetchError: LocalizedError {
        case firebaseNotInstalled
        case selectorMissing(String)
        case fetchFailed(Error)
        case unexpectedReturn(String)
        
        var errorDescription: String? {
            switch self {
            case .firebaseNotInstalled:
                return """
                MDRUpdateAlert: FIRRemoteConfig was not found at runtime. \
                Make sure FirebaseRemoteConfig is installed in your app and \
                FirebaseApp.configure() is called before \
                AppUpdateManager.setup(with:).
                """
            case .selectorMissing(let s):
                return "MDRUpdateAlert: Firebase selector missing — \(s). Likely a Firebase SDK version mismatch."
            case .fetchFailed(let error):
                return "Firebase Remote Config fetch failed: \(error.localizedDescription)"
            case .unexpectedReturn(let s):
                return "MDRUpdateAlert: unexpected runtime return — \(s)"
            }
        }
    }
    
    private let latestVersionFirebaseKey: String
    private let minimumVersionFirebaseKey: String
    private let managerOverrideFirebaseKey: String
    
    init(
        latestVersionFirebaseKey: String = "latest_version",
        minimumVersionFirebaseKey: String = "minimum_version",
        managerOverrideFirebaseKey: String = "manager_override"
    ) {
        self.latestVersionFirebaseKey = latestVersionFirebaseKey
        self.minimumVersionFirebaseKey = minimumVersionFirebaseKey
        self.managerOverrideFirebaseKey = managerOverrideFirebaseKey
    }
    
    // MARK: - Resolve singleton
    
    private func resolveRemoteConfig() throws -> NSObject {
        guard let metaClass = NSClassFromString("FIRRemoteConfig") as? NSObject.Type else {
            throw FetchError.firebaseNotInstalled
        }
        
        let remoteConfigSel = NSSelectorFromString("remoteConfig")
        guard metaClass.responds(to: remoteConfigSel) else {
            throw FetchError.selectorMissing("+[FIRRemoteConfig remoteConfig]")
        }
        
        guard let unmanaged = metaClass.perform(remoteConfigSel) else {
            throw FetchError.unexpectedReturn("+remoteConfig returned nil")
        }
        
        guard let rc = unmanaged.takeUnretainedValue() as? NSObject else {
            throw FetchError.unexpectedReturn("+remoteConfig did not return an NSObject")
        }
        
        applySettings(to: rc)
        return rc
    }
    
    private func applySettings(to remoteConfig: NSObject) {
        guard let SettingsClass = NSClassFromString("FIRRemoteConfigSettings") as? NSObject.Type else {
            return
        }
        let settings = SettingsClass.init()
        
        // setMinimumFetchInterval: takes a double — KVC handles it
        settings.setValue(0.0, forKey: "minimumFetchInterval")
        
        let setConfigSettingsSel = NSSelectorFromString("setConfigSettings:")
        if remoteConfig.responds(to: setConfigSettingsSel) {
            _ = remoteConfig.perform(setConfigSettingsSel, with: settings)
        }
    }
    
    // MARK: - Fetch
    
    func fetchRemoteConfig() async throws -> UpdateRemoteConfig {
        let remoteConfig = try resolveRemoteConfig()
        
        let fetchSel = NSSelectorFromString("fetchAndActivateWithCompletionHandler:")
        guard remoteConfig.responds(to: fetchSel) else {
            throw FetchError.selectorMissing("-fetchAndActivateWithCompletionHandler:")
        }
        
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            // Block matches: void (^)(FIRRemoteConfigFetchAndActivateStatus, NSError * _Nullable)
            let completion: @convention(block) (Int, Error?) -> Void = { _, error in
                if let error = error {
                    cont.resume(throwing: FetchError.fetchFailed(error))
                } else {
                    cont.resume()
                }
            }
            _ = remoteConfig.perform(fetchSel, with: completion)
        }
        
        return UpdateRemoteConfig(
            latestVersion:   stringValue(from: remoteConfig, key: latestVersionFirebaseKey),
            minimumVersion:  stringValue(from: remoteConfig, key: minimumVersionFirebaseKey),
            managerOverride: stringValue(from: remoteConfig, key: managerOverrideFirebaseKey)
        )
    }
    
    private func stringValue(from remoteConfig: NSObject, key: String) -> String {
        let configValueSel = NSSelectorFromString("configValueForKey:")
        guard remoteConfig.responds(to: configValueSel),
              let unmanaged = remoteConfig.perform(configValueSel, with: key),
              let value = unmanaged.takeUnretainedValue() as? NSObject else {
            return ""
        }
        let stringSel = NSSelectorFromString("stringValue")
        guard value.responds(to: stringSel),
              let result = value.perform(stringSel)?.takeUnretainedValue() as? String else {
            return ""
        }
        return result
    }
}
