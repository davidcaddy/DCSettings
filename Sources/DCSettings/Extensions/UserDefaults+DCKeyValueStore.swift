//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import Foundation
import Combine

extension UserDefaults: DCKeyValueStore {
    
    /// Returns a publisher that emits the value associated with the specified key whenever it changes.
    ///
    /// - Parameter key: The key for the value to observe.
    ///
    /// - Returns: A publisher that emits the value associated with the specified key whenever it changes.
    public func publisher(forKey key: String) -> AnyPublisher<Any?, Never> {
        let notificationPublisher = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification, object: self)
            .map { _ in self.object(forKey: key) }
        let initialValuePublisher = Just(self.object(forKey: key))
        return initialValuePublisher.merge(with: notificationPublisher).eraseToAnyPublisher()
    }
}
