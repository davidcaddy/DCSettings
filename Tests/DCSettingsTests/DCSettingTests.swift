//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import Testing
import Foundation
@testable import DCSettings
import Combine

@Suite @MainActor struct DCSettingTests {

    private struct CodableValue: Codable, Equatable {
        let name: String
        let count: Int
    }

    private final class LegacySettable: DCSettable {
        let label: String? = nil
        let key = "legacy"
        var value = 1
        let configuration: DCSettingConfiguration<Int>? = DCSettingConfiguration(options: nil, bounds: nil, step: 1)
        var store: DCSettingStore?

        func refresh() {}
    }

    private let store: DCSettingStore
    private let backingStore: MockStore
    private let setting: DCSetting<String>

    init() {
        backingStore = MockStore()
        store = .custom(backingStore: backingStore)
        setting = DCSetting(key: "testKey", defaultValue: "defaultValue", store: store)
    }

    @Test func initWithDefaultValue() {
        #expect(setting.value == "defaultValue")
    }

    @Test func optionalValueTypesAreUnsupported() {
        #expect(DCSetting<String>.supportsValueType)
        #expect(!DCSetting<String?>.supportsValueType)
    }

    @Test func valueChange() {
        setting.value = "newValue"

        #expect(setting.value == "newValue")
    }

    @Test func optionSettingRejectsValuesOutsideConfiguredOptions() throws {
        let setting = try #require(DCSetting(key: "optionKey", store: store) {
            DCSettingOption(value: "first")
            DCSettingOption(value: "second")
        })

        setting.value = "third"

        #expect(setting.value == "first")
        #expect(backingStore.storage["optionKey"] == nil)
    }

    @Test func boundedSettingRejectsValuesOutsideConfiguredBounds() {
        let setting = DCSetting(key: "boundedKey", defaultValue: 5, store: store, lowerBound: 0, upperBound: 10)

        setting.value = 11

        #expect(setting.value == 5)
        #expect(backingStore.storage["boundedKey"] == nil)
    }

    @Test func refresh() {
        backingStore.set("anotherValue", forKey: "testKey")
        setting.refresh()

        #expect(setting.value == "anotherValue")
    }

    @Test func refreshIgnoresStoredValuesOutsideConfiguredOptions() throws {
        let setting = try #require(DCSetting(key: "optionKey", store: store) {
            DCSettingOption(value: "first")
            DCSettingOption(value: "second")
        })
        backingStore.storage["optionKey"] = "third"

        setting.refresh()

        #expect(setting.value == "first")
    }

    @Test func refreshIgnoresStoredValuesOutsideConfiguredBounds() {
        let setting = DCSetting(key: "boundedKey", defaultValue: 5, store: store, lowerBound: 0, upperBound: 10)
        backingStore.storage["boundedKey"] = 11

        setting.refresh()

        #expect(setting.value == 5)
    }

    @Test func initWithOptions() throws {
        let options = ["option1", "option2", "option3"]
        let setting = try #require(DCSetting(key: "testKey", store: store, options: options, defaultIndex: 1))

        #expect(setting.value == "option2")
    }

    @Test func initWithBounds() {
        let setting = DCSetting(key: "testKey", defaultValue: 5, store: store, lowerBound: 0, upperBound: 10)

        #expect(setting.value == 5)
        #expect(setting.configuration?.bounds == DCValueBounds(lowerBound: 0, upperBound: 10))
    }

    @Test func initWithBoundsStoresPositiveStep() {
        let setting = DCSetting(key: "testKey", defaultValue: 5, store: store, lowerBound: 0, upperBound: 10, step: 2)

        #expect(setting.configuration?.step == 2)
    }

    @Test func stepValidationRequiresPositiveNumericSteps() {
        #expect(DCSetting<Int>.isValidStep(nil))
        #expect(DCSetting<Int>.isValidStep(1))
        #expect(!DCSetting<Int>.isValidStep(0))
        #expect(!DCSetting<Int>.isValidStep(-1))
        #expect(DCSetting<Double>.isValidStep(0.1))
        #expect(!DCSetting<Double>.isValidStep(0.0))
        #expect(!DCSetting<Double>.isValidStep(.nan))
        #expect(!DCSetting<Double>.isValidStep(.infinity))
        #expect(DCSetting<Float>.isValidStep(0.1))
        #expect(!DCSetting<Float>.isValidStep(.infinity))
    }

    @Test func configurationPropertyIsAccessible() {
        let setting = LegacySettable()

        #expect(setting.configuration?.step == 1)
    }

    @Test func deprecatedConfiguationAliasForwardToConfiguration() {
        let setting = LegacySettable()

        #expect(setting.configuation?.step == setting.configuration?.step)
    }

    @Test func valueBinding() {
        let binding = setting.valueBinding()
        binding.wrappedValue = "newValue"

        #expect(setting.value == "newValue")
    }

    @Test func storeSet() {
        setting.value = "newValue"

        #expect(backingStore.storage["testKey"] as? String == setting.value)
    }

    @Test func refreshNotifiesObserversWhenValueChanges() async {
        var didRefresh = false
        var cancellables: Set<AnyCancellable> = []

        setting.objectWillChange
            .sink {
                didRefresh = true
            }
            .store(in: &cancellables)

        backingStore.storage["testKey"] = "anotherValue"
        setting.refresh()

        #expect(await waitUntil { didRefresh })
        #expect(setting.value == "anotherValue")
    }

    @Test func codableCustomStoreRefreshRoundTrip() {
        let storedValue = CodableValue(name: "stored", count: 42)
        let defaultValue = CodableValue(name: "default", count: 0)
        let setting = DCSetting(key: "codableKey", defaultValue: defaultValue, store: store)

        setting.value = storedValue

        #expect(backingStore.storage["codableKey"] is Data)

        let refreshedSetting = DCSetting(key: "codableKey", defaultValue: defaultValue, store: store)
        refreshedSetting.refresh()

        #expect(refreshedSetting.value == storedValue)
    }

    @Test func codableCustomStorePublisherRoundTrip() async {
        let defaultValue = CodableValue(name: "default", count: 0)
        let updatedValue = CodableValue(name: "updated", count: 7)
        let setting = DCSetting(key: "codableKey", defaultValue: defaultValue, store: store)
        var didChange = false
        var cancellables: Set<AnyCancellable> = []

        setting.refresh()
        setting.objectWillChange
            .sink {
                didChange = true
            }
            .store(in: &cancellables)

        store.set(updatedValue, forKey: "codableKey")

        #expect(await waitUntil { didChange })
        #expect(setting.value == updatedValue)
    }

    @Test func externalStoreUpdateDoesNotWriteValueBackToStore() async {
        setting.refresh()

        store.set("externalValue", forKey: "testKey")

        #expect(await waitUntil { setting.value == "externalValue" })
        #expect(backingStore.setCallCount(forKey: "testKey") == 1)
    }

    @Test func externalStoreUpdateIgnoresValuesOutsideConfiguredBounds() async {
        let setting = DCSetting(key: "boundedKey", defaultValue: 5, store: store, lowerBound: 0, upperBound: 10)
        setting.refresh()

        store.set(11, forKey: "boundedKey")

        #expect(!(await waitUntil(timeout: .milliseconds(100)) { setting.value == 11 }))
        #expect(setting.value == 5)
    }
}
