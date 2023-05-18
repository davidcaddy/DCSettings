//
//  DCStorage.swift
//
//  Created by David Caddy on 17/5/2023.
//

import SwiftUI

/// A property wrapper that wraps a value stored in a `DCSettingStore`.
///
/// The `DCStorage` property wrapper can be used to wrap a value that is stored in a `DCSettingStore`.
///
/// When the wrapped value is accessed or modified, the value will be automatically loaded from or saved to the store using a `DCSetting` instance.
///
/// Example:
/// ```swift
/// @DCStorage("key1", defaultValue: 1) var value1
///
/// @DCStorage("key2", defaultValue: "value2") var value2
///
/// @DCStorage("key3", defaultValue: true) var value3
/// ```
@available(iOS 14.0, *)
@propertyWrapper
public struct DCStorage<ValueType>: DynamicProperty where ValueType: Equatable {
    
    @StateObject private var setting: DCSetting<ValueType>

    /// The current value of the wrapped property.
    ///
    /// When this property is accessed or modified, the value will be automatically loaded from or saved to the store using the `DCSetting` instance.
    public var wrappedValue: ValueType {
        get {
            setting.value
        }
        nonmutating set {
            setting.value = newValue
        }
    }

    /// Initializes a new `DCStorage` instance with the specified key, default value, and settings manager.
    ///
    /// This initializer creates a new instance of `DCStorage` with the specified key, default value, and settings manager. The key and default value are required, while the settings manager is optional and defaults to the `.shared` singleton instance.
    ///
    /// If a `DCSetting` instance with the specified key already exists in the settings manager, it will be used to initialize the `StateObject` property. Otherwise, a new `DCSetting` instance will be created with the specified key and default value.
    ///
    /// - Parameters:
    ///   - key: The key used to identify the setting in the store.
    ///   - defaultValue: The default value of the setting.
    ///   - settingsManager: An optional `DCSettingsManager` instance used to manage the setting. The default value is the `.shared` singleton instance.
    public init(_ key: DCKeyRepresentable, defaultValue: ValueType, settingsManager: DCSettingsManager = .shared) {
        if let setting = settingsManager.setting(forKey: key) as? DCSetting<ValueType> {
            _setting = StateObject(wrappedValue: setting)
        }
        else {
            _setting = StateObject(wrappedValue: DCSetting(key: key, defaultValue: defaultValue))
            print("[DCStorage] Setting with key \"\(key)\" should be configured before use.")
        }
    }
}
