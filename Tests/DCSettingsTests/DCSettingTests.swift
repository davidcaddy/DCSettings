//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import XCTest
@testable import DCSettings
import Combine

@MainActor final class DCSettingTests: XCTestCase {

    private struct CodableValue: Codable, Equatable {
        let name: String
        let count: Int
    }

    private final class LegacySettable: DCSettable {
        let label: String? = nil
        let key = "legacy"
        var value = 1
        let configuation: DCSettingConfiguration<Int>? = DCSettingConfiguration(options: nil, bounds: nil, step: 1)
        var store: DCSettingStore?

        func refresh() {}
    }

    private var store: DCSettingStore!
    private var backingStore: MockStore!
    private var setting: DCSetting<String>!
    private var cancellables: Set<AnyCancellable> = []

    override func setUp() async throws {
        try await super.setUp()
        backingStore = MockStore()
        store = .custom(backingStore: backingStore)
        setting = DCSetting(key: "testKey", defaultValue: "defaultValue", store: store)
        cancellables = []
    }

    func testInitWithDefaultValue() {
        XCTAssertEqual(setting.value, "defaultValue")
    }

    func testValueChange() {
        setting.value = "newValue"

        XCTAssertEqual(setting.value, "newValue")
    }

    func testRefresh() {
        backingStore.set("anotherValue", forKey: "testKey")
        setting.refresh()

        XCTAssertEqual(setting.value, "anotherValue")
    }

    func testInitWithOptions() {
        let options = ["option1", "option2", "option3"]
        let setting = DCSetting(key: "testKey", store: store, options: options, defaultIndex: 1)

        XCTAssertEqual(setting?.value, "option2")
    }

    func testInitWithBounds() {
        let setting = DCSetting(key: "testKey", defaultValue: 5, store: store, lowerBound: 0, upperBound: 10)

        XCTAssertEqual(setting.value, 5)
        XCTAssertEqual(setting.configuration?.bounds, DCValueBounds(lowerBound: 0, upperBound: 10))
    }

    func testConfigurationCompatibilityForLegacySettableConformer() {
        let setting = LegacySettable()

        XCTAssertEqual(setting.configuration?.step, 1)
    }

    func testValueBinding() {
        let binding = setting.valueBinding()
        binding.wrappedValue = "newValue"

        XCTAssertEqual(setting.value, "newValue")
    }

    func testStoreSet() {
        setting.value = "newValue"

        XCTAssertEqual(backingStore?.storage["testKey"] as? String, setting.value)
    }

    func testRefreshNotifiesObserversWhenValueChanges() {
        let valueDidRefresh = expectation(description: "Setting refresh emitted a change")

        setting.objectWillChange
            .sink {
                XCTAssertEqual(self.setting.value, "anotherValue")
                valueDidRefresh.fulfill()
            }
            .store(in: &cancellables)

        backingStore.storage["testKey"] = "anotherValue"
        setting.refresh()

        wait(for: [valueDidRefresh], timeout: 1.0)
        XCTAssertEqual(setting.value, "anotherValue")
    }

    func testCodableCustomStoreRefreshRoundTrip() {
        let storedValue = CodableValue(name: "stored", count: 42)
        let defaultValue = CodableValue(name: "default", count: 0)
        let setting = DCSetting(key: "codableKey", defaultValue: defaultValue, store: store)

        setting.value = storedValue

        XCTAssertTrue(backingStore.storage["codableKey"] is Data)

        let refreshedSetting = DCSetting(key: "codableKey", defaultValue: defaultValue, store: store)
        refreshedSetting.refresh()

        XCTAssertEqual(refreshedSetting.value, storedValue)
    }

    func testCodableCustomStorePublisherRoundTrip() {
        let defaultValue = CodableValue(name: "default", count: 0)
        let updatedValue = CodableValue(name: "updated", count: 7)
        let setting = DCSetting(key: "codableKey", defaultValue: defaultValue, store: store)
        let valueDidChange = expectation(description: "Codable value update was decoded")

        setting.refresh()
        setting.objectWillChange
            .sink {
                valueDidChange.fulfill()
            }
            .store(in: &cancellables)

        store.set(updatedValue, forKey: "codableKey")

        wait(for: [valueDidChange], timeout: 1.0)
        XCTAssertEqual(setting.value, updatedValue)
    }
}
