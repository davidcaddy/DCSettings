//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import Combine
import SwiftUI

/// A protocol that represents a settable value with a specific type.
///
/// The `DCSettable` protocol defines the requirements for a type that represents a settable value with a specific type.
/// The value type must conform to the `Equatable` protocol.
///
/// The protocol includes properties for the label and key of the setting, as well as the current value and configuration of the setting.
/// It also includes a property for the `DCSettingStore` instance used to store the setting value.
///
/// The protocol also includes a `refresh` method that can be used to refresh the setting value from the store.
public protocol DCSettable<ValueType>: ObservableObject where ValueType: Equatable {
    
    /// The type of value associated with the setting.
    associatedtype ValueType
    
    /// An optional label for the setting.
    var label: String? { get }
    
    /// The key used to identify the setting in the store.
    var key: String { get }
    
    /// The current value of the setting.
    var value: ValueType { get set }
    
    /// An optional configuration for the setting.
    var configuation: DCSettingConfiguration<ValueType>? { get }
    
    /// An optional `DCSettingStore` instance used to store the setting value.
    var store: DCSettingStore? { get set }
    
    /// Refreshes the setting value from the store.
    func refresh()
}

/// A class that represents a settable value with a specific type.
///
/// The `DCSetting` class is a concrete implementation of the `DCSettable` protocol that represents a settable value with a specific type.
/// The value type must conform to the `Equatable` protocol.
///
/// The class includes properties for the label and key of the setting, as well as the current value and configuration of the setting.
///
/// It also includes a property for the `DCSettingStore` instance used to store the setting value.
///
/// The class also includes several convenience initializers that can be used to create new instances of `DCSetting` with different configurations.
///
/// - Note: If the store is not set when the setting is configured by a manager instance, the store of the group in which the setting resides will be used.
public class DCSetting<ValueType>: DCSettable where ValueType: Equatable {
    
    /// The key used to identify the setting in the store.
    public let key: String
    
    /// An optional label for the setting.
    public let label: String?
    
    private var _value: ValueType
    
    /// The current value of the setting.
    public var value: ValueType {
        get {
            _value
        }
        set {
            if _value != newValue {
                _value = newValue
                objectWillChange.send()
                save()
            }
        }
    }
    
    /// An optional `DCSettingStore` instance used to store the setting value.
    ///
    /// If not provided when initialized, this will be set to the store of the group in which the setting resides when configured by a manager.
    public var store: DCSettingStore?
    
    /// An optional configuration for the setting.
    public let configuation: DCSettingConfiguration<ValueType>?
    
    private var cancellable: AnyCancellable?
    
    private init(key: DCKeyRepresentable, value: ValueType, label: String?, configuation: DCSettingConfiguration<ValueType>?, store: DCSettingStore?) {
        self.key = key.keyValue
        self._value = value
        self.label = label
        self.store = store
        self.configuation = configuation
    }
    
    /// Initializes a new `DCSetting` instance with the specified key, default value, label, and store.
    ///
    /// If a store is not provided, the store of the group in which the setting resides will be used once configured.
    ///
    /// - Parameters:
    ///   - key: The key used to identify the setting in the store.
    ///   - defaultValue: The default value of the setting.
    ///   - label: An optional label for the setting. The default value is `nil`.
    ///   - store: An optional `DCSettingStore` instance used to store the setting value. The default value is `nil`.
    public convenience init(key: DCKeyRepresentable, defaultValue: ValueType, label: String? = nil, store: DCSettingStore? = nil) {
        self.init(key: key.keyValue, value: defaultValue, label: label, configuation: nil, store: store)
    }

