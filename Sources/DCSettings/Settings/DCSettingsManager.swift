//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import Foundation
import SwiftUI
import Combine

/// `DCSettingsManager` is a class that manages the settings for an application.
///
/// It provides a way to configure and access settings through a set of `DCSettingGroup`s.
/// Each group contains a set of `DCSettable` settings that can be accessed and modified.
///
/// `DCSettingsManager` also provides convenience methods for accessing and modifying settings directly.
///
/// Configure a manager before presenting `DCSettingsView` or constructing `DCStoredValue`
/// and `DCStoredRepresentedValue` wrappers. Reconfiguring a manager replaces its lookup
/// state, but already-created views and stored-value wrappers keep observing the setting
/// instances they were created with.
///
/// Example usage:
///
/// ```swift
/// let manager = DCSettingsManager.shared
///
/// // Configure the manager with setting groups
/// manager.configure {
    ///     DCSettingGroup(key: "general", label: "General") {
    ///         DCSetting(key: "darkMode", defaultValue: false)
    ///     }
/// }
///
/// // Access and modify a setting
/// let darkMode = manager.bool(forKey: "darkMode")
/// manager.set(!darkMode, forKey: "darkMode")
/// ```
@MainActor public class DCSettingsManager {

    /// A shared instance of `DCSettingsManager`.
    public static let shared = DCSettingsManager()

    public private(set) var groups: [DCSettingGroup] = []

    private var settingsByKey: [String: any DCSettable] = [:]

    public init() {}

    /// Configures the manager with an array of setting groups.
    ///
    /// Call this before presenting settings UI or constructing stored-value property wrappers.
    /// Calling it again replaces manager lookup state, but does not update already-created
    /// `DCSettingsView`, `DCStoredValue`, or `DCStoredRepresentedValue` instances.
    ///
    /// - Parameter settingGroups: An array of `DCSettingGroup` values representing the setting groups to be managed by the manager.
    public func configure(groups settingGroups: [DCSettingGroup]) {
        let duplicateGroupKeys = Self.duplicateGroupKeys(in: settingGroups)
        precondition(duplicateGroupKeys.isEmpty, "DCSettingsManager group keys must be unique. Duplicate keys: \(duplicateGroupKeys.joined(separator: ", ")).")

        let duplicateKeys = Self.duplicateSettingKeys(in: settingGroups)
        precondition(duplicateKeys.isEmpty, "DCSettingsManager setting keys must be unique. Duplicate keys: \(duplicateKeys.joined(separator: ", ")).")

        groups = settingGroups
        settingsByKey = [:]
        for group in groups {
            for setting in group.settings {
                let store = setting.store ?? group.store
                setting.store = store
                setting.refresh()
                if settingsByKey[setting.key] == nil {
                    settingsByKey[setting.key] = setting
                }
            }
        }
    }

    static func duplicateGroupKeys(in groups: [DCSettingGroup]) -> [String] {
        var seenKeys: Set<String> = []
        var duplicateKeys: Set<String> = []

        for group in groups {
            if !seenKeys.insert(group.key).inserted {
                duplicateKeys.insert(group.key)
            }
        }

        return duplicateKeys.sorted()
    }

    static func duplicateSettingKeys(in groups: [DCSettingGroup]) -> [String] {
        var seenKeys: Set<String> = []
        var duplicateKeys: Set<String> = []

        for group in groups {
            for setting in group.settings {
                if !seenKeys.insert(setting.key).inserted {
                    duplicateKeys.insert(setting.key)
                }
            }
        }

        return duplicateKeys.sorted()
    }

    /// Configures the manager with a result builder that produces an array of setting groups.
    ///
    /// Call this before presenting settings UI or constructing stored-value property wrappers.
    /// Calling it again replaces manager lookup state, but does not update already-created
    /// `DCSettingsView`, `DCStoredValue`, or `DCStoredRepresentedValue` instances.
    ///
    /// - Parameter builder: A result builder that produces an array of `DCSettingGroup` values
    /// representing the setting groups to be managed by the manager.
    public func configure(@DCSettingGroupsBuilder _ builder: @MainActor () -> [DCSettingGroup]) {
        configure(groups: builder())
    }

    /// Sets the value for a setting with the specified key.
    ///
    /// - Parameters:
    ///   - value: The value to set for the setting.
    ///   - key: The key for a setting that has been configured by the manager.
    ///
    /// - Returns: A boolean value indicating whether or not the value was successfully set. Returns `true` if successful, otherwise returns `false`.
    @discardableResult public func set<ValueType>(_ value: ValueType, forKey key: DCKeyRepresentable) -> Bool where ValueType: Equatable {
        setting(forKey: key)?._setTypedValue(value) ?? false
    }

    /// Returns the setting with the specified key.
    ///
    /// - Parameter key: The key of the desired setting.
    ///
    /// - Returns: The desired `(any DCSettable)` if it has been configured by the manager, otherwise returns `nil`.
    public func setting(forKey key: DCKeyRepresentable) -> (any DCSettable)? {
        return settingsByKey[key.keyValue]
    }

