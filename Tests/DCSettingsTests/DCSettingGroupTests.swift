//
//  DCSettingGroupTests.swift
//
//  Created by David Caddy on 17/5/2023.
//

import XCTest
@testable import DCSettings

class DCSettingGroupTests: XCTestCase {
    
    private var store: DCSettingStore!
    private var setting1: DCSetting<String>!
    private var setting2: DCSetting<Int>!
    private var group: DCSettingGroup!
    
    override func setUp() {
        super.setUp()
        store = .custom(backingStore: MockStore())
        setting1 = DCSetting(key: "testKey1", defaultValue: "defaultValue1")
        setting2 = DCSetting(key: "testKey2", defaultValue: 0)
        group = DCSettingGroup(store: store) {
            setting1
            setting2
        }
    }
    
    func testSettings() {
        XCTAssertEqual(group.settings.count, 2)
    }
}
