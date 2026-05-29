//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import SwiftUI

#if !os(tvOS)

/// Supplies custom SwiftUI views for individual settings inside a `DCSettingsView`.
///
/// Conform to this protocol and implement `content(for:)` to override the default control
/// for selected settings. Return `nil` for settings that should fall back to the default view.
@MainActor public protocol DCSettingViewProviding {

    /// The type of view returned by `content(for:)`.
    associatedtype Content: View

    /// Returns a custom view for the given setting, or `nil` to use the default control.
    ///
    /// - Parameter setting: The setting to render.
    func content(for setting: any DCSettable) -> Content?
}

/// A `DCSettingViewProviding` that never supplies a custom view.
///
/// Use this when you only want the package's default controls for every setting.
public struct DCDefaultViewProvider: DCSettingViewProviding {

    /// Creates a new `DCDefaultViewProvider` instance.
    public init() {}

    /// Always returns `nil`, so every setting uses its default control.
    public func content(for setting: any DCSettable) -> EmptyView? {
        return nil
    }
}

#endif
