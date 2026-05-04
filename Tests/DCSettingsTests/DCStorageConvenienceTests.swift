//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import XCTest
import SwiftUI
import Combine
@testable import DCSettings

@MainActor final class DCStorageConvenienceTests: XCTestCase {

    private enum TestMode: String {
        case list
        case grid
    }

    private struct ColorComponents: Codable {
        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
        let opacity: CGFloat
    }

    private struct StoredLayout: Codable, Equatable {
        let name: String
        let columns: Int
    }

    private var cancellables: Set<AnyCancellable> = []

    override func tearDown() async throws {
        cancellables = []
        try await super.tearDown()
    }

    func testColorCodableRoundTrip() throws {
        let components = ColorComponents(red: 0.25, green: 0.5, blue: 0.75, opacity: 0.6)
        let color = Color(red: components.red, green: components.green, blue: components.blue, opacity: components.opacity)

        let encodedColor = try JSONEncoder().encode(color)
        let decodedColor = try JSONDecoder().decode(Color.self, from: encodedColor)
        let encodedDecodedColor = try JSONEncoder().encode(decodedColor)
        let decodedComponents = try JSONDecoder().decode(ColorComponents.self, from: encodedDecodedColor)

        XCTAssertEqual(decodedComponents.red, components.red, accuracy: 0.001)
        XCTAssertEqual(decodedComponents.green, components.green, accuracy: 0.001)
        XCTAssertEqual(decodedComponents.blue, components.blue, accuracy: 0.001)
        XCTAssertEqual(decodedComponents.opacity, components.opacity, accuracy: 0.001)
    }

    func testUserDefaultsValuePublisherEmitsInitialAndChangedValue() {
        let suiteName = "DCStorageConvenienceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let valueDidChange = expectation(description: "UserDefaults value changed")
        var receivedValues: [String?] = []

        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        defaults.valuePublisher(forKey: "layout")
            .sink { value in
                receivedValues.append(value as? String)
                if receivedValues.count == 2 {
                    valueDidChange.fulfill()
                }
            }
            .store(in: &cancellables)

        defaults.set("grid", forKey: "layout")

        wait(for: [valueDidChange], timeout: 1.0)
        XCTAssertEqual(receivedValues, [nil, "grid"])
    }

    func testUserDefaultsValuePublisherDoesNotEmitDuplicateValueForUnrelatedChange() {
        let suiteName = "DCStorageConvenienceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let unrelatedChangeDidNotEmit = expectation(description: "Unrelated UserDefaults change did not emit")
        unrelatedChangeDidNotEmit.isInverted = true
        var receivedValues: [String?] = []

        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        defaults.set("list", forKey: "layout")

        defaults.valuePublisher(forKey: "layout")
            .sink { value in
                receivedValues.append(value as? String)
                if receivedValues.count > 1 {
                    unrelatedChangeDidNotEmit.fulfill()
                }
            }
            .store(in: &cancellables)

        defaults.set("dark", forKey: "theme")

        wait(for: [unrelatedChangeDidNotEmit], timeout: 0.2)
        XCTAssertEqual(receivedValues, ["list"])
    }

    func testUserDefaultsValuePublisherKeepsSuiteValuesIsolated() {
        let observedSuiteName = "DCStorageConvenienceTests.observed.\(UUID().uuidString)"
        let unrelatedSuiteName = "DCStorageConvenienceTests.unrelated.\(UUID().uuidString)"
        let observedDefaults = UserDefaults(suiteName: observedSuiteName)!
        let unrelatedDefaults = UserDefaults(suiteName: unrelatedSuiteName)!
        let unrelatedSuiteDidNotEmit = expectation(description: "Unrelated UserDefaults suite change did not emit")
        unrelatedSuiteDidNotEmit.isInverted = true
        var receivedValues: [String?] = []

        defer {
            observedDefaults.removePersistentDomain(forName: observedSuiteName)
            unrelatedDefaults.removePersistentDomain(forName: unrelatedSuiteName)
        }

        observedDefaults.set("list", forKey: "layout")

        observedDefaults.valuePublisher(forKey: "layout")
            .sink { value in
                receivedValues.append(value as? String)
                if receivedValues.count > 1 {
                    unrelatedSuiteDidNotEmit.fulfill()
                }
            }
            .store(in: &cancellables)

        unrelatedDefaults.set("grid", forKey: "layout")

        wait(for: [unrelatedSuiteDidNotEmit], timeout: 0.2)
        XCTAssertEqual(receivedValues, ["list"])
    }