    /// Initializes a new `DCSetting` instance with the specified key, label, store, options array, and default index.
    ///
    /// If the provided default index is not a valid index in the options array or if the options array is empty, this initializer will return `nil`.
    ///
    /// If a store is not provided, the store of the group in which the setting resides will be used once configured.
    ///
    /// - Parameters:
    ///   - key: The key used to identify the setting in the store.
    ///   - label: An optional label for the setting. The default value is `nil`.
    ///   - store: An optional `DCSettingStore` instance used to store the setting value. The default value is `nil`.
    ///   - options: An array of values representing the available options for the setting.
    ///   - defaultIndex: The index of the default option in the options array.
    public convenience init?(key: DCKeyRepresentable, label: String? = nil, store: DCSettingStore? = nil, options: [ValueType], defaultIndex: Int) where ValueType: LosslessStringConvertible {
        if let defaultValue = options.get(defaultIndex) {
            let configuredOptions = options.map { DCSettingOption(value: $0, label: String($0)) }
            self.init(key: key, value: defaultValue, label: label, configuation: DCSettingConfiguration<ValueType>(options: configuredOptions, bounds: nil, step: nil), store: store)
        }
        else {
            return nil
        }
    }

    /// Initializes a new `DCSetting` instance with the specified key, default value, label, store, lower bound, upper bound, and step value.
    ///
    /// If a store is not provided, the store of the group in which the setting resides will be used once configured.
    ///
    /// - Parameters:
    ///   - key: The key used to identify the setting in the store.
    ///   - defaultValue: The default value of the setting.
    ///   - label: An optional label for the setting. The default value is `nil`.
    ///   - store: An optional `DCSettingStore` instance used to store the setting value. The default value is `.standard`.
    ///   - lowerBound: The lower bound of the range of valid values for the setting.
    ///   - upperBound: The upper bound of the range of valid values for the setting.
    ///   - step: An optional step value that specifies the increment or decrement between valid values. The default value is `nil`.
    public convenience init(key: DCKeyRepresentable, defaultValue: ValueType, label: String? = nil, store: DCSettingStore? = nil, lowerBound: ValueType, upperBound: ValueType, step: ValueType? = nil) where ValueType: Numeric {
        self.init(key: key, value: defaultValue, label: label, configuation: DCSettingConfiguration<ValueType>(options: nil, bounds: DCValueBounds(lowerBound: lowerBound, upperBound: upperBound), step: step), store: store)
    }
    
    /// Initializes a new `DCSetting` instance with the specified key, label, store and result builder closure.
    ///
    /// This convenience initializer creates a new instance of `DCSetting` with an array of options constructed using a result builder closure.
    ///
    /// If no options are provided in the result builder closure, this initializer will return `nil`.
    ///
    /// If no default option in the result builder has be set as the default, the first option will be used as default.
    /// If multiple options are set as default in the result builder, the first default option will be used as default.
    ///
    /// If a store is not provided, the store of the group in which the setting resides will be used once configured.
    ///
    /// - Parameters:
    ///   - key: The key used to identify the setting in the store.
    ///   - label: An optional label for the setting. The default value is `nil`.
    ///   - store: An optional `DCSettingStore` instance used to store the setting value. The default value is `nil`.
    ///   - builder: A result builder closure that constructs an array of `DCSettingOption` instances.
    public convenience init?(key: DCKeyRepresentable, label: String? = nil, store: DCSettingStore? = nil, @DCSettingOptionsBuilder _ builder: () -> [DCSettingOption<ValueType>]) {
        self.init(key: key, label: label, store: store, options: builder())
    }
    
    /// Initializes a new `DCSetting` instance with the specified key, label, store and options.
    ///
    /// This convenience initializer creates a new instance of `DCSetting` with an array of options.
    ///
    /// If the option array is empty, this initializer will return `nil`.
    ///
    /// If no default option in the array has be set as the default, the first option will be used as default.
    /// If multiple options are set as default in the array, the first default option will be used as default.
    ///
    /// If a store is not provided, the store of the group in which the setting resides will be used once configured.
    ///
    /// - Parameters:
    ///   - key: The key used to identify the setting in the store.
    ///   - label: An optional label for the setting. The default value is `nil`.
    ///   - store: An optional `DCSettingStore` instance used to store the setting value. The default value is `nil`.
    ///   - options: An array of `DCSettingOption` instances.
    public convenience init?(key: DCKeyRepresentable, label: String? = nil, store: DCSettingStore? = nil, options configuredOptions: [DCSettingOption<ValueType>]) {
        if let defaultValue = configuredOptions.first(where: { $0.isDefault })?.value ?? configuredOptions.first?.value {
            self.init(key: key, value: defaultValue, label: label, configuation: DCSettingConfiguration<ValueType>(options: configuredOptions, bounds: nil, step: nil), store: store)
        }
        else {
            return nil
        }
    }
    
