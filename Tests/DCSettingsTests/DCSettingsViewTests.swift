//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import XCTest
import SwiftUI
@testable import DCSettings

@MainActor final class DCSettingsViewTests: XCTestCase {

    private struct CustomViewProvider: DCSettingViewProviding {
        func content(for setting: any DCSettable) -> Text? {
            return nil
        }
    }

    func testDefaultInitializerUsesDefaultProviderAndPlatformListStyle() {
        #if os(macOS)
            let view: DCSettingsView<DCDefaultViewProvider, SidebarListStyle> = DCSettingsView()
        #elseif os(watchOS)
            let view: DCSettingsView<DCDefaultViewProvider, DefaultListStyle> = DCSettingsView()
        #else
            let view: DCSettingsView<DCDefaultViewProvider, InsetGroupedListStyle> = DCSettingsView()
        #endif

        XCTAssertNotNil(view)
    }

    func testCustomProviderInitializerUsesPlatformListStyle() {
        #if os(macOS)
            let view: DCSettingsView<CustomViewProvider, SidebarListStyle> = DCSettingsView(contentProvider: CustomViewProvider())
        #elseif os(watchOS)
            let view: DCSettingsView<CustomViewProvider, DefaultListStyle> = DCSettingsView(contentProvider: CustomViewProvider())
        #else
            let view: DCSettingsView<CustomViewProvider, InsetGroupedListStyle> = DCSettingsView(contentProvider: CustomViewProvider())
        #endif

        XCTAssertNotNil(view)
    }

    func testCustomListStyleInitializerUsesDefaultProvider() {
        let view: DCSettingsView<DCDefaultViewProvider, PlainListStyle> = DCSettingsView(listStyle: PlainListStyle())

        XCTAssertNotNil(view)
    }
}
