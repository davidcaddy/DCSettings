//
//  DCSettingsView.swift
//
//  Created by David Caddy on 26/4/2023.
//

import SwiftUI

/// A view that displays a list of grouped settings.
///
/// `DCSettingsView` is a view that displays a list of grouped settings. The view takes a `DCSettingsManager` instance as an argument and displays a list of all settings managed by that instance.
///
/// The view uses a `DCSettingViewProviding` instance to provide custom views for individual settings. If no custom view is available for a specific setting, a default view will be used if the setting's value is a supported type.
/// Supported types as standard are: `Bool`, `Int`,  `Double`, `String`, `Date` and `Color`.
@available(iOS 15.0, *)
public struct DCSettingsView<Provider: DCSettingViewProviding>: View {
    
    private let settingsManager: DCSettingsManager
    
    private var includeSettingsWithoutLabels: Bool
    
    private var hiddenKeys: [String]
    
    private let contentProvider: Provider?

    /// Initializes a new `DCSettingsView` instance with the specified settings manager, inclusion flag, hidden keys, and content provider.
    ///
    /// This initializer creates a new instance of `DCSettingsView` with the specified settings manager, inclusion flag, hidden keys, and content provider. The settings manager is required, while the inclusion flag, hidden keys, and content provider are optional.
    ///
    /// - Parameters:
    ///   - settingsManager: A `DCSettingsManager` instance used to manage the settings. The default value is the `.shared` singleton instance.
    ///   - includeSettingsWithoutLabels: A boolean value indicating whether to include settings without labels in the list. The default value is `false`.
    ///   - hiddenKeys: An array of keys representing settings that should be hidden from the list. The default value is an empty array.
    ///   - contentProvider: A `DCSettingViewProviding` instance used to provide custom views for individual settings. The default value is an instance of `DCDefaultViewProvider`.
    public init(settingsManager: DCSettingsManager = .shared, includeSettingsWithoutLabels: Bool = false, hiddenKeys: [DCKeyRepresentable] = [], contentProvider: Provider? = DCDefaultViewProvider()) {
        self.settingsManager = settingsManager
        self.includeSettingsWithoutLabels = includeSettingsWithoutLabels
        self.hiddenKeys = hiddenKeys.map({ $0.keyValue })
        self.contentProvider = contentProvider
    }
    
    public var body: some View {
        List(settingsManager.groups) { group in
            if !hiddenKeys.contains(group.key.keyValue) {
                Section(group.label ?? "") {
                    ForEach(group.settings, id: \.key) { setting in
                        if ((setting.label != nil) || includeSettingsWithoutLabels) && !hiddenKeys.contains(setting.key.keyValue) {
                            if let content = contentProvider?.content(for: setting), !(content is EmptyView) {
                                content
                                    .animation(nil)
                            }
                            else {
                                DCSettingView(setting)
                                    .animation(nil)
                            }
                        }
                    }
                }
            }
        }
        .animation(.default)
    }
}

@available(iOS 15.0, *)
struct DCSettingsView_Previews: PreviewProvider {

    static var previews: some View {
        DCSettingsView()
    }
}