    /// Initializes a new `DCSetting` instance with the specified key and options provider.
    ///
    /// - Parameters:
    ///   - key: The key for the setting.
    ///   - label: The label for the setting. Defaults to `nil`.
    ///   - store: The store to use for the setting. Defaults to `nil`.
    ///   - optionsProvider: The type that provides options for the setting.
    public convenience init?<ProviderType: DCSettingOptionProviding>(key: DCKeyRepresentable, label: String? = nil, store: DCSettingStore? = nil, optionsProvider: ProviderType.Type) where ValueType == ProviderType.RawValue {
        if let defaultCase = optionsProvider.defaultCase ?? ProviderType.allCases.first {
            let options: [DCSettingOption] = ProviderType.allCases.map { option in
                var label = option.label
                if label == nil, let stringConvertible = option.rawValue as? LosslessStringConvertible {
                    label = String(stringConvertible)
                }
                let image = option.image
                let isDefault = option == defaultCase
                return DCSettingOption(value: option.rawValue, label: label, image: image, isDefault: isDefault)
            }
            self.init(key: key, label: label, store: store, options: options)
        }
        else {
            return nil
        }
    }
    
    /// Refreshes the setting value from the store.
    ///
    /// This method refreshes the current value of the setting from the store.
    /// If a new value is found in the store and is different from the current value, the current value will be updated.
    ///
    /// This is called during the initial configuatrion of the setting by the managing `DCSettingsManager` instance.
    /// Calling this directly on a setting should be avoided.
    public func refresh() {
        if let newValue: ValueType = store?.object(forKey: key), value != newValue {
            _value = newValue
        }
        setUpListener()
    }
    
    private func save() {
        cancellable = nil
        store?.set(value, forKey: key)
        setUpListener()
    }
    
    /// Returns a binding for the current value of the setting.
    ///
    /// This method returns a `Binding` instance for the current value of the setting.
    /// The binding can be used to bind the setting value to a user interface element.
    ///
    /// - Returns: A `Binding` instance for the current value of the setting.
    public func valueBinding() -> Binding<ValueType> {
        return Binding {
            self.value
        } set: { newValue in
            self.value = newValue
        }
    }
    
    private func setUpListener() {
        guard let store = store else { return }
        cancellable = store.valuePublisher(forKey: key)
            .receive(on: RunLoop.main)
            .sink { [weak self] newValue in
                if let newTypedValue = newValue as? ValueType, self?.value != newTypedValue {
                    self?.value = newTypedValue
                }
            }
    }
}

/// A result builder that constructs an array of `DCSettable` instances.
///
/// The `DCSettingsBuilder` struct is a result builder that can be used to construct an array of `DCSettable` instances
/// using a closure with multiple `DCSettable` expressions.
///
/// Example:
/// ``` swift
/// let settings: [any DCSettable] = DCSettingsBuilder {
///     DCSetting(key: "key1", defaultValue: 1)
///     DCSetting(key: "key2", defaultValue: "value2")
///     DCSetting(key: "key3", defaultValue: true)
/// }
/// ```
@resultBuilder
public struct DCSettingsBuilder {
    
    /// Constructs an array of `DCSettable` instances from the provided expressions.
    ///
    /// This method is called by the result builder to construct the final result from the provided expressions.
    /// The expressions must be instances of `DCSettable`.
    ///
    /// - Parameter settings: A variadic list of optional `DCSettable` instances.
    /// - Returns: An array of `DCSettable` instances.
    public static func buildBlock(_ settings: (any DCSettable)?...) -> [any DCSettable] {
        settings.compactMap { $0 }
    }
}
