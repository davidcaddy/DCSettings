//
//  NSUbiquitousKeyValueStore+DCKeyValueStore.swift
//
//  Created by David Caddy on 17/5/2023.
//

import Foundation
import Combine

extension NSUbiquitousKeyValueStore: DCKeyValueStore {
    
    /// Sets the value of the specified default key in the key-value store.
    ///
    /// - Parameters:
    ///   - value: The integer value to store in the key-value store.
    ///   - defaultName: The key with which to associate with the value.
    public func set(_ value: Int, forKey defaultName: String) {
        setValue(Int64(value), forKey: defaultName)
    }
    
    /// Returns the integer value associated with the specified key.
    ///
    /// - Parameter defaultName: A key in the current key-value store.
    ///
    /// - Returns: The integer value associated with the specified key. If the specified key does not exist, this method returns 0.
    public func integer(forKey defaultName: String) -> Int {
        return Int(longLong(forKey: defaultName))
    }
    
    /// Returns a publisher that emits the value associated with the specified key whenever it changes.
    ///
    /// - Parameter key: The key whose value to observe.
    ///
    /// - Returns: A publisher that emits the value associated with the specified key whenever it changes.
    public func publisher(forKey key: String) -> AnyPublisher<Any?, Never> {
        let notificationPublisher = NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: self)
            .map { _ in self.object(forKey: key) }
        let initialValuePublisher = Just(self.object(forKey: key))
        return initialValuePublisher.merge(with: notificationPublisher).eraseToAnyPublisher()
    }
}
