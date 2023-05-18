//
//  DCSettingsManager.swift
//
//  Created by David Caddy on 25/4/2023.
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
/// Example usage:
///
/// ```swift
/// let manager = DCSettingsManager.shared
///
/// // Configure the manager with setting groups
/// manager.configure {
///     DCSettingGroup(label: "General") {
///         DCSetting(key: "darkMode", defaultValue: false)
///     }
/// }
///
/// // Access and modify a setting
/// let darkMode = manager.bool(forKey: "darkMode")
/// manager.set(!darkMode, forKey: "darkMode")
/// ```
public class DCSettingsManager {
    
    /// A shared instance of `DCSettingsManager`.
    public static let shared = DCSettingsManager()
    
    private(set) var groups: [DCSettingGroup] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    public init() {}
    
    /// Configures the manager with an array of setting groups.
    ///
    /// - Parameter settingGroups: An array of `DCSettingGroup` values representing the setting groups to be managed by the manager.
    public func configure(_ settingGroups: [DCSettingGroup]) {
        groups = settingGroups
        for group in groups {
            for setting in group.settings {
                let store = setting.store ?? group.store
                setting.store = store
                setting.refresh()
            }
        }
    }
    
    /// Configures the manager with a result builder that produces an array of setting groups.
    ///
    /// - Parameter builder: A result builder that produces an array of `DCSettingGroup` values representing the setting groups to be managed by the manager.
    public func configure(@DCSettingGroupsBuilder _ builder: () -> [DCSettingGroup]) {
        configure(builder())
    }
    
    /// Sets the value for a setting with the specified key.
    ///
    /// - Parameters:
    ///   - value: The value to set for the setting.
    ///   - key: The key of the setting to set the value for.
    ///
    /// - Returns: A boolean value indicating whether or not the value was successfully set. Returns `true` if successful, otherwise returns `false`.
    @discardableResult public func set<ValueType>(_ value: ValueType, forKey key: DCKeyRepresentable) -> Bool where ValueType: Equatable {
        if let setting = setting(forKey: key) as? DCSetting<ValueType> {
            setting.value = value
            return true
        }
        return false
    }

    /// Returns the setting with the specified key.
    ///
    /// - Parameter key: The key of the desired setting.
    ///
    /// - Returns: The desired `(any DCSettable)` if it exists, otherwise returns `nil`.
    public func setting(forKey key: DCKeyRepresentable) -> (any DCSettable)? {
        let existingSettings = groups.flatMap({ $0.settings })
        return existingSettings.first(where: { $0.key == key.keyValue })
    }
    
    /// Returns the value for a setting with the specified key.
    ///
    /// - Parameter key: The key of the desired setting value.
    ///
    /// - Returns: The desired value if it exists, otherwise returns `nil`.
    public func value<ValueType>(forKey key: DCKeyRepresentable) -> ValueType? where ValueType: Equatable {
        let setting = setting(forKey: key) as? DCSetting<ValueType>
        return setting?.value
    }
    
    /// Returns the represented value for a setting with the specified key.
    ///
    /// This method is useful when working with settings that have raw representable values such as enums or option sets. It attempts to convert
    /// the raw value of the setting to its represented value and returns it.
    ///
    /// - Parameter key: The key of the desired setting value.
    ///
    /// - Returns: The desired represented value if it exists and can be converted, otherwise returns `nil`.
    public func representedValue<ValueType>(forKey key: DCKeyRepresentable) -> ValueType? where ValueType: RawRepresentable, ValueType.RawValue: Equatable {
        if let settingRawValue: ValueType.RawValue = value(forKey: key), let option = ValueType(rawValue: settingRawValue)  {
            return option
        }
        return nil
    }
    
    /// Returns a binding to the value for a setting with the specified key.
    ///
    /// - Parameter key: The key of the desired setting value.
    ///
    /// - Returns: A binding to the desired value if it exists, otherwise returns `nil`.
    public func valueBinding<ValueType>(forKey key: DCKeyRepresentable) -> Binding<ValueType>? where ValueType: Equatable {
        if let setting = setting(forKey: key) as? DCSetting<ValueType> {
            return Binding {
                setting.value
            } set: { newValue in
                setting.value = newValue
            }
        }
        return nil
    }
    
    /// Returns a boolean value for a setting with the specified key.
    ///
    /// - Parameter key: The key of the desired setting value.
    ///
    /// - Returns: The desired boolean value if it exists, otherwise returns `false`.
    public func bool(forKey key: DCKeyRepresentable) -> Bool {
        return value(forKey: key) ?? false
    }
    
    /// Returns an integer value for a setting with the specified key.
    ///
    /// - Parameter key: The key of the desired setting value.
    ///
    /// - Returns: The desired integer value if it exists, otherwise returns `0`.
    public func int(forKey key: DCKeyRepresentable) -> Int {
        return value(forKey: key) ?? 0
    }
    
    /// Returns a double value for a setting with the specified key.
    ///
    /// - Parameter key: The key of the desired setting value.
    ///
    /// - Returns: The desired double value if it exists, otherwise returns `0.0`.
    public func double(forKey key: DCKeyRepresentable) -> Double {
        return value(forKey: key) ?? 0.0
    }
    
    /// Returns a string value for a setting with the specified key.
    ///
    /// - Parameter key: The key of the desired setting value.
    ///
    /// - Returns: The desired string value if it exists, otherwise returns an empty string.
    public func string(forKey key: DCKeyRepresentable) -> String {
        return value(forKey: key) ?? ""
    }
    
    /// Returns a date value for a setting with the specified key.
    ///
    /// - Parameter key: The key of the desired setting value.
    ///
    /// - Returns: The desired date value if it exists, otherwise returns a distant past date.
    public func date(forKey key: DCKeyRepresentable) -> Date {
        return value(forKey: key) ?? .distantPast
    }
    
    /// Returns a color value for a setting with the specified key.
    ///
    /// - Parameter key: The key of the desired setting value.
    ///
    /// - Returns: The desired color value if it exists, otherwise returns gray.
    public func color(forKey key: DCKeyRepresentable) -> Color {
        return value(forKey: key) ?? .gray
    }
}
