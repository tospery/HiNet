//
//  ReachManager.swift
//  HiNet
//
//  Created by liaoya on 2022/7/19.
//

import Foundation
import RxSwift
import RxRelay
import Alamofire
 
public let reachSubject = BehaviorRelay<NetworkReachabilityManager.NetworkReachabilityStatus>.init(value: .unknown)
 
final public class ReachSubjecter {
    
    let network = NetworkReachabilityManager.default
    public static let shared = ReachSubjecter()

    init() {
    }
    
    deinit {
        self.network?.stopListening()
    }
    
    public func start() {
        self.network?.startListening(onUpdatePerforming: { status in
            print("网络状态：\(status)")
            reachSubject.accept(status)
        })
    }

}