    func testUserDefaultsSettingStoreTypedValuePublisherEmitsInitialAndChangedValue() {
        let suiteName = "DCStorageConvenienceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let store = DCSettingStore.userDefaults(suiteName: suiteName)
        let key = "layout"
        let valueDidChange = expectation(description: "Typed UserDefaults setting store value changed")
        var receivedValues: [String?] = []

        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        defaults.set("list", forKey: key)

        store.valuePublisher(forKey: key, as: String.self)
            .sink { value in
                receivedValues.append(value)
                if receivedValues.count == 2 {
                    valueDidChange.fulfill()
                }
            }
            .store(in: &cancellables)

        store.set("grid", forKey: key)

        wait(for: [valueDidChange], timeout: 1.0)
        XCTAssertEqual(receivedValues, ["list", "grid"])
    }

    func testUserDefaultsSettingStoreTypedValuePublisherDecodesCodableValues() {
        let suiteName = "DCStorageConvenienceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let store = DCSettingStore.userDefaults(suiteName: suiteName)
        let key = "layout"
        let firstValue = StoredLayout(name: "list", columns: 1)
        let secondValue = StoredLayout(name: "grid", columns: 3)
        let valueDidChange = expectation(description: "Typed UserDefaults setting store Codable value changed")
        var receivedValues: [StoredLayout?] = []

        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        XCTAssertTrue(store.set(firstValue, forKey: key))

        store.valuePublisher(forKey: key, as: StoredLayout.self)
            .sink { value in
                receivedValues.append(value)
                if receivedValues.count == 2 {
                    valueDidChange.fulfill()
                }
            }
            .store(in: &cancellables)

        XCTAssertTrue(store.set(secondValue, forKey: key))

        wait(for: [valueDidChange], timeout: 1.0)
        XCTAssertEqual(receivedValues, [firstValue, secondValue])
    }

    func testSettingStoreSetReturnsTrueWhenClearingCodableValue() {
        let suiteName = "DCStorageConvenienceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let store = DCSettingStore.userDefaults(suiteName: suiteName)
        let key = "layout"
        let value = StoredLayout(name: "list", columns: 1)

        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        XCTAssertTrue(store.set(value, forKey: key))
        XCTAssertEqual(store.object(forKey: key), value)

        XCTAssertTrue(store.set(nil as StoredLayout?, forKey: key))
        XCTAssertNil(store.object(forKey: key) as StoredLayout?)
    }

    func testUbiquitousValuePublisherIgnoresUnrelatedChangedKeysNotification() throws {
        #if os(watchOS)
            guard #available(watchOS 9.0, *) else {
                throw XCTSkip("NSUbiquitousKeyValueStore DCKeyValueStore conformance requires watchOS 9 or newer.")
            }
        #endif

        let store = NSUbiquitousKeyValueStore.default
        let key = "DCStorageConvenienceTests.\(UUID().uuidString).layout"
        let unrelatedNotificationDidNotEmit = expectation(description: "Unrelated ubiquitous notification did not emit")
        unrelatedNotificationDidNotEmit.isInverted = true
        var receivedValueCount = 0

        defer {
            store.removeObject(forKey: key)
        }

        store.valuePublisher(forKey: key)
            .sink { _ in
                receivedValueCount += 1
                if receivedValueCount > 1 {
                    unrelatedNotificationDidNotEmit.fulfill()
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.post(
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store,
            userInfo: [NSUbiquitousKeyValueStoreChangedKeysKey: ["unrelated"]]
        )

        wait(for: [unrelatedNotificationDidNotEmit], timeout: 0.2)
        XCTAssertEqual(receivedValueCount, 1)
    }

    func testStoredValueReadsAndWritesConfiguredSetting() {
        let manager = DCSettingsManager()
        let backingStore = MockStore()

        manager.configure {
            DCSettingGroup("Display", store: .custom(backingStore: backingStore)) {
                DCSetting(key: "title", defaultValue: "Initial")
            }
        }

        let storedValue = DCStoredValue<String>("title", settingsManager: manager)

        XCTAssertEqual(storedValue.wrappedValue, "Initial")

        storedValue.wrappedValue = "Updated"

        XCTAssertEqual(manager.string(forKey: "title"), "Updated")
        XCTAssertEqual(backingStore.storage["title"] as? String, "Updated")
    }

    func testStoredRepresentedValueReadsAndWritesRawRepresentableSetting() {
        let manager = DCSettingsManager()
        let backingStore = MockStore()

        manager.configure {
            DCSettingGroup("Display", store: .custom(backingStore: backingStore)) {
                DCSetting(key: "mode", defaultValue: TestMode.list.rawValue)
            }
        }

        let storedValue = DCStoredRepresentedValue<TestMode>("mode", settingsManager: manager)

        XCTAssertEqual(storedValue.wrappedValue, .list)

        storedValue.wrappedValue = .grid

        XCTAssertEqual(manager.string(forKey: "mode"), TestMode.grid.rawValue)
        XCTAssertEqual(backingStore.storage["mode"] as? String, TestMode.grid.rawValue)

        storedValue.wrappedValue = nil

        XCTAssertEqual(manager.string(forKey: "mode"), TestMode.grid.rawValue)
    }
}
