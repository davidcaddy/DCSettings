//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import Foundation
import Combine

@available(watchOS 9.0, *)
extension NSUbiquitousKeyValueStore: DCKeyValueStore {
    
    /// Sets the value of the specified key in the key-value store.
    ///
    /// - Parameters:
    ///   - value: The integer value to store in the key-value store.
    ///   - key: The key with which to associate with the value.
    public func set(_ value: Int, forKey key: String) {
        setValue(Int64(value), forKey: key)
    }
    
    /// Returns the integer value associated with the specified key.
    ///
    /// - Parameter key: A key in the current key-value store.
    ///
    /// - Returns: The integer value associated with the specified key. If the specified key does not exist, this method returns `0`.
    public func integer(forKey key: String) -> Int {
        return Int(exactly: longLong(forKey: key)) ?? 0
    }
    
    /// Returns a publisher that emits the value associated with the specified key whenever it changes.
    ///
    /// - Parameter key: The key for the value to observe.
    ///
    /// - Returns: A publisher that emits the value associated with the specified key whenever it changes.
    public func publisher(forKey key: String) -> AnyPublisher<Any?, Never> {
        let notificationPublisher = NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: self)
            .map { _ in self.object(forKey: key) }
        let initialValuePublisher = Just(self.object(forKey: key))
        return initialValuePublisher.merge(with: notificationPublisher).eraseToAnyPublisher()
    }
}
