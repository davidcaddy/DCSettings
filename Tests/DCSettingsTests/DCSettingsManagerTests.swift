//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import Testing
@testable import DCSettings
import SwiftUI
import Combine

@Suite @MainActor struct DCSettingsManagerTests {

    private enum TestEnum: String, Equatable, CaseIterable {
        case case1
        case case2
    }

    @MainActor private final class CustomSettable<ValueType: Equatable>: DCSettable {
        let label: String?
        let key: String
        let configuration: DCSettingConfiguration<ValueType>?
        var store: DCSettingStore?
        var value: ValueType {
            willSet {
                if value != newValue {
                    objectWillChange.send()
                }
            }
        }

        init(key: String, value: ValueType, label: String? = nil, configuration: DCSettingConfiguration<ValueType>? = nil) {
            self.key = key
            self.value = value
            self.label = label
            self.configuration = configuration
        }

        func refresh() {}
    }

    private let backingStore: MockStore
    private let store: DCSettingStore
    private let manager: DCSettingsManager

    init() {
        backingStore = MockStore()
        store = .custom(backingStore: backingStore)
        manager = DCSettingsManager()

        manager.configure {
            DCSettingGroup("Group 1", store: store) {
                DCSetting(key: "key1", defaultValue: "value1")
                DCSetting(key: "key2", defaultValue: 2)
            }
            DCSettingGroup("Group 2", store: store) {
                DCSetting(key: "key3", defaultValue: true)
                DCSetting(key: "key4", defaultValue: TestEnum.case1.rawValue)
                DCSetting(key: "key5", defaultValue: 5.0)
                DCSetting(key: "key6", defaultValue: Date.distantFuture)
                DCSetting(key: "key7", defaultValue: "value2")
            }
        }
    }

    @Test func configureWithSettingGroups() {
        #expect(manager.groups.count == 2)
        #expect(manager.groups[0].label == "Group 1")
        #expect(manager.groups[1].label == "Group 2")
    }

    @Test func setAndGetValue() {
        #expect(manager.bool(forKey: "key3"))

        manager.set(false, forKey: "key3")

        #expect(!manager.bool(forKey: "key3"))
    }

    @Test func configure() {
        #expect(manager.groups.count == 2)
        #expect(manager.groups.first?.settings.count == 2)
        #expect(manager.groups.last?.settings.count == 5)
    }

    @Test func set() {
        #expect(manager.set("newValue", forKey: "key1"))
        #expect(backingStore.storage["key1"] as? String == "newValue")
        #expect(!manager.set("newValue", forKey: "nonExistentKey"))
    }

    @Test func setReturnsFalseForMismatchedValueType() {
        #expect(!manager.set(42, forKey: "key1"))
        #expect(manager.string(forKey: "key1") == "value1")
        #expect(backingStore.storage["key1"] == nil)
    }

    @Test func setReturnsFalseForInvalidConfiguredValue() {
        let manager = DCSettingsManager()

        manager.configure {
            DCSettingGroup("Validation", store: store) {
                DCSetting(key: "boundedKey", defaultValue: 5, lowerBound: 0, upperBound: 10)
            }
        }

        #expect(!manager.set(11, forKey: "boundedKey"))
        #expect(manager.int(forKey: "boundedKey") == 5)
        #expect(backingStore.storage["boundedKey"] == nil)
    }

    @Test func configureReplacesCachedSettings() {
        manager.configure {
            DCSettingGroup("Replacement", store: store) {
                DCSetting(key: "replacementKey", defaultValue: "replacement")
            }
        }

        #expect(manager.setting(forKey: "key1") == nil)
        #expect(manager.string(forKey: "replacementKey") == "replacement")
    }

