//
//  DCSettingGroup.swift
//
//  Created by David Caddy on 25/4/2023.
//

import Foundation

/// A group of settings that can be displayed together.
///
/// A `DCSettingGroup` is a collection of settings that can be displayed together in a user interface. Each setting group has a key, a label, and an array of settings.
///
/// You can create a `DCSettingGroup` using one of its initializers or by using the `@DCSettingsBuilder` result builder to build an array of settings.
///
/// - Note: The `DCSettingGroup` conforms to the `Identifiable` protocol and uses its key as its `id`.
public struct DCSettingGroup: Identifiable {
    
    /// The key for the setting group.
    let key: String
    
    /// The label for the setting group.
    let label: String?
    
    /// The store for the setting group.
    let store: DCSettingStore
    
    /// The array of settings in the setting group.
    let settings: [any DCSettable]
    
    /// The identifier for the setting group.
    public var id: String {
        return key
    }
    
    /// Creates a new setting group with the specified key, label, store, and settings.
    ///
    /// - Parameters:
    ///   - key: The key for the setting group. If not specified, a new UUID will be used as the key.
    ///   - label: The label for the setting group. Defaults to `nil`.
    ///   - store: The store for the setting group. Defaults to `.standard`.
    ///   - settings: An array of settings to include in the setting group.
    public init(key: DCKeyRepresentable?, label: String? = nil, store: DCSettingStore = .standard, settings: [any DCSettable]) {
        self.key = (key ?? UUID()).keyValue
        self.label = label
        self.store = store
        self.settings = settings
    }
    
    /// Creates a new setting group with the specified label, store, and settings.
    ///
    /// - Parameters:
    ///   - label: The label for the setting group. Defaults to `nil`.
    ///   - store: The store for the setting group. Defaults to `.standard`.
    ///   - settings: An array of settings to include in the setting group.
    public init(_ label: String? = nil, store: DCSettingStore = .standard, settings: [any DCSettable]) {
        self.init(key: nil, label: label, store: store, settings: settings)
    }
    
    /// Creates a new setting group with the specified key, label, store, and settings.
    ///
    /// - Parameters:
    ///   - key: The key for the setting group. If not specified, a new UUID will be used as the key.
    ///   - label: The label for the setting group. Defaults to `nil`.
    ///   - store: The store for the setting group. Defaults to `.standard`.
    ///   - builder: A closure that builds an array of settings using the `@DCSettingsBuilder` result builder.
    public init(key: DCKeyRepresentable?, label: String? = nil, store: DCSettingStore = .standard, @DCSettingsBuilder _ builder: () -> [any DCSettable]) {
        self.init(key: key, label: label, store: store, settings: builder())
    }
    
    /// Creates a new setting group with the specified label, store, and settings.
    ///
    /// - Parameters:
    ///   - label: The label for the setting group. Defaults to `nil`.
    ///   - store: The store for the setting group. Defaults to `.standard`.
    ///   - builder: A closure that builds an array of settings using the `@DCSettingsBuilder` result builder.
    public init(_ label: String? = nil, store: DCSettingStore = .standard, @DCSettingsBuilder _ builder: () -> [any DCSettable]) {
        self.init(key: nil, label: label, store: store, settings: builder())
    }
}

extension DCSettingGroup {
    
    /// Returns a new setting group with the specified label.
    ///
    /// - Parameter label: The new label for the setting group.
    public func label(_ label: String) -> DCSettingGroup {
        return DCSettingGroup(key: key, label: label, store: store, settings: settings)
    }
    
    /// Returns a new setting group with the specified store.
    ///
    /// - Parameter store: The new store for the setting group.
    public func store(_ store: DCSettingStore) -> DCSettingGroup {
        return DCSettingGroup(key: key, label: label, store: store, settings: settings)
    }
}

/// A result builder that builds an array of setting groups.
///
/// The `DCSettingGroupsBuilder` is a result builder that you can use to build an array of `DCSettingGroup` instances. You can use this result builder when configuring a `DCSettingsManager` instance.
///
/// Here's an example of how you can use the `DCSettingGroupsBuilder` to build an array of setting groups:
///
/// ```swift
/// let groups = DCSettingGroupsBuilder.buildBlock(
///     DCSettingGroup("General") {
///         DCSetting(key: "darkMode", defaultValue: false)
///     },
///     DCSettingGroup("Appearance") {
///         DCSetting(key: "fontSize", defaultValue: 14)
///         DCSetting(key: "fontFamily", defaultValue: "Helvetica")
///     }
/// )
/// ```
@resultBuilder
public struct DCSettingGroupsBuilder {
    
    /// Builds an array of setting groups from the provided setting group instances.
    ///
    /// - Parameter settings: The setting group instances to include in the array.
    /// - Returns: An array of setting groups.
    public static func buildBlock(_ settings: DCSettingGroup...) -> [DCSettingGroup] {
        settings
    }
}

