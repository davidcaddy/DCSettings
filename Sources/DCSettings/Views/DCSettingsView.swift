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
/// Supported types as standard are: `Bool`, `Int`, `Double`, `String`, `Date` and `Color`.
@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 9.0, visionOS 1.0, *)
public struct DCSettingsView<Provider: DCSettingViewProviding, S: ListStyle>: View {
    
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
    /// The settings manager is required, while the filter and content provider are optional.
    ///
    /// - Parameters:
    ///   - settingsManager: A `DCSettingsManager` instance used to manage the settings.
    ///   The default value is the `.shared` singleton instance.
    ///   - filter: A `Filter` value used to filter the displayed settings. The default value is `nil`.
    ///   - contentProvider: A `DCSettingViewProviding` instance used to provide custom views for individual settings.
    ///   The default value is an instance of `DCDefaultViewProvider`.
    ///   - listStyle: A `ListStyle` value used to set the style of the list. The default value is platform-dependent.
    #if os(macOS)
        public init(settingsManager: DCSettingsManager = .shared, filter: Filter? = nil, contentProvider: Provider? = DCDefaultViewProvider(), listStyle: S = SidebarListStyle()) {
            self.settingsManager = settingsManager
            self.filter = filter
            self.contentProvider = contentProvider
            self.listStyle = listStyle
        }
    #else
        public init(settingsManager: DCSettingsManager = .shared, filter: Filter? = nil, contentProvider: Provider? = DCDefaultViewProvider(), listStyle: S = InsetGroupedListStyle()) {
            self.settingsManager = settingsManager
            self.filter = filter
            self.contentProvider = contentProvider
            self.listStyle = listStyle
        }
    #endif
    
    public var body: some View {
        List(settingsManager.groups) { group in
            if !hiddenKeys.contains(group.key.keyValue) {
                Section(group.label?.sentenceFormatted ?? "") {
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
                }
            }
        }
        .listStyle(listStyle)
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 9.0, visionOS 1.0, *)
struct DCSettingsView_Previews: PreviewProvider {

    static var previews: some View {
        DCSettingsView()
    }
}
