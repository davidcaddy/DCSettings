//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import Foundation
import Combine
import DCSettings

final class MockStore: DCKeyValueStore, @unchecked Sendable {
    enum SetMethod {
        case object
        case bool
        case int
        case double
    }

    var storage: [String: Any] = [:]
    private var setCounts: [String: Int] = [:]
    private var setMethods: [String: SetMethod] = [:]
    private let subject = PassthroughSubject<(String, Any?), Never>()

    func setCallCount(forKey key: String) -> Int {
        setCounts[key, default: 0]
    }

    func setMethod(forKey key: String) -> SetMethod? {
        setMethods[key]
    }

    func valuePublisher(forKey key: String) -> AnyPublisher<Any?, Never> {
        return subject.filter { $0.0 == key }.map { $0.1 }.eraseToAnyPublisher()
    }

    func set(_ value: Any?, forKey defaultName: String) {
        setCounts[defaultName, default: 0] += 1
        setMethods[defaultName] = .object
        storage[defaultName] = value
        subject.send((defaultName, value))
    }

    func object(forKey defaultName: String) -> Any? {
        return storage[defaultName]
    }

    func set(_ value: Bool, forKey defaultName: String) {
        setCounts[defaultName, default: 0] += 1
        setMethods[defaultName] = .bool
        storage[defaultName] = value
        subject.send((defaultName, value))
    }

    func bool(forKey defaultName: String) -> Bool {
        return storage[defaultName] as? Bool ?? false
    }

    func set(_ value: Int, forKey defaultName: String) {
        setCounts[defaultName, default: 0] += 1
        setMethods[defaultName] = .int
        storage[defaultName] = value
        subject.send((defaultName, value))
    }

    func integer(forKey defaultName: String) -> Int {
        return storage[defaultName] as? Int ?? 0
    }

    func set(_ value: Double, forKey defaultName: String) {
        setCounts[defaultName, default: 0] += 1
        setMethods[defaultName] = .double
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