    /// Returns the value for a setting with the specified key.
    ///
    /// - Parameter key: The key of the desired setting value.
    ///
    /// - Returns: The desired value if it has been configured by the manager, otherwise returns `nil`.
    public func value<ValueType>(forKey key: DCKeyRepresentable) -> ValueType? where ValueType: Equatable {
        setting(forKey: key)?._typedValue(as: ValueType.self)
    }

    /// Returns the represented value for a setting with the specified key.
    ///
    /// This method is useful when working with settings that have raw representable values such as enums or option sets.
    /// It attempts to convert the raw value of the setting to its represented value and returns it.
    ///
    /// - Parameter key: The key of the desired setting value.
    ///
    /// - Returns: The desired represented value if it has been configured by the manager and can be converted, otherwise returns `nil`.
    public func representedValue<ValueType>(forKey key: DCKeyRepresentable) -> ValueType? where ValueType: RawRepresentable, ValueType.RawValue: Equatable {
        if let settingRawValue: ValueType.RawValue = value(forKey: key), let option = ValueType(rawValue: settingRawValue) {
            return option
        }
        return nil
    }

    /// Returns a binding to the value for a setting with the specified key.
    ///
    /// - Parameter key: The key of the desired setting value.
    ///
    /// - Returns: A binding to the desired value if it has been configured by the manager, otherwise returns `nil`.
    public func valueBinding<ValueType>(forKey key: DCKeyRepresentable) -> Binding<ValueType>? where ValueType: Equatable {
        setting(forKey: key)?._typedBinding(as: ValueType.self)
    }

    /// Returns a publisher that emits the current value of the setting with the specified key.
    ///
    /// - Parameters:
    ///   - key: The key for the value to observe.
    ///
    /// - Returns: An `AnyPublisher` that emits the current value of the setting with the specified key.
    /// Returns `nil` if the setting is not found or the value is not of the expected type.
    public func valuePublisher<ValueType>(forKey key: DCKeyRepresentable) -> AnyPublisher<ValueType, Never>? where ValueType: Equatable {
        setting(forKey: key)?._typedPublisher(as: ValueType.self)
    }

    /// Returns a publisher that emits the represented value of the setting with the specified key.
    ///
    /// - Parameters:
    ///   - key: The key for the value to observe.
    ///
    /// - Returns: An `AnyPublisher` that emits the represented value of the setting with the specified key.
    /// Returns `nil` if the setting is not found or the represented value cannot be initialized from the raw value.
    public func representedValuePublisher<ValueType>(forKey key: DCKeyRepresentable) -> AnyPublisher<ValueType?, Never>? where ValueType: RawRepresentable, ValueType.RawValue: Equatable {
        guard let publisher = setting(forKey: key)?._typedPublisher(as: ValueType.RawValue.self) else {
            return nil
        }

        return publisher
            .map { ValueType(rawValue: $0) }
            .eraseToAnyPublisher()
    }

    /// Returns a boolean value for the setting with the specified key.
    ///
    /// - Parameter key: The key of the desired setting value.
    ///
    /// - Returns: The desired boolean value if it has been configured by the manager, otherwise returns `false`.
    public func bool(forKey key: DCKeyRepresentable) -> Bool {
        return value(forKey: key) ?? false
    }

    /// Returns an integer value for the setting with the specified key.
    ///
    /// - Parameter key: The key of the desired setting value.
    ///
    /// - Returns: The desired integer value if it has been configured by the manager, otherwise returns `0`.
    public func int(forKey key: DCKeyRepresentable) -> Int {
        return value(forKey: key) ?? 0
    }

    /// Returns a double value for the setting with the specified key.
    ///
    /// - Parameter key: The key of the desired setting value.
    ///
    /// - Returns: The desired double value if it has been configured by the manager, otherwise returns `0.0`.
    public func double(forKey key: DCKeyRepresentable) -> Double {
        return value(forKey: key) ?? 0.0
    }

    /// Returns a string value for the setting with the specified key.
    ///
    /// - Parameter key: The key of the desired setting value.
    ///
    /// - Returns: The desired string value if it has been configured by the manager, otherwise returns an empty string.
    public func string(forKey key: DCKeyRepresentable) -> String {
        return value(forKey: key) ?? ""
    }

    /// Returns a date value for the setting with the specified key.
    ///
    /// - Parameter key: The key of the desired setting value.
    ///
    /// - Returns: The desired date value if it has been configured by the manager, otherwise returns a distant past date.
    public func date(forKey key: DCKeyRepresentable) -> Date {
        return value(forKey: key) ?? .distantPast
    }

    /// Returns a color value for the setting with the specified key.
    ///
    /// - Parameter key: The key of the desired setting value.
    ///
    /// - Returns: The desired color value if it has been configured by the manager, otherwise returns `gray`.
    public func color(forKey key: DCKeyRepresentable) -> Color {
        return value(forKey: key) ?? .gray
    }
}
