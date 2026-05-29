//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import SwiftUI
import Testing
@testable import DCSettings

#if !os(tvOS)

@Suite @MainActor struct DCSettingsViewTests {

    private struct CustomViewProvider: DCSettingViewProviding {
        func content(for setting: any DCSettable) -> Text? {
            return nil
        }
    }

    @Test func defaultInitializerUsesDefaultProviderAndPlatformListStyle() {
        #if os(macOS)
            let view: DCSettingsView<DCDefaultViewProvider, SidebarListStyle> = DCSettingsView()
        #elseif os(watchOS)
            let view: DCSettingsView<DCDefaultViewProvider, DefaultListStyle> = DCSettingsView()
        #else
            let view: DCSettingsView<DCDefaultViewProvider, InsetGroupedListStyle> = DCSettingsView()
        #endif

        #expect(!String(describing: type(of: view)).isEmpty)
    }

    @Test func customProviderInitializerUsesPlatformListStyle() {
        #if os(macOS)
            let view: DCSettingsView<CustomViewProvider, SidebarListStyle> = DCSettingsView(contentProvider: CustomViewProvider())
        #elseif os(watchOS)
            let view: DCSettingsView<CustomViewProvider, DefaultListStyle> = DCSettingsView(contentProvider: CustomViewProvider())
        #else
            let view: DCSettingsView<CustomViewProvider, InsetGroupedListStyle> = DCSettingsView(contentProvider: CustomViewProvider())
        #endif

        #expect(!String(describing: type(of: view)).isEmpty)
    }

    @Test func customListStyleInitializerUsesDefaultProvider() {
        let view: DCSettingsView<DCDefaultViewProvider, PlainListStyle> = DCSettingsView(listStyle: PlainListStyle())

        #expect(!String(describing: type(of: view)).isEmpty)
    }

    @Test func filterSeparatesGroupAndSettingKeys() {
        #expect(DCSettingsView<DCDefaultViewProvider, PlainListStyle>.Filter.excludeGroups(["General"]) != .excludeSettings(["General"]))
        #expect(DCSettingsView<DCDefaultViewProvider, PlainListStyle>.Filter.exclude(groupKeys: ["General"], settingKeys: ["theme"]) == .exclude(groupKeys: ["General"], settingKeys: ["theme"]))
    }

    @Test func excludeSettingsFilterSkipsGroupsWithNoVisibleSettings() {
        let manager = DCSettingsManager()
        manager.configure(groups: [
            DCSettingGroup("General", store: .custom(backingStore: MockStore())) {
                DCSetting(key: "hiddenSetting", defaultValue: true, label: "Hidden Setting")
            },
            DCSettingGroup("Advanced", store: .custom(backingStore: MockStore())) {
                DCSetting(key: "visibleSetting", defaultValue: true, label: "Visible Setting")
            }
        ])

        let view: DCSettingsView<DCDefaultViewProvider, PlainListStyle> = DCSettingsView(settingsManager: manager, filter: .excludeSettings(["hiddenSetting"]), listStyle: PlainListStyle())

        #expect(view.visibleGroups.map(\.key) == ["Advanced"])
        #expect(view.visibleGroups.flatMap { group in group.settings.map { $0.key } } == ["visibleSetting"])
    }

    @Test func labelledFilterSkipsGroupsWithNoLabelledSettings() {
        let manager = DCSettingsManager()
        manager.configure(groups: [
            DCSettingGroup("General", store: .custom(backingStore: MockStore())) {
                DCSetting(key: "unlabelledSetting", defaultValue: true)
            },
            DCSettingGroup("Advanced", store: .custom(backingStore: MockStore())) {
                DCSetting(key: "labelledSetting", defaultValue: true, label: "Labelled Setting")
            }
        ])

        let view: DCSettingsView<DCDefaultViewProvider, PlainListStyle> = DCSettingsView(settingsManager: manager, filter: .labelled, listStyle: PlainListStyle())

        #expect(view.visibleGroups.map(\.key) == ["Advanced"])
        #expect(view.visibleGroups.flatMap { group in group.settings.map { $0.key } } == ["labelledSetting"])
    }

    @Test func defaultViewProviderReturnsNilContent() {
        let provider = DCDefaultViewProvider()
        let setting = DCSetting(key: "showImages", defaultValue: true)

        #expect(provider.content(for: setting) == nil)
    }
}

#endif
