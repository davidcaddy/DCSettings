//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import Testing
import SwiftUI
import Combine
@testable import DCSettings

@Suite @MainActor struct DCStorageConvenienceTests {

    private enum TestMode: String {
        case list
        case grid
    }

    private struct StoredLayout: Codable, Equatable {
        let name: String
        let columns: Int
    }

    #if canImport(UIKit) || canImport(AppKit)
    private struct ColorComponents: Codable {
        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
        let opacity: CGFloat
    }

    @Test func colorSettingStoreRoundTrip() throws {
        let components = ColorComponents(red: 0.25, green: 0.5, blue: 0.75, opacity: 0.6)
        let color = Color(red: components.red, green: components.green, blue: components.blue, opacity: components.opacity)
        let backingStore = MockStore()
        let store = DCSettingStore.custom(backingStore: backingStore)
        let key = "color"

        #expect(store.set(color, forKey: key))
        #expect(backingStore.storage[key] is Data)

        let decodedColor = try #require(store.object(forKey: key) as Color?)
        let encodedDecodedColor = try decodedColor.dcSettingsEncodedData()
        let decodedComponents = try JSONDecoder().decode(ColorComponents.self, from: encodedDecodedColor)

        #expect(abs(decodedComponents.red - components.red) <= 0.001)
        #expect(abs(decodedComponents.green - components.green) <= 0.001)
        #expect(abs(decodedComponents.blue - components.blue) <= 0.001)
        #expect(abs(decodedComponents.opacity - components.opacity) <= 0.001)
    }
    #endif

    @Test func userDefaultsValuePublisherEmitsInitialAndChangedValue() async throws {
        let suiteName = "DCStorageConvenienceTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        var receivedValues: [String?] = []
        var cancellables: Set<AnyCancellable> = []

        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        defaults.valuePublisher(forKey: "layout")
            .sink { value in
                receivedValues.append(value as? String)
            }
            .store(in: &cancellables)

        defaults.set("grid", forKey: "layout")

        #expect(await waitUntil { receivedValues.count == 2 })
        #expect(receivedValues == [nil, "grid"])
    }

    @Test func userDefaultsValuePublisherDoesNotEmitDuplicateValueForUnrelatedChange() async throws {
        let suiteName = "DCStorageConvenienceTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        var receivedValues: [String?] = []
        var cancellables: Set<AnyCancellable> = []

        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        defaults.set("list", forKey: "layout")

        defaults.valuePublisher(forKey: "layout")
            .sink { value in
                receivedValues.append(value as? String)
            }
            .store(in: &cancellables)

        defaults.set("dark", forKey: "theme")

        try? await Task.sleep(for: .milliseconds(200))
        #expect(receivedValues == ["list"])
    }

    @Test func userDefaultsValuePublisherKeepsSuiteValuesIsolated() async throws {
        let observedSuiteName = "DCStorageConvenienceTests.observed.\(UUID().uuidString)"
        let unrelatedSuiteName = "DCStorageConvenienceTests.unrelated.\(UUID().uuidString)"
        let observedDefaults = try #require(UserDefaults(suiteName: observedSuiteName))
        let unrelatedDefaults = try #require(UserDefaults(suiteName: unrelatedSuiteName))
        var receivedValues: [String?] = []
        var cancellables: Set<AnyCancellable> = []

        defer {
            observedDefaults.removePersistentDomain(forName: observedSuiteName)
            unrelatedDefaults.removePersistentDomain(forName: unrelatedSuiteName)
        }

        observedDefaults.set("list", forKey: "layout")

        observedDefaults.valuePublisher(forKey: "layout")
            .sink { value in
                receivedValues.append(value as? String)
            }
            .store(in: &cancellables)

        unrelatedDefaults.set("grid", forKey: "layout")

        try? await Task.sleep(for: .milliseconds(200))
        #expect(receivedValues == ["list"])
    }

    @Test func userDefaultsSettingStoreTypedValuePublisherEmitsInitialAndChangedValue() async throws {
        let suiteName = "DCStorageConvenienceTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let store = DCSettingStore.userDefaults(suiteName: suiteName)
        let key = "layout"
        var receivedValues: [String?] = []
        var cancellables: Set<AnyCancellable> = []

        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        defaults.set("list", forKey: key)

        store.valuePublisher(forKey: key, as: String.self)
            .sink { value in
                receivedValues.append(value)
            }
            .store(in: &cancellables)

        store.set("grid", forKey: key)

        #expect(await waitUntil { receivedValues.count == 2 })
        #expect(receivedValues == ["list", "grid"])
    }

