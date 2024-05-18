//
//  HiNetError.swift
//  HiNetwork
//
//  Created by 杨建祥 on 2024/5/17.
//

import Foundation

public enum HiNetError: Error {
    case unknown
    case dataInvalid
    case listIsEmpty
//    case networkNotConnected
//    case networkNotReachable
    case userNotLoginedIn   // 对应HTTP的401
    case userLoginExpired   // 将自己服务器的错误码转换为该值
    case server(Int, String?, [String: Any]?)
}
