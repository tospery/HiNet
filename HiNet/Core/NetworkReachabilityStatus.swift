//
//  NetworkReachabilityStatus.swift
//  HiNet
//
//  Created by 杨建祥 on 2024/8/29.
//

import Foundation
import Alamofire

extension NetworkReachabilityManager.NetworkReachabilityStatus {
    
    public var isCellular: Bool { self == .reachable(.cellular) }
    public var isWifi: Bool { self == .reachable(.ethernetOrWiFi) }
    public var isReachable: Bool { self != .notReachable && self != .unknown }
    
}


extension NetworkReachabilityManager.NetworkReachabilityStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown:
            return NSLocalizedString("Network.Reach.Unknow", value: "", comment: "") // 未知网络
        case .notReachable:
            return NSLocalizedString("Network.Reach.NotReachable", value: "", comment: "") // 网络不可达
        case let .reachable(type):
            return type == .cellular ? "cellular" : "wifi"
        }
     }
}
