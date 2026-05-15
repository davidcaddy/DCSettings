//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import Combine
import SwiftUI

private protocol DCOptionalValue {}

extension Optional: DCOptionalValue {}

private protocol DCComparableValueBounds {
    func contains(_ value: Any) -> Bool
}

extension DCValueBounds: DCComparableValueBounds where ValueType: Comparable {

    func contains(_ value: Any) -> Bool {
        guard let typedValue = value as? ValueType else {
            return false
        }

        return lowerBound <= typedValue && typedValue <= upperBound
    }
}

/// A type-erased view of a settable value backed by a `DCSettingStore`.
///
/// Conformers expose a `value` of `ValueType: Equatable`, an identifying `key`, an optional
/// `label`, an optional `configuration` (options/bounds/step), and the `store` used for
/// persistence. Call `set(_:)` when you need to know whether a write took effect, and
/// `refresh()` to reload the current value from the store.
@MainActor public protocol DCSettable<ValueType>: ObservableObject where ValueType: Equatable {

    /// The type of value associated with the setting.
    associatedtype ValueType

    /// An optional label for the setting.
    var label: String? { get }

    /// The key used to identify the setting in the store.
    var key: String { get }

    /// The current value of the setting.
    var value: ValueType { get set }

    /// Attempts to update the setting's value.
    ///
    /// - Parameter value: The new value to assign.
    /// - Returns: `true` when the setting accepted the value, otherwise `false`.
    @discardableResult func set(_ value: ValueType) -> Bool

    /// An optional configuration for the setting.
    var configuration: DCSettingConfiguration<ValueType>? { get }

    /// An optional `DCSettingStore` instance used to store the setting value.
    ///
    /// For `DCSetting`, this is an explicit per-setting override. When it is `nil`, the
    /// containing group store is inherited during manager configuration.
    ///
    /// Custom conformers with `store == nil` have the containing group store assigned during
    /// manager configuration. If a custom conformer needs reusable inherited-store behavior,
    /// keep explicit and inherited storage separate in that type.
    var store: DCSettingStore? { get set }

    /// Refreshes the setting value from the store.
    func refresh()
}

public extension DCSettable {

    /// Attempts to update the setting's value.
    ///
    /// The default implementation validates `value` against `configuration`, assigns it to
    /// ``value``, and returns whether the assigned value is now visible. Conformers that persist
    /// values should override this method when persistence failure matters.
    @discardableResult func set(_ newValue: ValueType) -> Bool {
        guard _isValidConfiguredValue(newValue) else {
            return false
        }

        if value == newValue {
            return true
        }

        value = newValue
        return value == newValue
    }

    /// An optional configuration for the setting.
    @available(*, deprecated, renamed: "configuration")
    var configuation: DCSettingConfiguration<ValueType>? {
        configuration
    }
}

extension DCSettable {

    func _typedValue<T>(as type: T.Type) -> T? where T: Equatable {
        value as? T
    }

    func _typedConfiguration<T>(as type: T.Type) -> DCSettingConfiguration<T>? where T: Equatable {
        configuration as? DCSettingConfiguration<T>
    }

    @discardableResult func _setTypedValue<T>(_ newValue: T) -> Bool where T: Equatable {
        guard let typedValue = newValue as? ValueType, _isValidConfiguredValue(typedValue) else {
            return false
        }

        return set(typedValue)
    }

    func _typedBinding<T>(as type: T.Type) -> Binding<T>? where T: Equatable {
        guard let currentValue = value as? T else {
            return nil
        }

        return Binding {
            self.value as? T ?? currentValue
        } set: { newValue in
            self._setTypedValue(newValue)
        }
    }

