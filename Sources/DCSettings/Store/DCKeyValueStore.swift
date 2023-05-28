//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import Combine

/// A protocol that defines an interface for a key-value store.
public protocol DCKeyValueStore {
    
    /// Returns a publisher that emits the value for the given key whenever it changes.
    ///
    /// - Parameter key: The key for the value to observe.
    /// - Returns: A publisher that emits the value for the given key whenever it changes.
    func valuePublisher(forKey key: String) -> AnyPublisher<Any?, Never>
    
    /// Sets the value of the specified key in the key-value store.
    ///
    /// - Parameters:
    ///   - value: The value to store in the key-value store.
    ///   - key: The key with which to associate the value.
    func set(_ value: Any?, forKey key: String)
    
    /// Returns the value associated with the specified key.
    ///
    /// - Parameter key: A key in the key-value store.
    /// - Returns: The value associated with the specified key, or `nil` if the key does not exist.
    func object(forKey key: String) -> Any?
    
    /// Sets a boolean value for the specified key in the key-value store.
    ///
    /// - Parameters:
    ///   - value: The boolean value to store in the key-value store.
    ///   - key: The key with which to associate the value.
    func set(_ value: Bool, forKey key: String)
    
    /// Returns a boolean value associated with the specified key.
    ///
    /// - Parameter key: A key in the key-value store.
    /// - Returns: The boolean value associated with the specified key, or `false` if the key does not exist or its value is not a boolean.
    func bool(forKey key: String) -> Bool
    
    /// Sets an integer value for the specified key in the key-value store.
    ///
    /// - Parameters:
    ///   - value: The integer value to store in the key-value store.
    ///   - key: The key with which to associate the value.
    func set(_ value: Int, forKey key: String)
    
    /// Returns an integer value associated with the specified key.
    ///
    /// - Parameter key: A key in the key-value store.
    /// - Returns: The integer value associated with the specified key, or `0` if the key does not exist or its value is not an integer.
    func integer(forKey key: String) -> Int
    
    /// Sets a double-precision floating-point value for the specified key in the key-value store.
    ///
    /// - Parameters:
    ///   - value: The double-precision floating-point value to store in the key-value store.
    ///   - key: The key with which to associate the value.
    func set(_ value: Double, forKey key: String)
    
    /// Returns a double-precision floating-point value associated with the specified key.
    ///
    /// - Parameter key: A key in the key-value store.
    /// - Returns: The double-precision floating-point value associated with the specified key,
    /// or `0.0` if the key does not exist or its value is not a double-precision floating-point number.
    func double(forKey key: String) -> Double
    
    /// Returns a string associated with the specified key.
    ///
    /// - Parameter key: A key in the key-value store.
    /// - Returns: The string associated with the specified key, or `nil` if the key does not exist or its value is not a string.
    func string(forKey key: String) -> String?
}
