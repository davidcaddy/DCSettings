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

    @Test func settingForKey() throws {
        let setting = try #require(manager.setting(forKey: "key1") as? DCSetting<String>)

        #expect(setting.value == "value1")
        #expect(manager.setting(forKey: "nonExistentKey") == nil)
    }

    @Test func valueForKey() {
        let value: String? = manager.value(forKey: "key1")

        #expect(value == "value1")
        #expect((manager.value(forKey: "nonExistentKey") as String?) == nil)
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
