//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import SwiftUI

/// A property wrapper that exposes a `RawRepresentable` view of a setting whose stored value is the raw type.
///
/// Reads convert the underlying raw value back into `ValueType`; writes store the new
/// value's `rawValue`. Useful for enum- or option-set-backed settings.
@MainActor @propertyWrapper
public struct DCStoredRepresentedValue<ValueType>: DynamicProperty where ValueType: RawRepresentable, ValueType.RawValue: Equatable {

    @StateObject private var setting: DCSetting<ValueType.RawValue>

    /// The setting's value, converted to and from `ValueType` via its `rawValue`.
    ///
    /// Returns `nil` if the stored raw value cannot be converted back to `ValueType`.
    /// Assigning `nil` is ignored because the underlying setting stores a non-optional raw value.
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

    /// Looks up the setting with the specified key in the given settings manager and captures it.
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
    /// - Warning: A `DCSetting<ValueType.RawValue>` for `key` must already be configured in
    /// `settingsManager`. Otherwise this initializer traps.
    public init(_ key: DCKeyRepresentable, settingsManager: DCSettingsManager = .shared) {
        if let setting = settingsManager.setting(forKey: key) as? DCSetting<ValueType.RawValue> {
            _setting = StateObject(wrappedValue: setting)
        }
        else {
            fatalError("[DCStoredRepresentedValue] No value of specified type found for key \(key.keyValue). Settings need to be configured in the specified settings manager before use.")
        }
    }
}
