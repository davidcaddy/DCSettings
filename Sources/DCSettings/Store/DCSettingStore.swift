//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import Foundation
import Combine

private let userDefaultsCache = UserDefaultsCache()

private final class UserDefaultsCache: @unchecked Sendable {

    private let lock = NSLock()
    private var stores: [String: UserDefaults] = [:]

    func userDefaults(suiteName: String) -> UserDefaults? {
        lock.lock()
        defer { lock.unlock() }

        if let store = stores[suiteName] {
            return store
        }

        let store = UserDefaults(suiteName: suiteName)
        stores[suiteName] = store
        return store
    }
}

/// An enumeration that represents different types of key-value stores.
public enum DCSettingStore {

    /// The standard `UserDefaults` key-value store.
    case standard

    /// A `UserDefaults` key-value store with the specified suite name.
    ///
    /// - Parameter suiteName: The suite name of the `UserDefaults` store to use.
    case userDefaults(suiteName: String)

    /// A key-value store that uses the iCloud `NSUbiquitousKeyValueStore` key-value store.
    ///
    /// On watchOS, this store is available in watchOS 9.0 or newer.
    @available(watchOS 9.0, *)
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
            return userDefaultsCache.userDefaults(suiteName: suiteName) ?? .standard
        case .ubiquitous:
            #if os(watchOS)
                if #available(watchOS 9.0, *) {
                    return NSUbiquitousKeyValueStore.default
                }

                return UserDefaults.standard
            #else
                return NSUbiquitousKeyValueStore.default
            #endif
        case .custom(let backingStore):
            return backingStore
        }
    }

    /// Returns a publisher that emits the value for the given key whenever it changes.
    ///
    /// - Parameter key: The key for the value to observe.
    /// - Returns: A publisher that emits the value for the given key whenever it changes.
    public func valuePublisher(forKey key: String) -> AnyPublisher<Any?, Never> {
        return backingStore.valuePublisher(forKey: key)
    }

    /// Returns a publisher that emits the typed value for the given key whenever it changes.
    ///
    /// - Parameters:
    ///   - key: The key for the value to observe.
    ///   - type: The expected value type.
    /// - Returns: A publisher that emits decoded typed values for the given key whenever it changes.
    public func valuePublisher<ValueType>(forKey key: String, as type: ValueType.Type) -> AnyPublisher<ValueType?, Never> {
        return valuePublisher(forKey: key)
            .map { object in
                decodedValue(object, as: type)
            }
            .eraseToAnyPublisher()
    }

    /// Sets the value of the specified key in the key-value store.
    ///
    /// Standard property-list compatible values are stored directly. Other values
    /// must conform to `Codable` and are stored as JSON-encoded `Data`.
    ///
    /// - Parameters:
    ///   - value: The value to store in the key-value store.
    ///   - key: The key with which to associate the value.
    /// - Returns: `true` when the value could be stored, otherwise `false`.
    @discardableResult public func set<ValueType>(_ value: ValueType?, forKey key: String) -> Bool {
        guard let value else {
            backingStore.set(nil, forKey: key)
            return true
        }

        if isStandardType(ValueType.self) {
            backingStore.set(value, forKey: key)
            return true
        }

        if let codableValue = value as? Codable {
            do {
                let data = try JSONEncoder().encode(codableValue)
                backingStore.set(data, forKey: key)
                return true
            }
            catch {
                assertionFailure("[DCSettingStore] Failed to encode value for key '\(key)': \(error)")
                return false
            }
        }

        assertionFailure("[DCSettingStore] Unsupported value for key '\(key)'. Values must be property-list compatible or Codable.")
        return false
    }

    /// Returns the value associated with the specified key.
    ///
    /// - Parameter key: A key in the key-value store.
    /// - Returns: The value associated with the specified key, or `nil` if the key does not exist.
    public func object<ValueType>(forKey key: String) -> ValueType? {
        return decodedValue(backingStore.object(forKey: key), as: ValueType.self)
    }

    /// Sets a boolean value for the specified key in the key-value store.
    ///
    /// - Parameters:
    ///   - value: The boolean value to store in the key-value store.
    ///   - key: The key with which to associate the value.
    public func set(_ value: Bool, forKey key: String) {
        backingStore.set(value, forKey: key)
    }

    /// Returns a boolean value associated with the specified key.
    ///
    /// - Parameter key: A key in the key-value store.
    /// - Returns: The boolean value associated with the specified key, or `false` if the key does not exist or its value is not a boolean.
    public func bool(forKey key: String) -> Bool {
        return backingStore.bool(forKey: key)
    }

    /// Sets an integer value for the specified key in the key-value store.
    ///
    /// - Parameters:
    ///   - value: The integer value to store in the key-value store.
    ///   - key: The key with which to associate the value.
    public func set(_ value: Int, forKey key: String) {
        backingStore.set(value, forKey: key)
    }

    /// Returns an integer value associated with the specified key.
    ///
    /// - Parameter key: A key in the key-value store.
    /// - Returns: The integer value associated with the specified key, or `0` if the key does not exist or its value is not an integer.
    public func integer(forKey key: String) -> Int {
        return backingStore.integer(forKey: key)
    }

    /// Sets a double-precision floating-point value for the specified key in the key-value store.
    ///
    /// - Parameters:
    ///   - value: The double-precision floating-point value to store in the key-value store.
    ///   - key: The key with which to associate the value.
    public func set(_ value: Double, forKey key: String) {
        backingStore.set(value, forKey: key)
    }

    /// Returns a double-precision floating-point value associated with the specified key.
    ///
    /// - Parameter key:  A key in the key-value store.
    /// - Returns: The double-precision floating-point value associated with the specified key,
    /// or `0.0` if the key does not exist or its value is not a double-precision floating-point number.
    public func double(forKey key: String) -> Double {
        return backingStore.double(forKey: key)
    }

    /// Returns a string associated with the specified key.
    ///
    /// - Parameter key: A key in the key-value store.
    /// - Returns: The string associated with the specified key, or `nil` if the key does not exist or its value is not a string.
    public func string(forKey key: String) -> String? {
        return backingStore.string(forKey: key)
    }

    private func isStandardType<T>(_ type: T.Type) -> Bool {
        return type == Bool.self || type == Int.self || type == Double.self || type == String.self || type == Date.self || type == Data.self
    }

    private func decodedValue<ValueType>(_ object: Any?, as type: ValueType.Type) -> ValueType? {
        if let value = object as? ValueType {
            return value
        }

        if let data = object as? Data, let decodableType = ValueType.self as? Decodable.Type {
            let value = try? JSONDecoder().decode(decodableType, from: data)
            return value as? ValueType
        }

        return nil
    }
}
