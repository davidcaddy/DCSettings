//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import Foundation
import Combine

private func areUbiquitousKeyValueStoreObjectsEqual(_ lhs: Any?, _ rhs: Any?) -> Bool {
    switch (lhs, rhs) {
    case (nil, nil):
        return true
    case (nil, _), (_, nil):
        return false
    case let (lhs as NSObject, rhs as NSObject):
        return lhs.isEqual(rhs)
    default:
        return false
    }
}

@available(watchOS 9.0, *)
extension NSUbiquitousKeyValueStore: DCKeyValueStore {

    /// Sets the value of the specified key in the key-value store.
    ///
    /// - Parameters:
    ///   - value: The integer value to store in the key-value store.
    ///   - key: The key with which to associate with the value.
    public func set(_ value: Int, forKey key: String) {
        set(Int64(value), forKey: key)
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
    public func valuePublisher(forKey key: String) -> AnyPublisher<Any?, Never> {
        let notificationPublisher = NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: self)
            .filter { notification in
                guard let changedKeys = notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] else {
                    return true
                }

                return changedKeys.contains(key)
            }
            .map { _ in self.object(forKey: key) }
        let localWritePublisher = NotificationCenter.default.publisher(for: dcSettingsUbiquitousStoreDidChangeLocallyNotification)
            .filter { notification in
                notification.userInfo?[dcSettingsUbiquitousStoreChangedKey] as? String == key
            }
            .map { notification -> Any? in
                guard let value = notification.userInfo?[dcSettingsUbiquitousStoreChangedValue] else {
                    return self.object(forKey: key)
                }

                if value is NSNull {
                    return nil
                }

                return value
            }
        let initialValuePublisher = Just(self.object(forKey: key))
        return initialValuePublisher
            .merge(with: notificationPublisher)
            .merge(with: localWritePublisher)
            .removeDuplicates(by: areUbiquitousKeyValueStoreObjectsEqual)
            .eraseToAnyPublisher()
    }
}
