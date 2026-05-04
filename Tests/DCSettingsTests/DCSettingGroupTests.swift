//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
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

    func testKeyLabelAndID() {
        let group = DCSettingGroup(key: "general", label: "General", store: store, settings: [setting1])

        XCTAssertEqual(group.key, "general")
        XCTAssertEqual(group.id, "general")
        XCTAssertEqual(group.label, "General")
    }

    func testLabelInitializerCreatesGroupWithSettings() {
        let group = DCSettingGroup("General", store: store, settings: [setting1, setting2])

        XCTAssertEqual(group.label, "General")
        XCTAssertEqual(group.settings.count, 2)
    }

    func testStoreModifierReturnsCopyWithNewStore() {
        let newStore = DCSettingStore.custom(backingStore: MockStore())

        let updatedGroup = group.store(newStore)

        XCTAssertEqual(updatedGroup.key, group.key)
        XCTAssertEqual(updatedGroup.label, group.label)
        XCTAssertEqual(updatedGroup.settings.count, group.settings.count)
    }

    func testGroupsBuilderBuildsGroups() {
        let groups = DCSettingGroupsBuilder.buildBlock(
            DCSettingGroup("General", settings: [setting1]),
            DCSettingGroup("Appearance", settings: [setting2])
        )

        XCTAssertEqual(groups.map(\.label), ["General", "Appearance"])
    }
}