    @Test func configureReResolvesInheritedGroupStoreForReusedSetting() {
        let firstBackingStore = MockStore()
        let secondBackingStore = MockStore()
        let setting = DCSetting(key: "reusedKey", defaultValue: "initial")
        let manager = DCSettingsManager()

        manager.configure {
            DCSettingGroup("First", store: .custom(backingStore: firstBackingStore)) {
                setting
            }
        }

        #expect(setting.store == nil)
        setting.value = "first"

        manager.configure {
            DCSettingGroup("Second", store: .custom(backingStore: secondBackingStore)) {
                setting
            }
        }

        #expect(setting.store == nil)
        setting.value = "second"

        #expect(firstBackingStore.storage["reusedKey"] as? String == "first")
        #expect(secondBackingStore.storage["reusedKey"] as? String == "second")
    }

    @Test func groupStoreModifierReResolvesInheritedStoreForReusedSetting() {
        let firstBackingStore = MockStore()
        let secondBackingStore = MockStore()
        let setting = DCSetting(key: "modifiedGroupKey", defaultValue: "initial")
        let group = DCSettingGroup("Group", store: .custom(backingStore: firstBackingStore)) {
            setting
        }
        let manager = DCSettingsManager()

        manager.configure(groups: [group])
        #expect(setting.store == nil)
        setting.value = "first"

        manager.configure(groups: [group.store(.custom(backingStore: secondBackingStore))])
        #expect(setting.store == nil)
        setting.value = "second"

        #expect(firstBackingStore.storage["modifiedGroupKey"] as? String == "first")
        #expect(secondBackingStore.storage["modifiedGroupKey"] as? String == "second")
    }

    @Test func explicitSettingStoreContinuesToOverrideGroupStoreAfterReconfigure() {
        let explicitBackingStore = MockStore()
        let firstGroupBackingStore = MockStore()
        let secondGroupBackingStore = MockStore()
        let setting = DCSetting(key: "explicitStoreKey", defaultValue: "initial", store: .custom(backingStore: explicitBackingStore))
        let manager = DCSettingsManager()

        manager.configure {
            DCSettingGroup("First", store: .custom(backingStore: firstGroupBackingStore)) {
                setting
            }
        }

        setting.value = "first"

        manager.configure {
            DCSettingGroup("Second", store: .custom(backingStore: secondGroupBackingStore)) {
                setting
            }
        }

        setting.value = "second"

        #expect(explicitBackingStore.storage["explicitStoreKey"] as? String == "second")
        #expect(firstGroupBackingStore.storage["explicitStoreKey"] == nil)
        #expect(secondGroupBackingStore.storage["explicitStoreKey"] == nil)
    }

    @Test func settingForKey() throws {
        let setting = try #require(manager.setting(forKey: "key1") as? DCSetting<String>)

        #expect(setting.value == "value1")
        #expect(manager.setting(forKey: "nonExistentKey") == nil)
    }

    @Test func duplicateSettingKeysAreDetectedBeforeConfiguration() {
        let groups = DCSettingGroupsBuilder.buildBlock(
            DCSettingGroup("Group 1", store: store) {
                DCSetting(key: "duplicateKey", defaultValue: "first")
            },
            DCSettingGroup("Group 2", store: store) {
                DCSetting(key: "duplicateKey", defaultValue: "second")
            }
        )

        #expect(DCSettingsManager.duplicateSettingKeys(in: groups) == ["duplicateKey"])
    }

    @Test func duplicateGroupKeysAreDetectedBeforeConfiguration() {
        let groups = DCSettingGroupsBuilder.buildBlock(
            DCSettingGroup("Duplicate", store: store) {
                DCSetting(key: "first", defaultValue: "first")
            },
            DCSettingGroup("Duplicate", store: store) {
                DCSetting(key: "second", defaultValue: "second")
            }
        )

        #expect(DCSettingsManager.duplicateGroupKeys(in: groups) == ["Duplicate"])
    }

    @Test func valueForKey() {
        let value: String? = manager.value(forKey: "key1")

        #expect(value == "value1")
        #expect((manager.value(forKey: "nonExistentKey") as String?) == nil)
    }

