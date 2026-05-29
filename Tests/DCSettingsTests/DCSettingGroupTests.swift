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

        #expect(group.key == "General")
        #expect(group.label == "General")
        #expect(group.settings.count == 2)
    }

    @Test func nilLabelInitializerUsesGeneratedKey() {
        let group = DCSettingGroup(store: store, settings: [setting1])

        #expect(!group.key.isEmpty)
        #expect(group.label == nil)
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

    @Test func settingsBuilderSupportsEmptyBody() {
        let group = DCSettingGroup("Empty") {
        }

        #expect(group.settings.isEmpty)
    }

    @Test func settingsBuilderSupportsControlFlow() {
        let includeSecondSetting = false
        let loopedKeys = ["loop1", "loop2"]
        let selectedKey = "switch"

        let group = DCSettingGroup("Control Flow") {
            setting1

            if includeSecondSetting {
                setting2
            }
            else {
                DCSetting(key: "fallback", defaultValue: "fallback")
            }

            for key in loopedKeys {
                DCSetting(key: key, defaultValue: key)
            }

            switch selectedKey {
            case "switch":
                DCSetting(key: "switch", defaultValue: "switch")
            default:
                DCSetting(key: "default", defaultValue: "default")
            }
        }

        #expect(group.settings.map(\.key) == ["testKey1", "fallback", "loop1", "loop2", "switch"])
    }

    @Test func groupsBuilderSupportsControlFlow() {
        let includeAppearance = false
        let selectedGroup = "Labs"

        let manager = DCSettingsManager()
        manager.configure {
            DCSettingGroup("General", settings: [setting1])

            if includeAppearance {
                DCSettingGroup("Appearance", settings: [setting2])
            }
            else {
                DCSettingGroup("Fallback", settings: [])
            }

            for label in ["Advanced", "Debug"] {
                DCSettingGroup(label, settings: [])
            }

            switch selectedGroup {
            case "Labs":
                DCSettingGroup("Labs", settings: [])
            default:
                DCSettingGroup("Other", settings: [])
            }
        }

        #expect(manager.groups.map(\.label) == ["General", "Fallback", "Advanced", "Debug", "Labs"])
    }

    @Test func groupsBuilderSupportsEmptyBody() {
        let manager = DCSettingsManager()

        manager.configure {
        }

        #expect(manager.groups.isEmpty)
    }
}
