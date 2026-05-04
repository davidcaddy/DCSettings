//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import Testing
@testable import DCSettings

@Suite @MainActor struct DCSettingGroupTests {

    private let store: DCSettingStore
    private let setting1: DCSetting<String>
    private let setting2: DCSetting<Int>
    private let group: DCSettingGroup

    init() {
        let store = DCSettingStore.custom(backingStore: MockStore())
        let setting1 = DCSetting(key: "testKey1", defaultValue: "defaultValue1")
        let setting2 = DCSetting(key: "testKey2", defaultValue: 0)

        self.store = store
        self.setting1 = setting1
        self.setting2 = setting2
        self.group = DCSettingGroup(store: store) {
            setting1
            setting2
        }
    }

    @Test func settings() {
        #expect(group.settings.count == 2)
    }

    @Test func keyLabelAndID() {
        let group = DCSettingGroup(key: "general", label: "General", store: store, settings: [setting1])

        #expect(group.key == "general")
        #expect(group.id == "general")
        #expect(group.label == "General")
    }

    @Test func labelInitializerCreatesGroupWithSettings() {
        let group = DCSettingGroup("General", store: store, settings: [setting1, setting2])

        #expect(group.label == "General")
        #expect(group.settings.count == 2)
    }

    @Test func storeModifierReturnsCopyWithNewStore() {
        let newStore = DCSettingStore.custom(backingStore: MockStore())

        let updatedGroup = group.store(newStore)

        #expect(updatedGroup.key == group.key)
        #expect(updatedGroup.label == group.label)
        #expect(updatedGroup.settings.count == group.settings.count)
    }

    @Test func groupsBuilderBuildsGroups() {
        let groups = DCSettingGroupsBuilder.buildBlock(
            DCSettingGroup("General", settings: [setting1]),
            DCSettingGroup("Appearance", settings: [setting2])
        )

        #expect(groups.map(\.label) == ["General", "Appearance"])
    }
}