    func _typedPublisher<T>(as type: T.Type) -> AnyPublisher<T, Never>? where T: Equatable {
        guard let currentValue = value as? T else {
            return nil
        }

        return Just(currentValue)
            .merge(with: _objectWillChangePublisher().compactMap { [weak self] in
                self?.value as? T
            })
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func _objectWillChangePublisher() -> AnyPublisher<Void, Never> {
        objectWillChange
            .receive(on: RunLoop.main)
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    func _isValidConfiguredValue(_ value: ValueType) -> Bool {
        DCSetting<ValueType>.isValid(value, configuration: configuration)
    }
}

@MainActor protocol DCGroupStoreConfigurable {

    func _configureInheritedStore(_ store: DCSettingStore)
}

/// The default `DCSettable` implementation: a settable value of a specific type, persisted via a `DCSettingStore`.
///
/// `DCSetting` provides convenience initializers for plain default values, fixed option lists,
/// numeric bounds, and result-builder option DSLs.
///
/// - Important: Optional value types, such as `String?`, are not supported. Model unset, inherited,
///   or system-default states with a concrete default value or an explicit enum case.
/// - Note: When `store` is `nil` at configuration time, the manager resolves the containing
///   group's store as the inherited backing store without changing the setting's explicit
///   store override.
@MainActor public final class DCSetting<ValueType>: DCSettable where ValueType: Equatable {

    /// The key used to identify the setting in the store.
    public let key: String

    /// An optional label for the setting.
    public let label: String?

    private let defaultValue: ValueType
    private var _value: ValueType

    /// The current value of the setting.
    ///
    /// Assignments that fail validation or cannot be submitted to storage are ignored. Use
    /// `DCSettingsManager.set(_:forKey:)` when you need a boolean result.
    public var value: ValueType {
        get {
            _value
        }
        set {
            set(newValue)
        }
    }

    /// An optional `DCSettingStore` instance used to store the setting value.
    ///
    /// If not provided when initialized, the setting inherits the store of the group in which
    /// it resides when configured by a manager. This property remains the explicit setting
    /// override and is not mutated by group-store inheritance.
    public var store: DCSettingStore?

    private var inheritedStore: DCSettingStore?

    private var effectiveStore: DCSettingStore? {
        store ?? inheritedStore
    }

    /// An optional configuration for the setting.
    public let configuration: DCSettingConfiguration<ValueType>?

    /// An optional configuration for the setting.
    @available(*, deprecated, renamed: "configuration")
    public var configuation: DCSettingConfiguration<ValueType>? {
        configuration
    }

    /// Attempts to update the setting's value and persist it to the effective store.
    ///
    /// - Parameter newValue: The new value to assign.
    /// - Returns: `true` when the value is valid and either already current or accepted
    /// and submitted to the backing store, otherwise `false`. Backing-store setters do not
    /// report durable-write failures, so custom store failures cannot be detected here.
    @discardableResult public func set(_ newValue: ValueType) -> Bool {
        guard isValid(newValue) else {
            return false
        }

        if _value == newValue {
            return true
        }

        guard save(newValue) else {
            return false
        }

        objectWillChange.send()
        _value = newValue
        return true
    }

    private var cancellable: AnyCancellable?

    static var supportsValueType: Bool {
        !(ValueType.self is DCOptionalValue.Type)
    }

    fileprivate static func isValid(_ value: ValueType, configuration: DCSettingConfiguration<ValueType>?) -> Bool {
        guard let configuration else {
            return true
        }

        if let options = configuration.options, !options.contains(where: { $0.value == value }) {
            return false
        }

        if let bounds = configuration.bounds as? any DCComparableValueBounds, !bounds.contains(value) {
            return false
        }

        return true
    }

    static func isValidStep(_ step: ValueType?) -> Bool where ValueType: Numeric & Comparable {
        guard let step else {
            return true
        }

        if let step = step as? Double {
            return step > 0.0 && step.isFinite
        }

        if let step = step as? Float {
            return step > 0.0 && step.isFinite
        }

        if let step = step as? CGFloat {
            return step > 0.0 && step.isFinite
        }

        return step > .zero
    }

    private init(key: DCKeyRepresentable, defaultValue: ValueType, label: String?, configuration: DCSettingConfiguration<ValueType>?, store: DCSettingStore?) {
        precondition(Self.supportsValueType, "DCSetting optional value types are not supported. Use a concrete default value or an explicit enum case instead.")
        precondition(Self.isValid(defaultValue, configuration: configuration), "DCSetting default value must satisfy configured options and bounds.")

        self.key = key.keyValue
        self.defaultValue = defaultValue
        self._value = defaultValue
        self.label = label
        self.store = store
        self.configuration = configuration
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
        self.init(key: key.keyValue, defaultValue: defaultValue, label: label, configuration: nil, store: store)
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
            let configuredOptions = options.enumerated().map { index, value in
                DCSettingOption(value: value, label: String(value), isDefault: index == defaultIndex)
            }
            self.init(key: key, defaultValue: defaultValue, label: label, configuration: DCSettingConfiguration<ValueType>(options: configuredOptions, bounds: nil, step: nil), store: store)
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
    ///   - step: An optional positive step value that controls the editing increment. The default value is `nil`.
    ///   This value must be greater than zero when provided. Floating-point steps must also be finite.
    public convenience init(key: DCKeyRepresentable, defaultValue: ValueType, label: String? = nil, store: DCSettingStore? = nil, lowerBound: ValueType, upperBound: ValueType, step: ValueType? = nil) where ValueType: Numeric & Comparable {
        precondition(Self.isValidStep(step), "DCSetting step must be greater than zero and finite.")
        self.init(key: key, defaultValue: defaultValue, label: label, configuration: DCSettingConfiguration<ValueType>(options: nil, bounds: DCValueBounds(lowerBound: lowerBound, upperBound: upperBound), step: step), store: store)
    }

    /// Initializes a new `DCSetting` instance with the specified key, label, store and result builder closure.
    ///
    /// This convenience initializer creates a new instance of `DCSetting` with an array of options constructed using a result builder closure.
    ///
    /// If no options are provided in the result builder closure, this initializer will return `nil`.
    ///
    /// If no default option in the result builder has been set as the default, the first option will be used as default.
    /// If multiple options are set as default in the result builder, the first default option will be used as default.
    ///
    /// If a store is not provided, the store of the group in which the setting resides will be used once configured.
    ///
    /// - Parameters:
    ///   - key: The key used to identify the setting in the store.
    ///   - label: An optional label for the setting. The default value is `nil`.
    ///   - store: An optional `DCSettingStore` instance used to store the setting value. The default value is `nil`.
    ///   - builder: A result builder closure that constructs an array of `DCSettingOption` instances.
    public convenience init?(key: DCKeyRepresentable, label: String? = nil, store: DCSettingStore? = nil, @DCSettingOptionsBuilder _ builder: @MainActor () -> [DCSettingOption<ValueType>]) {
        self.init(key: key, label: label, store: store, options: builder())
    }

    /// Initializes a new `DCSetting` instance with the specified key, label, store and options.
    ///
    /// This convenience initializer creates a new instance of `DCSetting` with an array of options.
    ///
    /// If the option array is empty, this initializer will return `nil`.
    ///
    /// If no default option in the array has been set as the default, the first option will be used as default.
    /// If multiple options are set as default in the array, the first default option will be used as default.
    ///
    /// If a store is not provided, the store of the group in which the setting resides will be used once configured.
    ///
    /// - Parameters:
    ///   - key: The key used to identify the setting in the store.
    ///   - label: An optional label for the setting. The default value is `nil`.
    ///   - store: An optional `DCSettingStore` instance used to store the setting value. The default value is `nil`.
    ///   - configuredOptions: An array of `DCSettingOption` instances.
    public convenience init?(key: DCKeyRepresentable, label: String? = nil, store: DCSettingStore? = nil, options configuredOptions: [DCSettingOption<ValueType>]) {
        if let defaultValue = configuredOptions.first(where: { $0.isDefault })?.value ?? configuredOptions.first?.value {
            self.init(key: key, defaultValue: defaultValue, label: label, configuration: DCSettingConfiguration<ValueType>(options: configuredOptions, bounds: nil, step: nil), store: store)
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

    /// Reloads the setting's value from its store and starts observing further changes.
    ///
    /// `DCSettingsManager` calls this during configuration. Avoid invoking it directly.
    public func refresh() {
        guard let store = effectiveStore else {
            return
        }

        if let newValue: ValueType = store.object(forKey: key) {
            updateValueFromStore(newValue)
        }
        else {
            updateValueFromStore(defaultValue)
        }

        setUpListener()
    }

    private func save(_ value: ValueType) -> Bool {
        cancellable = nil
        let didSave = effectiveStore?.set(value, forKey: key) ?? true
        setUpListener()
        return didSave
    }

    private func isValid(_ value: ValueType) -> Bool {
        _isValidConfiguredValue(value)
    }

    private func updateValueFromStore(_ newValue: ValueType) {
        guard _value != newValue, isValid(newValue) else {
            return
        }

        objectWillChange.send()
        _value = newValue
    }

    /// Returns a `Binding` to the setting's current value, suitable for SwiftUI controls.
    public func valueBinding() -> Binding<ValueType> {
        return Binding {
            self.value
        } set: { newValue in
            self.set(newValue)
        }
    }

    private func setUpListener() {
        guard let store = effectiveStore else { return }
        cancellable = store.valuePublisher(forKey: key, as: ValueType.self)
            .receive(on: RunLoop.main)
            .sink { [weak self] newValue in
                guard let self else {
                    return
                }

                self.updateValueFromStore(newValue ?? self.defaultValue)
            }
    }
}

extension DCSetting: DCGroupStoreConfigurable {

    func _configureInheritedStore(_ store: DCSettingStore) {
        inheritedStore = store
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
@MainActor public struct DCSettingsBuilder {

    /// Constructs an empty array of `DCSettable` instances.
    ///
    /// - Returns: An empty array of `DCSettable` instances.
    public static func buildBlock() -> [any DCSettable] {
        []
    }

    /// Constructs an array of `DCSettable` instances from the provided expressions.
    ///
    /// - Parameter settings: A variadic list of optional `DCSettable` instances.
    /// - Returns: An array of `DCSettable` instances.
    public static func buildBlock(_ settings: (any DCSettable)?...) -> [any DCSettable] {
        settings.compactMap { $0 }
    }

    public static func buildExpression(_ setting: (any DCSettable)?) -> [any DCSettable] {
        setting.map { [$0] } ?? []
    }

    public static func buildBlock(_ components: [any DCSettable]...) -> [any DCSettable] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [any DCSettable]?) -> [any DCSettable] {
        component ?? []
    }

    public static func buildEither(first component: [any DCSettable]) -> [any DCSettable] {
        component
    }

    public static func buildEither(second component: [any DCSettable]) -> [any DCSettable] {
        component
    }

    public static func buildArray(_ components: [[any DCSettable]]) -> [any DCSettable] {
        components.flatMap { $0 }
    }
}
