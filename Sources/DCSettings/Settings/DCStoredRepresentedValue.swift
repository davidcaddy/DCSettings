//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import SwiftUI

/// A property wrapper that wraps the represented value of a setting stored in a `DCSettingStore`.
///
/// The `DCStoredRepresentedValue` property wrapper can be used to wrap a value that is stored in a `DCSettingStore`.
/// It attempts to convert the raw value of the setting to its represented value when being accessed, and does the inverse when being set.
/// This is useful when working with settings that have raw representable values such as enums or option sets.
///
/// When the wrapped value is accessed or modified, the value will be automatically loaded from or saved to the store using a `DCSetting` instance.
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
@propertyWrapper
public struct DCStoredRepresentedValue<ValueType>: DynamicProperty where ValueType: RawRepresentable, ValueType.RawValue: Equatable {
    
    @StateObject private var setting: DCSetting<ValueType.RawValue>

    /// The current represented value of the wrapped property.
    ///
    /// When this property is accessed or modified, the value will be automatically loaded from or saved to the store using the `DCSetting` instance.
    public var wrappedValue: ValueType? {
        get {
            ValueType(rawValue: setting.value)
        }
        nonmutating set {
            if let value = newValue {
                setting.value = value.rawValue
            }
        }
    }

    /// Initializes a new `DCStoredRepresentedValue` instance with the specified key and settings manager.
    ///
    /// This initializer creates a new instance of `DCStoredRepresentedValue` with the specified key, and settings manager.
    /// The key and default value are required, while the settings manager is optional and defaults to the `.shared` singleton instance.
    ///
    /// If a `DCSetting` instance with the specified key already exists in the settings manager, it will be used to initialize the `StateObject` property.
    /// Otherwise, a runtime error will occur.
    ///
    /// - Parameters:
    ///   - key: The key used to identify the setting in the store.
    ///   - settingsManager: An optional `DCSettingsManager` instance used to manage the setting.
    ///   The default value is the `.shared` singleton instance.
    ///
    /// - Warning: A value for the given key must be set in the specified settings manager before using this initializer.
    /// If no value is found for the given key, a runtime error will occur.
    public init(_ key: DCKeyRepresentable, settingsManager: DCSettingsManager = .shared) {
        if let setting = settingsManager.setting(forKey: key) as? DCSetting<ValueType.RawValue> {
            _setting = StateObject(wrappedValue: setting)
        }
        else {
            fatalError("[DCStoredRepresentedValue] No value of specified type found for key \(key.keyValue). Settings need to be configured in the specified settings manager before use.")
        }
    }
}
