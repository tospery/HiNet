//
//  ObservableType+Net.swift
//  HiNet
//
//  Created by 杨建祥 on 2024/5/23.
//

import Foundation
import Combine
import ObjectMapper
import Moya

public extension Publisher where Output == Response, Failure == Error {
    
    func mapObject<T: BaseMappable>(_ type: T.Type, context: MapContext? = nil) -> AnyPublisher<T, Error> {
        flatMap { response -> AnyPublisher<T, Error> in
            do {
                let object = try response.mapObject(type, context: context)
                return Just(object)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            } catch {
                return Fail(error: error).eraseToAnyPublisher()
            }
        }
        .eraseToAnyPublisher()
    }
    
    func mapArray<T: BaseMappable>(_ type: T.Type, context: MapContext? = nil) -> AnyPublisher<[T], Error> {
        flatMap { response -> AnyPublisher<[T], Error> in
            do {
                let array = try response.mapArray(type, context: context)
                return Just(array)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            } catch {
                return Fail(error: error).eraseToAnyPublisher()
            }
        }
        .eraseToAnyPublisher()
    }
    
    func mapObject<T: BaseMappable>(_ type: T.Type, atKeyPath keyPath: String, context: MapContext? = nil) -> AnyPublisher<T, Error> {
        flatMap { response -> AnyPublisher<T, Error> in
            do {
                let object = try response.mapObject(T.self, atKeyPath: keyPath, context: context)
                return Just(object)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            } catch {
                return Fail(error: error).eraseToAnyPublisher()
            }
        }
        .eraseToAnyPublisher()
    }
    
    func mapArray<T: BaseMappable>(_ type: T.Type, atKeyPath keyPath: String, context: MapContext? = nil) -> AnyPublisher<[T], Error> {
        flatMap { response -> AnyPublisher<[T], Error> in
            do {
                let array = try response.mapArray(type, context: context)
                return Just(array)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            } catch {
                return Fail(error: error).eraseToAnyPublisher()
            }
        }
        .eraseToAnyPublisher()
    }
    
}


public extension Publisher where Output == Response, Failure == Error {
    
    func mapObject<T: ImmutableMappable>(_ type: T.Type, context: MapContext? = nil) -> AnyPublisher<T, Error> {
        flatMap { response -> AnyPublisher<T, Error> in
            do {
                let object = try response.mapObject(type, context: context)
                return Just(object)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            } catch {
                return Fail(error: error).eraseToAnyPublisher()
            }
        }
        .eraseToAnyPublisher()
    }
    
    func mapArray<T: ImmutableMappable>(_ type: T.Type, context: MapContext? = nil) -> AnyPublisher<[T], Error> {
        flatMap { response -> AnyPublisher<[T], Error> in
            do {
                let array = try response.mapArray(type, context: context)
                return Just(array)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            } catch {
                return Fail(error: error).eraseToAnyPublisher()
            }
        }
        .eraseToAnyPublisher()
    }
    
    func mapObject<T: ImmutableMappable>(_ type: T.Type, atKeyPath keyPath: String, context: MapContext? = nil) -> AnyPublisher<T, Error> {
        flatMap { response -> AnyPublisher<T, Error> in
            do {
                let object = try response.mapObject(T.self, atKeyPath: keyPath, context: context)
                return Just(object)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            } catch {
                return Fail(error: error).eraseToAnyPublisher()
            }
        }
        .eraseToAnyPublisher()
    }
    
    func mapArray<T: ImmutableMappable>(_ type: T.Type, atKeyPath keyPath: String, context: MapContext? = nil) -> AnyPublisher<[T], Error> {
        flatMap { response -> AnyPublisher<[T], Error> in
            do {
                let array = try response.mapArray(type, context: context)
                return Just(array)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            } catch {
                return Fail(error: error).eraseToAnyPublisher()
            }
        }
        .eraseToAnyPublisher()
    }
    
}