    @Test func userDefaultsSettingStoreTypedValuePublisherDecodesCodableValues() async throws {
        let suiteName = "DCStorageConvenienceTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let store = DCSettingStore.userDefaults(suiteName: suiteName)
        let key = "layout"
        let firstValue = StoredLayout(name: "list", columns: 1)
        let secondValue = StoredLayout(name: "grid", columns: 3)
        var receivedValues: [StoredLayout?] = []
        var cancellables: Set<AnyCancellable> = []

        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        #expect(store.set(firstValue, forKey: key))

        store.valuePublisher(forKey: key, as: StoredLayout.self)
            .sink { value in
                receivedValues.append(value)
            }
            .store(in: &cancellables)

        #expect(store.set(secondValue, forKey: key))

        #expect(await waitUntil { receivedValues.count == 2 })
        #expect(receivedValues == [firstValue, secondValue])
    }

    @Test func settingStoreSetReturnsTrueWhenClearingCodableValue() throws {
        let suiteName = "DCStorageConvenienceTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let store = DCSettingStore.userDefaults(suiteName: suiteName)
        let key = "layout"
        let value = StoredLayout(name: "list", columns: 1)

        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        #expect(store.set(value, forKey: key))
        #expect(store.object(forKey: key) == value)

        #expect(store.set(nil as StoredLayout?, forKey: key))
        #expect((store.object(forKey: key) as StoredLayout?) == nil)
    }

    @Test func settingStoreGenericSetUsesTypedStandardScalarSetters() {
        let backingStore = MockStore()
        let store = DCSettingStore.custom(backingStore: backingStore)

        #expect(setGeneric(true, forKey: "bool", in: store))
        #expect(setGeneric(12, forKey: "int", in: store))
        #expect(setGeneric(1.25, forKey: "double", in: store))
        #expect(setGeneric("grid", forKey: "string", in: store))

        #expect(backingStore.setMethod(forKey: "bool") == .bool)
        #expect(backingStore.setMethod(forKey: "int") == .int)
        #expect(backingStore.setMethod(forKey: "double") == .double)
        #expect(backingStore.setMethod(forKey: "string") == .object)
    }

    @Test func ubiquitousValuePublisherIgnoresUnrelatedChangedKeysNotification() async {
        #if os(watchOS)
            if #unavailable(watchOS 9.0) {
                return
            }
        #endif

        let store = NSUbiquitousKeyValueStore.default
        let key = "DCStorageConvenienceTests.\(UUID().uuidString).layout"
        var receivedValueCount = 0
        var cancellables: Set<AnyCancellable> = []

        defer {
            store.removeObject(forKey: key)
        }

        store.valuePublisher(forKey: key)
            .sink { _ in
                receivedValueCount += 1
            }
            .store(in: &cancellables)

        NotificationCenter.default.post(
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store,
            userInfo: [NSUbiquitousKeyValueStoreChangedKeysKey: ["unrelated"]]
        )

        try? await Task.sleep(for: .milliseconds(200))
        #expect(receivedValueCount == 1)
    }

    @Test func ubiquitousStoreAcceptsIntegerValuesWithSettingKeys() {
        #if os(watchOS)
            if #unavailable(watchOS 9.0) {
                return
            }
        #endif

        let store = NSUbiquitousKeyValueStore.default
        let key = "DCStorageConvenienceTests.\(UUID().uuidString).integer"

        defer {
            store.removeObject(forKey: key)
        }

        store.set(42, forKey: key)
    }

    private func setGeneric<ValueType>(_ value: ValueType, forKey key: String, in store: DCSettingStore) -> Bool {
        store.set(value, forKey: key)
    }

    @Test func storedValueReadsAndWritesConfiguredSetting() {
        let manager = DCSettingsManager()
        let backingStore = MockStore()

        manager.configure {
            DCSettingGroup("Display", store: .custom(backingStore: backingStore)) {
                DCSetting(key: "title", defaultValue: "Initial")
            }
        }

        let storedValue = DCStoredValue<String>("title", settingsManager: manager)

        #expect(storedValue.wrappedValue == "Initial")

        storedValue.wrappedValue = "Updated"

        #expect(manager.string(forKey: "title") == "Updated")
        #expect(backingStore.storage["title"] as? String == "Updated")
    }

    @Test func storedRepresentedValueReadsAndWritesRawRepresentableSetting() {
        let manager = DCSettingsManager()
        let backingStore = MockStore()

        manager.configure {
            DCSettingGroup("Display", store: .custom(backingStore: backingStore)) {
                DCSetting(key: "mode", defaultValue: TestMode.list.rawValue)
            }
        }

        let storedValue = DCStoredRepresentedValue<TestMode>("mode", settingsManager: manager)

        #expect(storedValue.wrappedValue == .list)

        storedValue.wrappedValue = .grid

        #expect(manager.string(forKey: "mode") == TestMode.grid.rawValue)
        #expect(backingStore.storage["mode"] as? String == TestMode.grid.rawValue)

        storedValue.wrappedValue = nil

        #expect(manager.string(forKey: "mode") == TestMode.grid.rawValue)
    }
}
