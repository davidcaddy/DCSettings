//
//  DCSettingsManagerTests.swift
//
//  Created by Dave Caddy on 17/5/2023.
//

import XCTest
@testable import DCSettings
import SwiftUI

class DCSettingsManagerTests: XCTestCase {
    
    private enum TestEnum: String, Equatable, CaseIterable {
        case case1
    }
    
    private var backingStore: MockStore!
    private var store: DCSettingStore!
    private var manager: DCSettingsManager!
    
    override func setUp() {
        super.setUp()
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
    
    func testRepresentedValueForKey() {
        let value: TestEnum? = manager.representedValue(forKey: "key4")
        
        XCTAssertEqual(value, TestEnum.case1)
        XCTAssertNil(manager.representedValue(forKey: "nonExistentKey") as TestEnum?)
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
