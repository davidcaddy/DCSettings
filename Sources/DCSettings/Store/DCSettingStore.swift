//
//  DCSettingStore.swift
//
//  Created by David Caddy on 17/5/2023.
//

import Foundation
import Combine

/// An enumeration that represents different types of key-value stores.
public enum DCSettingStore {
    
    /// The standard `UserDeafults` key-value store.
    case standard
    
    /// A key-value store that uses a user defaults database with the specified suite name.
    ///
    /// - Parameter suiteName: The suite name of the user defaults database to use.
    case userDefaults(suiteName: String)
    
    /// A key-value store that uses the iCloud key-value store.
    case ubiquitous
    
    /// A custom key-value store that conforms to the `DCKeyValueStore` protocol.
    ///
    /// - Parameter backingStore: The custom key-value store to use.
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
    
    /// Returns a publisher that emits the value for the given key whenever it changes.
    ///
    /// - Parameter forKey: The key for which to retrieve the value.
    /// - Returns: A publisher that emits the value for the given key whenever it changes.
    public func publisher(forKey key: String) -> AnyPublisher<Any?, Never> {
        return backingStore.publisher(forKey: key)
    }
    
    /// Sets the value of the specified key in the key-value store.
    ///
    /// - Parameters:
    ///   - value: The value to set for the specified key.
    ///   - forKey: The key for which to set the value.
    public func set<ValueType>(_ value: ValueType?, forKey key: String) {
        if isStandardType(ValueType.self) {
            backingStore.set(value, forKey: key)
        }
        else if let encodableValue = value as? Encodable, let data = try? PropertyListEncoder().encode(encodableValue) {
            backingStore.set(data, forKey: key)
        }
    }
    
    /// Returns the value associated with the specified key.
    ///
    /// - Parameter forKey: The key for which to retrieve the value.
    /// - Returns: The value associated with the specified key, or `nil` if the key does not exist.
    public func object<ValueType>(forKey key: String) -> ValueType? {
        if case .custom(_) = self {
            return backingStore.object(forKey: key) as? ValueType
        }
        
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
    
    /// Sets a boolean value for the specified key in the key-value store.
    ///
    /// - Parameters:
    ///   - value: The boolean value to set for the specified key.
    ///   - forKey: The key for which to set the boolean value.
    public func set(_ value: Bool, forKey key: String) {
        backingStore.set(value, forKey: key)
    }
    
    /// Returns a boolean value associated with the specified key.
    ///
    /// - Parameter forKey: The key for which to retrieve the boolean value.
    /// - Returns: The boolean value associated with the specified key, or `false` if the key does not exist or its value is not a boolean.
    public func bool(forKey key: String) -> Bool {
        return backingStore.bool(forKey: key)
    }
    
    /// Sets an integer value for the specified key in the key-value store.
    ///
    /// - Parameters:
    ///   - value: The integer value to set for the specified key.
    ///   - forKey: The key for which to set the integer value.
    public func set(_ value: Int, forKey key: String) {
        backingStore.set(value, forKey: key)
    }
    
    /// Returns an integer value associated with the specified key.
    ///
    /// - Parameter forKey: The key for which to retrieve the integer value.
    /// - Returns: The integer value associated with the specified key, or `0` if the key does not exist or its value is not an integer.
    public func integer(forKey key: String) -> Int {
        return backingStore.integer(forKey: key)
    }
    
    /// Sets a double-precision floating-point value for the specified key in the key-value store.
    ///
    /// - Parameters:
    ///   - value: The double-precision floating-point value to set for the specified key.
    ///   - forKey: The key for which to set the double-precision floating-point value.
    public func set(_ value: Double, forKey key: String) {
        backingStore.set(value, forKey: key)
    }
    
    /// Returns a double-precision floating-point value associated with the specified key.
    ///
    /// - Parameter forKey: The key for which to retrieve the double-precision floating-point value.
    /// - Returns: The double-precision floating-point value associated with the specified key, or `0.0` if the key does not exist or its value is not a double-precision floating-point number.
    public func double(forKey key: String) -> Double {
        return backingStore.double(forKey: key)
    }
    
    /// Returns a string associated with the specified key.
    ///
    /// - Parameter forKey: The keyof which to retrieve string
    ///
    public func string(forKey key: String) -> String? {
        return backingStore.string(forKey: key)
    }
    
    private func isStandardType<T>(_ type: T.Type) -> Bool {
        return type == Bool.self || type == Int.self || type == Double.self || type == String.self || type == Date.self || type == Data.self
    }
}
