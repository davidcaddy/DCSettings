//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import Testing
import SwiftUI
@testable import DCSettings

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
}
