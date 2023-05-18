//
//  DCSettingsManagerTests.swift
//
//  Created by Dave Caddy on 17/5/2023.
//

import XCTest
@testable import DCSettings

class DCSettingsManagerTests: XCTestCase {
    var manager: DCSettingsManager!
    var store: DCSettingStore!
    
    override func setUp() {
        super.setUp()
        manager = DCSettingsManager()
        store = DCSettingStore.custom(backingStore: MockStore())
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    func testConfigureWithSettingGroups() {
        let setting1 = DCSetting(key: "setting1", defaultValue: false)
        let setting2 = DCSetting(key: "setting2", defaultValue: 0)
        let group1 = DCSettingGroup(key: nil, label: "Group 1", store: store, settings: [setting1])
        let group2 = DCSettingGroup(key: nil, label: "Group 2", store: store, settings: [setting2])
        manager.configure([group1, group2])

        XCTAssertEqual(manager.groups.count, 2)
        XCTAssertEqual(manager.groups[0].label, "Group 1")
        XCTAssertEqual(manager.groups[1].label, "Group 2")
    }

    func testSetAndGetValue() {
        let setting = DCSetting(key: "setting", defaultValue: false, store: store)
        let group = DCSettingGroup(key: nil, label: "Group", settings: [setting])
        manager.configure([group])

        XCTAssertEqual(manager.bool(forKey: "setting"), false)

        manager.set(true, forKey: "setting")

        XCTAssertEqual(manager.bool(forKey: "setting"), true)
    }
}
