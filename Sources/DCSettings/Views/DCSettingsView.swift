//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import SwiftUI

/// A view that displays a list of grouped settings.
///
/// `DCSettingsView` is a view that displays a list of grouped settings.
/// The view takes a `DCSettingsManager` instance as an argument and displays a list of all settings managed by that instance.
///
/// The view uses a `DCSettingViewProviding` instance to provide custom views for individual settings.
/// If no custom view is available for a specific setting, a default view will be used if the setting's value is a supported type.
/// Supported types are: non-optional `Bool`, `Int`, `Double`, `String`, `Date` and `Color`.
@MainActor public struct DCSettingsView<Provider: DCSettingViewProviding, S: ListStyle>: View {

    /// An enumeration that defines the available filters for the settings view.
    public enum Filter: Equatable {

        /// A filter that includes only settings with labels.
        case labelled

        /// A filter that excludes settings with the specified keys.
        case excludeKeys([String])
    }

    private let settingsManager: DCSettingsManager
    private let filter: Filter?
    private let contentProvider: Provider?
    private let listStyle: S

    private var hiddenKeys: [String] {
        if case .excludeKeys(let keys) = filter {
            return keys
        }
        return []
    }

    /// Initializes a new `DCSettingsView` instance with the specified settings manager, filter, and content provider.
    ///
    /// This initializer creates a new instance of `DCSettingsView` with the specified settings manager, filter, and content provider.
    /// The settings manager defaults to the `.shared` singleton instance, while the filter is optional.
    ///
    /// - Parameters:
    ///   - settingsManager: A `DCSettingsManager` instance used to manage the settings.
    ///   The default value is the `.shared` singleton instance.
    ///   - filter: A `Filter` value used to filter the displayed settings. The default value is `nil`.
    ///   - contentProvider: A `DCSettingViewProviding` instance used to provide custom views for individual settings.
    ///   - listStyle: A `ListStyle` value used to set the style of the list.
    public init(settingsManager: DCSettingsManager = .shared, filter: Filter? = nil, contentProvider: Provider?, listStyle: S) {
        self.settingsManager = settingsManager
        self.filter = filter
        self.contentProvider = contentProvider
        self.listStyle = listStyle
    }

    public var body: some View {
        List(settingsManager.groups) { group in
            if !hiddenKeys.contains(group.key.keyValue) {
                Section {
                    ForEach(group.settings, id: \.key) { setting in
                        if ((setting.label != nil) || (filter != .labelled)) && !hiddenKeys.contains(setting.key.keyValue) {
                            if let content = contentProvider?.content(for: setting), !(content is EmptyView) {
                                content
                            }
                            else {
                                DCSettingView(setting)
                            }
                        }
                    }
                } header: {
                    Text(group.label?.sentenceFormatted ?? "")
                }
            }
        }
        .listStyle(listStyle)
    }
}

extension DCSettingsView where Provider == DCDefaultViewProvider {

    /// Initializes a new settings view with the default content provider and the specified list style.
    public init(settingsManager: DCSettingsManager = .shared, filter: Filter? = nil, listStyle: S) {
        self.init(settingsManager: settingsManager, filter: filter, contentProvider: DCDefaultViewProvider(), listStyle: listStyle)
    }
}

#if os(macOS)
extension DCSettingsView where S == SidebarListStyle {

    /// Initializes a new settings view with the platform default list style.
    public init(settingsManager: DCSettingsManager = .shared, filter: Filter? = nil, contentProvider: Provider?) {
        self.init(settingsManager: settingsManager, filter: filter, contentProvider: contentProvider, listStyle: SidebarListStyle())
    }
}

extension DCSettingsView where Provider == DCDefaultViewProvider, S == SidebarListStyle {

    /// Initializes a new settings view with the default content provider and platform default list style.
    public init(settingsManager: DCSettingsManager = .shared, filter: Filter? = nil) {
        self.init(settingsManager: settingsManager, filter: filter, contentProvider: DCDefaultViewProvider(), listStyle: SidebarListStyle())
    }
}
#elseif os(watchOS)
extension DCSettingsView where S == DefaultListStyle {

    /// Initializes a new settings view with the platform default list style.
    public init(settingsManager: DCSettingsManager = .shared, filter: Filter? = nil, contentProvider: Provider?) {
        self.init(settingsManager: settingsManager, filter: filter, contentProvider: contentProvider, listStyle: DefaultListStyle())
    }
}

extension DCSettingsView where Provider == DCDefaultViewProvider, S == DefaultListStyle {

    /// Initializes a new settings view with the default content provider and platform default list style.
    public init(settingsManager: DCSettingsManager = .shared, filter: Filter? = nil) {
        self.init(settingsManager: settingsManager, filter: filter, contentProvider: DCDefaultViewProvider(), listStyle: DefaultListStyle())
    }
}
#else
extension DCSettingsView where S == InsetGroupedListStyle {

    /// Initializes a new settings view with the platform default list style.
    public init(settingsManager: DCSettingsManager = .shared, filter: Filter? = nil, contentProvider: Provider?) {
        self.init(settingsManager: settingsManager, filter: filter, contentProvider: contentProvider, listStyle: InsetGroupedListStyle())
    }
}

extension DCSettingsView where Provider == DCDefaultViewProvider, S == InsetGroupedListStyle {

    /// Initializes a new settings view with the default content provider and platform default list style.
    public init(settingsManager: DCSettingsManager = .shared, filter: Filter? = nil) {
        self.init(settingsManager: settingsManager, filter: filter, contentProvider: DCDefaultViewProvider(), listStyle: InsetGroupedListStyle())
    }
}
#endif

struct DCSettingsView_Previews: PreviewProvider {

    static var previews: some View {
        DCSettingsView()
    }
}
