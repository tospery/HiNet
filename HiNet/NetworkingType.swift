//
//  NetworkingType.swift
//  HiIOS
//
//  Created by liaoya on 2022/7/19.
//

import Foundation
import Moya
import RxSwift
import ObjectMapper

public protocol NetworkingType {
    associatedtype Target: TargetType
    var provider: MoyaProvider<Target> { get }
    func request(_ target: Target) -> Single<Moya.Response>
}

public extension NetworkingType {
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

public extension NetworkingType {
    func request(_ target: Target) -> Single<Moya.Response> {
        // YJX_TODO
        self.provider.rx.request(target)
            // .catch { Single<Moya.Response>.error($0.asHiError) }
            .catch { Single<Moya.Response>.error($0) }
    }
    
    func requestRaw(_ target: Target) -> Single<Moya.Response> {
        return self.request(target)
            .observe(on: MainScheduler.instance)
    }
    
    func requestJSON(_ target: Target) -> Single<Any> {
        return self.request(target)
            .mapJSON()
            .observe(on: MainScheduler.instance)
    }
    
    func requestObject<Model: Mappable>(_ target: Target, type: Model.Type) -> Single<Model> {
        return self.request(target)
            .mapObject(Model.self)
            .flatMap { response -> Single<Model> in
//                let id = (response as? (any Identifiable))?.id
//                if id is String {
//                    if (id as! String).isEmpty {
//                        return .error(HiNetworkError.dataInvalid)
//                    }
//                }
//                if id is Int {
//                    if (id as! Int) == 0 {
//                        return .error(HiNetworkError.dataInvalid)
//                    }
//                }
                // YJX_TODO
//                if !response.isValid {
//                    return .error(HiNetworkError.dataInvalid)
//                }
                if (response as? (any Identifiable))?.id.hashValue ?? 0 == 0 {
                    return .error(HiNetworkError.dataInvalid)
                }
                return .just(response)
        }
            .observe(on: MainScheduler.instance)
    }
    
    func requestArray<Model: Mappable>(_ target: Target, type: Model.Type) -> Single<[Model]> {
        return self.request(target)
            .mapArray(Model.self)
            .flatMap { $0.isEmpty ? .error(HiNetworkError.listIsEmpty) : .just($0) }
            .observe(on: MainScheduler.instance)
    }
    
    func requestBase(_ target: Target) -> Single<BaseResponse> {
        return self.request(target)
            .mapObject(BaseResponse.self)
            .flatMap { response -> Single<BaseResponse> in
                if let error = self.check(response.code(target), response.message(target)) {
                    return .error(error)
                }
                return .just(response)
        }
            .observe(on: MainScheduler.instance)
    }
    
    func requestData(_ target: Target) -> Single<Any?> {
        return self.request(target)
            .mapObject(BaseResponse.self)
            .flatMap { response -> Single<Any?> in
                if let error = self.check(response.code(target), response.message(target)) {
                    return .error(error)
                }
                return .just(response.data(target))
        }
            .observe(on: MainScheduler.instance)
    }
    
    func requestModel<Model: Mappable>(_ target: Target, type: Model.Type) -> Single<Model> {
        return self.request(target)
            .mapObject(BaseResponse.self)
            .flatMap { response -> Single<Model> in
                if let error = self.check(response.code(target), response.message(target)) {
                    return .error(error)
                }
                let data = response.data(target)
                guard let json = data as? [String: Any],
                      let model = Model.init(JSON: json) else {
                    return .error(HiNetworkError.dataInvalid)
                }
                return .just(model)
        }
            .observe(on: MainScheduler.instance)
    }
    
    func requestModels<Model: Mappable>(_ target: Target, type: Model.Type) -> Single<[Model]> {
        return self.request(target)
            .mapObject(BaseResponse.self)
            .flatMap { response -> Single<[Model]> in
                if let error = self.check(response.code(target), response.message(target)) {
                    return .error(error)
                }
                guard let json = response.data(target) as? [[String: Any]] else {
                    return .error(HiNetworkError.dataInvalid)
                }
                let models = [Model].init(JSONArray: json)
                if models.count == 0 {
                    return .error(HiNetworkError.listIsEmpty)
                }
                return .just(models)
        }
            .observe(on: MainScheduler.instance)
    }
    
    func requestList<Model: Mappable>(_ target: Target, type: Model.Type) -> Single<List<Model>> {
        return self.request(target)
            .mapObject(BaseResponse.self)
            .flatMap { response -> Single<List<Model>> in
                if let error = self.check(response.code(target), response.message(target)) {
                    return .error(error)
                }
                guard let json = response.data(target) as? [String: Any],
                      let list = List<Model>.init(JSON: json) else {
                        return .error(HiNetworkError.dataInvalid)
                }
                if list.items.count == 0 {
                    return .error(HiNetworkError.listIsEmpty)
                }
                return .just(list)
        }
            .observe(on: MainScheduler.instance)
    }
    
    private func check(_ code: Int, _ message: String?) -> HiNetworkError? {
        guard code == 200 else {
            if code == 401 {
                return .userNotLoginedIn
            }
//            if code == 403 {
//                return .userLoginExpired
//            }
            return HiNetworkError.server(code, message, nil)
        }
        return nil
    }
    
}
