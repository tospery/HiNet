//
//  NetworkingType.swift
//  HiNet
//
//  Created by liaoya on 2022/7/19.
//

import Foundation
import Combine
import ObjectMapper
import Moya

public protocol NetworkPublishType {
    associatedtype Target: TargetType
    var provider: MoyaProvider<Target> { get }
    func request(_ target: Target) -> AnyPublisher<Moya.Response, Error>
}

public extension NetworkPublishType {
    static var endpointClosure: MoyaProvider<Target>.EndpointClosure {
        return { target in
            return MoyaProvider.defaultEndpointMapping(for: target)
        }
    }
    
    static var requestClosure: MoyaProvider<Target>.RequestClosure {
        return { (endpoint, closure) in
            do {
                var request = try endpoint.urlRequest()
                request.httpShouldHandleCookies = true
                request.timeoutInterval = 15
                closure(.success(request))
            } catch {
                closure(.failure(MoyaError.underlying(error, nil)))
            }
        }
    }
    
    static var stubClosure: MoyaProvider<Target>.StubClosure {
        return { _ in
            return .never
        }
    }

    static var callbackQueue: DispatchQueue? {
        return nil
    }
    
    static var session: Session {
        return MoyaProvider<Target>.defaultAlamofireSession()
    }
    
    static var plugins: [PluginType] {
        var plugins: [PluginType] = []
        let logger = NetworkLoggerPlugin.init()
        logger.configuration.logOptions = [.requestBody, .successResponseBody, .errorResponseBody]
        // logger.configuration.output = output
        plugins.append(logger)
        return plugins
    }
    
    static var trackInflights: Bool {
        return false
    }

}

public extension NetworkPublishType {
    func request(_ target: Target) -> AnyPublisher<Moya.Response, Error> {
        self.provider.requestPublisher(target)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    func requestRaw(_ target: Target) -> AnyPublisher<Moya.Response, Error> {
        self.request(target)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func requestJSON(_ target: Target) -> AnyPublisher<Any, Error> {
        self.request(target)
            .mapError { $0 as! MoyaError }
            .eraseToAnyPublisher()
            .mapJSON(failsOnEmptyData: true)
            .mapError { $0 as Error }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func requestObject<Model: Mappable>(_ target: Target, type: Model.Type) -> AnyPublisher<Model, Error> {
        self.request(target)
            .mapObject(Model.self)
            .flatMap { response -> AnyPublisher<Model, Error> in
                if let int = (response as? (any Identifiable))?.id as? Int, int == 0 {
                    return Fail(error: HiNetError.dataInvalid).eraseToAnyPublisher()
                }
                if let string = (response as? (any Identifiable))?.id as? String, string.isEmpty {
                    return Fail(error: HiNetError.dataInvalid).eraseToAnyPublisher()
                }
                return Just(response).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func requestArray<Model: Mappable>(_ target: Target, type: Model.Type) -> AnyPublisher<[Model], Error> {
        self.request(target)
            .mapArray(Model.self)
            .flatMap {
                $0.isEmpty ? 
                Fail(error: HiNetError.listIsEmpty).eraseToAnyPublisher() :
                Just($0).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func requestBase(_ target: Target) -> AnyPublisher<BaseResponse, Error> {
        self.request(target)
            .mapObject(BaseResponse.self)
            .flatMap { response -> AnyPublisher<BaseResponse, Error> in
                if let error = self.check(response.code(target), response.message(target)) {
                    return Fail(error: error).eraseToAnyPublisher()
                }
                return Just(response).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func requestData(_ target: Target) -> AnyPublisher<Any?, Error> {
        self.request(target)
            .mapObject(BaseResponse.self)
            .flatMap { response -> AnyPublisher<Any?, Error> in
                if let error = self.check(response.code(target), response.message(target)) {
                    return Fail(error: error).eraseToAnyPublisher()
                }
                return Just(response.data(target)).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func requestModel<Model: Mappable>(_ target: Target, type: Model.Type) -> AnyPublisher<Model, Error> {
        self.request(target)
            .mapObject(BaseResponse.self)
            .flatMap { response -> AnyPublisher<Model, Error> in
                if let error = self.check(response.code(target), response.message(target)) {
                    return Fail(error: error).eraseToAnyPublisher()
                }
                let data = response.data(target)
                guard let json = data as? [String: Any],
                      let model = Model.init(JSON: json) else {
                    return Fail(error: HiNetError.dataInvalid).eraseToAnyPublisher()
                }
                return Just(model).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func requestModels<Model: Mappable>(_ target: Target, type: Model.Type) -> AnyPublisher<[Model], Error> {
        self.request(target)
            .mapObject(BaseResponse.self)
            .flatMap { response -> AnyPublisher<[Model], Error> in
                if let error = self.check(response.code(target), response.message(target)) {
                    return Fail(error: error).eraseToAnyPublisher()
                }
                guard let json = response.data(target) as? [[String: Any]] else {
                    return Fail(error: HiNetError.dataInvalid).eraseToAnyPublisher()
                }
                let models = [Model].init(JSONArray: json)
                if models.count == 0 {
                    return Fail(error: HiNetError.listIsEmpty).eraseToAnyPublisher()
                }
                return Just(models).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func requestList<Model: Mappable>(_ target: Target, type: Model.Type) -> AnyPublisher<List<Model>, Error> {
        self.request(target)
            .mapObject(BaseResponse.self)
            .flatMap { response -> AnyPublisher<List<Model>, Error> in
                if let error = self.check(response.code(target), response.message(target)) {
                    return Fail(error: error).eraseToAnyPublisher()
                }
                guard let json = response.data(target) as? [String: Any],
                      let list = List<Model>.init(JSON: json) else {
                    return Fail(error: HiNetError.dataInvalid).eraseToAnyPublisher()
                }
                if list.items.count == 0 {
                    return Fail(error: HiNetError.listIsEmpty).eraseToAnyPublisher()
                }
                return Just(list).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    private func check(_ code: Int, _ message: String?) -> HiNetError? {
        guard code == 200 else {
            if code == 401 {
                return .userNotLoginedIn
            }
//            if code == 403 {
//                return .userLoginExpired
//            }
            return HiNetError.server(code, message, nil)
        }
        return nil
    }
    
}