    @Test func accessorsSupportCustomSettableConformers() throws {
        let customSetting = CustomSettable(key: "customKey", value: "customValue")
        let manager = DCSettingsManager()

        manager.configure {
            DCSettingGroup("Custom") {
                customSetting
            }
        }

        #expect(manager.value(forKey: "customKey") == "customValue")
        #expect(manager.set("updatedValue", forKey: "customKey"))
        #expect(customSetting.value == "updatedValue")

        let binding = try #require(manager.valueBinding(forKey: "customKey") as Binding<String>?)
        binding.wrappedValue = "boundValue"

        #expect(customSetting.value == "boundValue")
    }

    @Test func setRejectsInvalidConfiguredValueForCustomSettableConformers() {
        let customSetting = CustomSettable(
            key: "customKey",
            value: "first",
            configuration: DCSettingConfiguration(options: [
                DCSettingOption(value: "first"),
                DCSettingOption(value: "second")
            ])
        )
        let manager = DCSettingsManager()

        manager.configure {
            DCSettingGroup("Custom") {
                customSetting
            }
        }

        #expect(!manager.set("third", forKey: "customKey"))
        #expect(customSetting.value == "first")
    }

    @Test func valuePublisherEmitsCurrentAndChangedValue() async {
        var receivedValues: [String] = []
        var cancellables: Set<AnyCancellable> = []

        manager.valuePublisher(forKey: "key1")?
            .sink { value in
                receivedValues.append(value)
            }
            .store(in: &cancellables)

        manager.set("newValue", forKey: "key1")

        #expect(await waitUntil { receivedValues.count == 2 })
        #expect(receivedValues == ["value1", "newValue"])
    }

    @Test func valuePublisherSupportsCustomSettableConformers() async {
        let customSetting = CustomSettable(key: "customKey", value: "customValue")
        let manager = DCSettingsManager()
        var receivedValues: [String] = []
        var cancellables: Set<AnyCancellable> = []

        manager.configure {
            DCSettingGroup("Custom") {
                customSetting
            }
        }

        manager.valuePublisher(forKey: "customKey")?
            .sink { value in
                receivedValues.append(value)
            }
            .store(in: &cancellables)

        manager.set("updatedValue", forKey: "customKey")

        #expect(await waitUntil { receivedValues.count == 2 })
        #expect(receivedValues == ["customValue", "updatedValue"])
    }

    @Test func representedValueForKey() {
        let value: TestEnum? = manager.representedValue(forKey: "key4")

        #expect(value == TestEnum.case1)
        #expect((manager.representedValue(forKey: "nonExistentKey") as TestEnum?) == nil)
    }

    @Test func representedValuePublisherEmitsCurrentAndChangedValue() async {
        var receivedValues: [TestEnum?] = []
        var cancellables: Set<AnyCancellable> = []

        manager.representedValuePublisher(forKey: "key4")?
            .sink { value in
                receivedValues.append(value)
            }
            .store(in: &cancellables)

        manager.set(TestEnum.case2.rawValue, forKey: "key4")

        #expect(await waitUntil { receivedValues.count == 2 })
        #expect(receivedValues == [.case1, .case2])
    }

    @Test func valueBindingForKey() throws {
        let binding = try #require(manager.valueBinding(forKey: "key1") as Binding<String>?)

        binding.wrappedValue = "newValue"

        #expect(backingStore.storage["key1"] as? String == "newValue")
        #expect((manager.valueBinding(forKey: "nonExistentKey") as Binding<String>?) == nil)
    }

    @Test func boolForKey() {
        #expect(manager.bool(forKey: "key3"))
        #expect(!manager.bool(forKey: "nonExistentKey"))
    }

    @Test func intForKey() {
        #expect(manager.int(forKey: "key2") == 2)
        #expect(manager.int(forKey: "nonExistentKey") == 0)
    }

    @Test func doubleForKey() {
        #expect(manager.double(forKey: "key5") == 5.0)
        #expect(manager.double(forKey: "nonExistentKey") == 0.0)
    }

    @Test func stringForKey() {
        #expect(manager.string(forKey: "key7") == "value2")
        #expect(manager.string(forKey: "nonExistentKey") == "")
    }

    @Test func dateForKey() {
        #expect(manager.date(forKey: "key6") == Date.distantFuture)
        #expect(manager.date(forKey: "nonExistentKey") == .distantPast)
    }
}
