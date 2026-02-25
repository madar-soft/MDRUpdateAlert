//
//  NetworkReachability.swift
//  MDRUpdateAlert
//
//  Created by Belal Samy on 19/02/2026.
//

import Foundation
import Network

final class NetworkReachability {
    static let shared = NetworkReachability()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.appupdate.network")
    
    private(set) var isConnected: Bool = true
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isConnected = path.status == .satisfied
        }
        monitor.start(queue: queue)
    }
}
