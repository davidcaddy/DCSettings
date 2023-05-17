//
//  DCKeyValueStore.swift
//
//  Created by David Caddy on 27/4/2023.
//

import Foundation
import Combine

public protocol DCKeyValueStore {
    
    func publisher(forKey key: String) -> AnyPublisher<Any?, Never>
    
    func set(_ value: Any?, forKey: String)
    
    func object(forKey: String) -> Any?
    
    func set(_ value: Bool, forKey: String)
    
    func bool(forKey: String) -> Bool
    
    func set(_ value: Int, forKey: String)
    
    func integer(forKey: String) -> Int
    
    func set(_ value: Double, forKey: String)
    
    func double(forKey: String) -> Double
    
    func string(forKey: String) -> String?
}

public enum DCSettingStore {
    
    case standard
    case userDefaults(suiteName: String)
    case ubiquitous
    case custom(backingStore: DCKeyValueStore)
    
    private var backingStore: DCKeyValueStore {
        switch self {
        case .standard:
            return UserDefaults.standard
        case .userDefaults(let suiteName):
            return UserDefaults.init(suiteName: suiteName) ?? .standard
        case .ubiquitous:
            return NSUbiquitousKeyValueStore.default
        case .custom(let backingStore):
            return backingStore
        }
    }
    
    public func publisher(forKey key: String) -> AnyPublisher<Any?, Never> {
        return backingStore.publisher(forKey: key)
    }
    
    public func set<ValueType>(_ value: ValueType?, forKey key: String) {
        if isStandardType(ValueType.self) {
            backingStore.set(value, forKey: key)
        }
        else if let encodableValue = value as? Encodable, let data = try? PropertyListEncoder().encode(encodableValue) {
            backingStore.set(data, forKey: key)
        }
    }
    
    public func object<ValueType>(forKey key: String) -> ValueType? {
        let object = backingStore.object(forKey: key)
        if isStandardType(ValueType.self) {
            return backingStore.object(forKey: key) as? ValueType
        }
        else if let data = object as? Data, let decodableType = ValueType.self as? Decodable.Type {
            let value = try? PropertyListDecoder().decode(decodableType, from: data)
            return value as? ValueType
        }
        return nil
    }
    
    public func set(_ value: Bool, forKey key: String) {
        backingStore.set(value, forKey: key)
    }
    
    public func bool(forKey key: String) -> Bool {
        return backingStore.bool(forKey: key)
    }
    
    public func set(_ value: Int, forKey key: String) {
        backingStore.set(value, forKey: key)
    }
    
    public func integer(forKey key: String) -> Int {
        return backingStore.integer(forKey: key)
    }
    
    public func set(_ value: Double, forKey key: String) {
        backingStore.set(value, forKey: key)
    }
    
    public func double(forKey key: String) -> Double {
        return backingStore.double(forKey: key)
    }
    
    public func string(forKey key: String) -> String? {
        return backingStore.string(forKey: key)
    }
    
    private func isStandardType<T>(_ type: T.Type) -> Bool {
        return type == Bool.self || type == Int.self || type == Double.self || type == String.self || type == Date.self || type == Data.self
    }
}

extension UserDefaults: DCKeyValueStore {
    public func publisher(forKey key: String) -> AnyPublisher<Any?, Never> {
        let notificationPublisher = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification, object: self)
            .map { _ in self.object(forKey: key) }
        let initialValuePublisher = Just(self.object(forKey: key))
        return initialValuePublisher.merge(with: notificationPublisher).eraseToAnyPublisher()
    }
}

extension NSUbiquitousKeyValueStore: DCKeyValueStore {
    
    public var changeNotificationName: NSNotification.Name {
        return NSUbiquitousKeyValueStore.didChangeExternallyNotification
    }
    
    public func set(_ value: Int, forKey defaultName: String) {
        setValue(Int64(value), forKey: defaultName)
    }
    
    public func integer(forKey defaultName: String) -> Int {
        return Int(longLong(forKey: defaultName))
    }
    
    public func publisher(forKey key: String) -> AnyPublisher<Any?, Never> {
        let notificationPublisher = NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: self)
            .map { _ in self.object(forKey: key) }
        let initialValuePublisher = Just(self.object(forKey: key))
        return initialValuePublisher.merge(with: notificationPublisher).eraseToAnyPublisher()
    }
}
