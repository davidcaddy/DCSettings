//
//  DCSettingGroupTests.swift
//
//  Created by David Caddy on 17/5/2023.
//

import XCTest
@testable import DCSettings

class DCSettingGroupTests: XCTestCase {
    
    var store: DCSettingStore!
    var setting1: DCSetting<String>!
    var setting2: DCSetting<Int>!
    var group: DCSettingGroup!
    
    override func setUp() {
        super.setUp()
        store = .custom(backingStore: MockStore())
        setting1 = DCSetting(key: "testKey1", defaultValue: "defaultValue1", store: store)
        setting2 = DCSetting(key: "testKey2", defaultValue: 0, store: store)
        group = DCSettingGroup {
            setting1
            setting2
        }
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testInitWithSettings() {
        XCTAssertEqual(group.settings.count, 2)
    }
    
    func testLabel() {
        let newGroup = group.label("newLabel")
        XCTAssertEqual(newGroup.label, "newLabel")
    }
}
