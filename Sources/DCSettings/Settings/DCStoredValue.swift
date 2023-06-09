//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import SwiftUI

/// A property wrapper that wraps a value stored in a `DCSettingStore`.
///
/// The `DCStoredValue` property wrapper can be used to wrap a value that is stored in a `DCSettingStore`.
///
/// When the wrapped value is accessed or modified, the value will be automatically loaded from or saved to the store using a `DCSetting` instance.
///
/// Example:
/// ```swift
/// @DCStoredValue("key1") var value1: Int
///
/// @DCStoredValue("key2") var value2: String
///
/// @DCStoredValue("key3") var value3: Bool
/// ```
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
@propertyWrapper
public struct DCStoredValue<ValueType>: DynamicProperty where ValueType: Equatable {
    
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

    /// Initializes a new `DCStoredValue` instance with the specified key and settings manager.
    ///
    /// This initializer creates a new instance of `DCStoredValue` with the specified key and settings manager.
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
        if let setting = settingsManager.setting(forKey: key) as? DCSetting<ValueType> {
            _setting = StateObject(wrappedValue: setting)
        }
        else {
            fatalError("[DCStoredValue] No value of specified type found for key \(key.keyValue). Settings need to be configured in the specified settings manager before use.")
        }
    }
    
    /// A binding to the current value of the wrapped property.
    ///
    /// The `projectedValue` property provides a `Binding` to the current value of the wrapped property.
    /// This binding can be used to create a two-way connection between the value stored in the `DCSettingStore` and a SwiftUI control.
    ///
    /// Example:
    /// ```swift
    /// struct ContentView: View {
    ///     @DCStoredValue("key1") var value1: Bool
    ///
    ///     var body: some View {
    ///         Toggle("Value", isOn: $value1)
    ///     }
    /// }
    /// ```
    public var projectedValue: Binding<ValueType> {
        return setting.valueBinding()
    }
}
