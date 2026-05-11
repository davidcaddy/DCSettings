//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import SwiftUI

/// A property wrapper that reads and writes a concrete `DCSetting` value through a `DCSettingsManager`.
///
/// Reads return the setting's current value; writes persist through its configured store.
///
/// Example:
/// ```swift
/// @DCStoredValue("key1") var value1: Int
/// @DCStoredValue("key2") var value2: String
/// @DCStoredValue("key3") var value3: Bool
/// ```
@MainActor @propertyWrapper
public struct DCStoredValue<ValueType>: DynamicProperty where ValueType: Equatable {

    @StateObject private var setting: DCSetting<ValueType>

    /// The current value of the wrapped setting.
    ///
    /// Reads and writes go through the captured `DCSetting` instance, which handles loading and persistence.
    public var wrappedValue: ValueType {
        get {
            setting.value
        }
        nonmutating set {
            setting.set(newValue)
        }
    }

    /// Looks up a concrete `DCSetting` with the specified key in the given settings manager and captures it.
    ///
    /// The wrapper captures the setting instance at initialization, so the manager must be
    /// configured before the wrapper is constructed. Reconfiguring the manager later does not
    /// rebind existing wrappers to newly-created setting objects.
    ///
    /// - Parameters:
    ///   - key: The key used to identify the setting in the manager.
    ///   - settingsManager: The `DCSettingsManager` used to look up the setting.
    ///   Defaults to `.shared`.
    ///
    /// - Warning: A `DCSetting<ValueType>` for `key` must already be configured in
    /// `settingsManager`. Custom `DCSettable` conformers are not supported by this wrapper;
    /// use manager accessors, bindings, or publishers for those. Otherwise this initializer traps.
    public init(_ key: DCKeyRepresentable, settingsManager: DCSettingsManager = .shared) {
        if let setting = settingsManager.setting(forKey: key) as? DCSetting<ValueType> {
            _setting = StateObject(wrappedValue: setting)
        }
        else {
            fatalError("[DCStoredValue] No value of specified type found for key \(key.keyValue). Settings need to be configured in the specified settings manager before use.")
        }
    }

    /// A `Binding` to the wrapped value, suitable for two-way SwiftUI controls.
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
