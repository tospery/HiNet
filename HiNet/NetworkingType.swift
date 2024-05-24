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
                if let int = (response as? (any Identifiable))?.id as? Int, int == 0 {
                    return .error(HiNetError.dataInvalid)
                }
                if let string = (response as? (any Identifiable))?.id as? String, string.isEmpty {
                    return .error(HiNetError.dataInvalid)
                }
                return .just(response)
        }
            .observe(on: MainScheduler.instance)
    }
    
    func requestArray<Model: Mappable>(_ target: Target, type: Model.Type) -> Single<[Model]> {
        return self.request(target)
            .mapArray(Model.self)
            .flatMap { $0.isEmpty ? .error(HiNetError.listIsEmpty) : .just($0) }
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
                    return .error(HiNetError.dataInvalid)
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
                    return .error(HiNetError.dataInvalid)
                }
                let models = [Model].init(JSONArray: json)
                if models.count == 0 {
                    return .error(HiNetError.listIsEmpty)
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
                        return .error(HiNetError.dataInvalid)
                }
                if list.items.count == 0 {
                    return .error(HiNetError.listIsEmpty)
                }
                return .just(list)
        }
            .observe(on: MainScheduler.instance)
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
