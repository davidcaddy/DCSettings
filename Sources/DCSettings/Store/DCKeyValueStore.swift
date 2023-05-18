//
//  DCKeyValueStore.swift
//
//  Created by David Caddy on 27/4/2023.
//

import Combine

/// A protocol that defines an interface for a key-value store.
public protocol DCKeyValueStore {
    
    /// Returns a publisher that emits the value for the given key whenever it changes.
    ///
    /// - Parameter key: The key for which to retrieve the value.
    /// - Returns: A publisher that emits the value for the given key whenever it changes.
    func publisher(forKey key: String) -> AnyPublisher<Any?, Never>
    
    /// Sets the value of the specified key in the key-value store.
    ///
    /// - Parameters:
    ///   - value: The value to set for the specified key.
    ///   - forKey: The key for which to set the value.
    func set(_ value: Any?, forKey: String)
    
    /// Returns the value associated with the specified key.
    ///
    /// - Parameter forKey: The key for which to retrieve the value.
    /// - Returns: The value associated with the specified key, or `nil` if the key does not exist.
    func object(forKey: String) -> Any?
    
    /// Sets a boolean value for the specified key in the key-value store.
    ///
    /// - Parameters:
    ///   - value: The boolean value to set for the specified key.
    ///   - forKey: The key for which to set the boolean value.
    func set(_ value: Bool, forKey: String)
    
    /// Returns a boolean value associated with the specified key.
    ///
    /// - Parameter forKey: The key for which to retrieve the boolean value.
    /// - Returns: The boolean value associated with the specified key, or `false` if the key does not exist or its value is not a boolean.
    func bool(forKey: String) -> Bool
    
    /// Sets an integer value for the specified key in the key-value store.
    ///
    /// - Parameters:
    ///   - value: The integer value to set for the specified key.
    ///   - forKey: The key for which to set the integer value.
    func set(_ value: Int, forKey: String)
    
    /// Returns an integer value associated with the specified key.
    ///
    /// - Parameter forKey: The key for which to retrieve the integer value.
    /// - Returns: The integer value associated with the specified key, or `0` if the key does not exist or its value is not an integer.
    func integer(forKey: String) -> Int
    
    /// Sets a double-precision floating-point value for the specified key in the key-value store.
    ///
    /// - Parameters:
    ///   - value: The double-precision floating-point value to set for the specified key.
    ///   - forKey: The key for which to set the double-precision floating-point value.
    func set(_ value: Double, forKey: String)
    
    /// Returns a double-precision floating-point value associated with the specified key.
    ///
    /// - Parameter forKey: The key for which to retrieve the double-precision floating-point value.
    /// - Returns: The double-precision floating-point value associated with the specified key, or `0.0` if the key does not exist or its value is not a double-precision floating-point number.
    func double(forKey: String) -> Double
    
    /// Returns a string associated with the specified key.
    ///
    /// - Parameter forKey: The key for which to retrieve the string.
    /// - Returns: The string associated with the specified key, or `nil` if the key does not exist or its value is not a string.
    func string(forKey: String) -> String?
}

