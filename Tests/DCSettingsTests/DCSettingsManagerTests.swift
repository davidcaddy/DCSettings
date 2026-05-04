//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import XCTest
@testable import DCSettings
import SwiftUI
import Combine

@MainActor class DCSettingsManagerTests: XCTestCase {

    private enum TestEnum: String, Equatable, CaseIterable {
        case case1
        case case2
    }

    private var backingStore: MockStore!
    private var store: DCSettingStore!
    private var manager: DCSettingsManager!
    private var cancellables: Set<AnyCancellable> = []

    override func setUp() async throws {
        try await super.setUp()
        backingStore = MockStore()
        store = .custom(backingStore: backingStore)
        manager = DCSettingsManager()
        cancellables = []

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

    func testConfigureWithSettingGroups() {
        XCTAssertEqual(manager.groups.count, 2)
        XCTAssertEqual(manager.groups[0].label, "Group 1")
        XCTAssertEqual(manager.groups[1].label, "Group 2")
    }

    func testSetAndGetValue() {
        XCTAssertTrue(manager.bool(forKey: "key3"))

        manager.set(false, forKey: "key3")

        XCTAssertFalse(manager.bool(forKey: "key3"))
    }

    func testConfigure() {
        XCTAssertEqual(manager.groups.count, 2)
        XCTAssertEqual(manager.groups.first?.settings.count, 2)
        XCTAssertEqual(manager.groups.last?.settings.count, 5)
    }

    func testSet() {
        XCTAssertTrue(manager.set("newValue", forKey: "key1"))
        XCTAssertEqual(backingStore.storage["key1"] as? String, "newValue")
        XCTAssertFalse(manager.set("newValue", forKey: "nonExistentKey"))
    }

    func testSettingForKey() {
        let setting = manager.setting(forKey: "key1") as? DCSetting<String>

        XCTAssertNotNil(setting)
        XCTAssertEqual(setting?.value, "value1")
        XCTAssertNil(manager.setting(forKey: "nonExistentKey"))
    }

    func testValueForKey() {
        let value: String? = manager.value(forKey: "key1")

        XCTAssertEqual(value, "value1")
        XCTAssertNil(manager.value(forKey: "nonExistentKey") as String?)
    }

    func testValuePublisherEmitsCurrentAndChangedValue() {
        let valuesDidEmit = expectation(description: "Value publisher emitted current and changed values")
        var receivedValues: [String] = []

        manager.valuePublisher(forKey: "key1")?
            .sink { value in
                receivedValues.append(value)
                if receivedValues.count == 2 {
                    valuesDidEmit.fulfill()
                }
            }
            .store(in: &cancellables)

        manager.set("newValue", forKey: "key1")

        wait(for: [valuesDidEmit], timeout: 1.0)
        XCTAssertEqual(receivedValues, ["value1", "newValue"])
    }

    func testRepresentedValueForKey() {
        let value: TestEnum? = manager.representedValue(forKey: "key4")

        XCTAssertEqual(value, TestEnum.case1)
        XCTAssertNil(manager.representedValue(forKey: "nonExistentKey") as TestEnum?)
    }

    func testRepresentedValuePublisherEmitsCurrentAndChangedValue() {
        let valuesDidEmit = expectation(description: "Represented value publisher emitted current and changed values")
        var receivedValues: [TestEnum?] = []

        manager.representedValuePublisher(forKey: "key4")?
            .sink { value in
                receivedValues.append(value)
                if receivedValues.count == 2 {
                    valuesDidEmit.fulfill()
                }
            }
            .store(in: &cancellables)

        manager.set(TestEnum.case2.rawValue, forKey: "key4")

        wait(for: [valuesDidEmit], timeout: 1.0)
        XCTAssertEqual(receivedValues, [.case1, .case2])
    }

    func testValueBindingForKey() {
        let binding = manager.valueBinding(forKey: "key1") as Binding<String>?

        XCTAssertNotNil(binding)

        binding?.wrappedValue = "newValue"

        XCTAssertEqual(backingStore.storage["key1"] as? String, "newValue")
        XCTAssertNil(manager.valueBinding(forKey: "nonExistentKey") as Binding<String>?)
    }

    func testBoolForKey() {
        XCTAssertTrue(manager.bool(forKey: "key3"))
        XCTAssertFalse(manager.bool(forKey: "nonExistentKey"))
    }

    func testIntForKey() {
        XCTAssertTrue(manager.int(forKey: "key2") == 2)
        XCTAssertTrue(manager.int(forKey: "nonExistentKey") == 0)
    }

    func testDoubleForKey() {
        XCTAssertTrue(manager.double(forKey: "key5") == 5.0)
        XCTAssertTrue(manager.double(forKey: "nonExistentKey") == 0.0)
    }

    func testStringForKey() {
        XCTAssertEqual(manager.string(forKey: "key7"), "value2")
        XCTAssertEqual(manager.string(forKey: "nonExistentKey"), "")
    }

    func testDateForKey() {
        XCTAssertEqual(manager.date(forKey: "key6"), Date.distantFuture)
        XCTAssertEqual(manager.date(forKey: "nonExistentKey"), .distantPast)
    }
}
