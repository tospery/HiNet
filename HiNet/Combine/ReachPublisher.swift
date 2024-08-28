//
//  ReachManager.swift
//  HiNet
//
//  Created by liaoya on 2022/7/19.
//

import Foundation
import Combine
import Alamofire
 
public let reachPublisher = CurrentValueSubject<NetworkReachabilityManager.NetworkReachabilityStatus, Never>(.unknown)

final public class ReachPublisher {
    
    let network = NetworkReachabilityManager.default
    public static let shared = ReachPublisher()

    init() {
    }
    
    deinit {
        self.network?.stopListening()
    }
    
    public func start() {
        self.network?.startListening(onUpdatePerforming: { status in
            print("网络状态：\(status)")
            reachPublisher.send(status)
        })
    }

}
