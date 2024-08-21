//
//  IPManager.swift
//  HiNet
//
//  Created by liaoya on 2022/7/19.
//

import Foundation
import Combine
import Alamofire

public let ipSubject = CurrentValueSubject<String?, Never>(nil)

final public class IPManager {
    
    private var subscription: AnyCancellable?
    
    public static let shared = IPManager()
    
    init() {
        
    }
    
    deinit {
    }
    
    public func start() {
        self.subscription = reachSubject
            .filter { $0 != .unknown }
            .flatMap { _ in self.request() }
            .sink { ip in
                ipSubject.send(ip)
            }
    }
    
    func request() -> AnyPublisher<String, Never> {
        self.request(urlString: "https://api.ipify.org")
            .catch { [weak self] _ -> AnyPublisher<String, Error> in
                guard let self = self else { return Just("").setFailureType(to: Error.self).eraseToAnyPublisher() }
                return self.request(urlString: "https://api.myip.la")
            }
            .handleEvents(receiveOutput: { ip in
                print("本机IP: \(ip)")
            }, receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("本机IP错误: \(error)")
                }
            })
            .replaceError(with: "")
            .eraseToAnyPublisher()
    }
    
    func request(urlString: String) -> AnyPublisher<String, Error> {
        Deferred {
            Future<String, Error> { promise in
                AF.request(urlString, requestModifier: { $0.timeoutInterval = 2 })
                    .responseString { response in
                        if let string = response.value, !string.isEmpty {
                            promise(.success(string))
                        } else {
                            promise(.failure(response.error ?? HiNetError.unknown))
                        }
                    }
            }
        }
        .eraseToAnyPublisher()
    }

}
