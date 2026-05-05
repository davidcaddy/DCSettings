//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import Foundation
import Combine
import DCSettings

class MockStore: DCKeyValueStore {
    var storage: [String: Any] = [:]
    private var setCounts: [String: Int] = [:]
    private let subject = PassthroughSubject<(String, Any?), Never>()

    func setCallCount(forKey key: String) -> Int {
        setCounts[key, default: 0]
    }

    func valuePublisher(forKey key: String) -> AnyPublisher<Any?, Never> {
        return subject.filter { $0.0 == key }.map { $0.1 }.eraseToAnyPublisher()
    }

    func set(_ value: Any?, forKey defaultName: String) {
        setCounts[defaultName, default: 0] += 1
        storage[defaultName] = value
        subject.send((defaultName, value))
    }

    func object(forKey defaultName: String) -> Any? {
        return storage[defaultName]
    }

    func set(_ value: Bool, forKey defaultName: String) {
        setCounts[defaultName, default: 0] += 1
        storage[defaultName] = value
        subject.send((defaultName, value))
    }

    func bool(forKey defaultName: String) -> Bool {
        return storage[defaultName] as? Bool ?? false
    }

    func set(_ value: Int, forKey defaultName: String) {
        setCounts[defaultName, default: 0] += 1
        storage[defaultName] = value
        subject.send((defaultName, value))
    }

    func integer(forKey defaultName: String) -> Int {
        return storage[defaultName] as? Int ?? 0
    }

    func set(_ value: Double, forKey defaultName: String) {
        setCounts[defaultName, default: 0] += 1
        storage[defaultName] = value
        subject.send((defaultName, value))
    }

    func double(forKey defaultName: String) -> Double {
        return storage[defaultName] as? Double ?? 0.0
    }

    func string(forKey defaultName: String) -> String? {
        return storage[defaultName] as? String
    }

    func synchronize() -> Bool {
        return true
    }
}
