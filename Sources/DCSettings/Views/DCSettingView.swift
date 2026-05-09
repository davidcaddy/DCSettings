//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import Combine
import SwiftUI

#if !os(tvOS)

extension DCSettable {

    var displayLabel: String {
        return label ?? key.sentenceFormatted
    }
}

enum DCOptionControlStyle: Equatable {
    case picker
    case menuPicker

    init(optionCount: Int) {
        self = optionCount > 2 ? .menuPicker : .picker
    }
}

extension DCSettingOption {

    func labelView() -> some View {
        return HStack {
            if let string = label {
                if let imageName = image {
                    switch imageName {
                    case .custom(let name):
                        Label(string, image: name)
                    case .system(let name):
                        Label(string, systemImage: name)
                    }
                }
                else {
                    Text(string)
                }
            }
            else if let imageName = image {
                switch imageName {
                case .custom(let name):
                    Image(name)
                case .system(let name):
                    Image(systemName: name)
                }
            }
        }
    }
}

@MainActor private final class DCSettableObservation: ObservableObject {

    private var cancellable: AnyCancellable?

    init(setting: any DCSettable) {
        cancellable = setting._objectWillChangePublisher()
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
    }
}

struct DCBoolSettingView: View {
    @Environment(\.isEnabled) var isEnabled

    let key: String
    let label: String
    @Binding var value: Bool

    var body: some View {
        Toggle(label, isOn: $value)
            .toggleStyle(SwitchToggleStyle())
            .accessibilityIdentifier(key)
            .foregroundColor(isEnabled ? .primary : .secondary)
            #if os(macOS)
                .controlSize(.mini)
            #endif
    }
}

struct DCIntSettingView: View {
    @Environment(\.isEnabled) var isEnabled

    let key: String
    let label: String
    let configuration: DCSettingConfiguration<Int>?
    @Binding var value: Int

    static func usableStep(_ step: Int?) -> Int {
        guard let step, step > 0 else {
            return 1
        }

        return step
    }

    var body: some View {
        if let options = configuration?.options {
            DCOptionPickerView(key: key, label: label, options: options, value: $value)
        }
        else if let bounds = configuration?.bounds {
            DCSliderView(key: key, label: label, value: Binding(get: {
                Double(value)
            }, set: { newValue in
                value = Int(newValue)
            }), bounds: DCValueBounds(lowerBound: Double(bounds.lowerBound), upperBound: Double(bounds.upperBound)), step: Double(Self.usableStep(configuration?.step)), specifier: "%.0f")
        }
        else {
            let step = Self.usableStep(configuration?.step)
            HStack {
                Text(label)
                    .foregroundColor(isEnabled ? .primary : .secondary)
                Spacer()
                Text(String(value))
                    .padding(.trailing, 8.0)
                #if os(watchOS)
                    if #available(watchOS 9.0, *) {
                        Stepper(label, value: $value, step: step)
                            .labelsHidden()
                            .accessibilityIdentifier(key)
                    }
                    else {
                        HStack(spacing: 8.0) {
                            Button {
                                value -= step
                            } label: {
                                Image(systemName: "minus")
                            }
                            .accessibilityLabel("Decrease \(label)")
                            .accessibilityIdentifier("\(key).decrement")

                            Button {
                                value += step
                            } label: {
                                Image(systemName: "plus")
                            }
                            .accessibilityLabel("Increase \(label)")
                            .accessibilityIdentifier("\(key).increment")
                        }
                    }
                #else
                    Stepper(label, value: $value, step: step)
                        .labelsHidden()
                        .accessibilityIdentifier(key)
                #endif
            }
            .foregroundColor(isEnabled ? .primary : .secondary)
        }
    }
}

struct DCDoubleSettingView: View {
    let key: String
    let label: String
    let configuration: DCSettingConfiguration<Double>?
    @Binding var value: Double

    static func usesSlider(configuration: DCSettingConfiguration<Double>?) -> Bool {
        return configuration?.options == nil && configuration?.bounds != nil
    }

    static func usesNumericTextField(configuration: DCSettingConfiguration<Double>?) -> Bool {
        return configuration?.options == nil && configuration?.bounds == nil
    }

    var body: some View {
        if let options = configuration?.options {
            DCOptionPickerView(key: key, label: label, options: options, value: $value)
        }
        else if let bounds = configuration?.bounds {
            DCSliderView(key: key, label: label, value: $value, bounds: bounds, step: configuration?.step, specifier: "%.2f")
        }
        else {
            DCDoubleTextFieldView(key: key, label: label, value: $value)
        }
    }
}

struct DCDoubleTextFieldView: View {
    @Environment(\.isEnabled) var isEnabled

    let key: String
    let label: String
    @Binding var value: Double

    static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 6
        return formatter
    }()

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField(label, value: $value, formatter: Self.formatter)
                .multilineTextAlignment(.trailing)
                .accessibilityIdentifier(key)
            #if os(iOS) || os(visionOS)
                .keyboardType(.decimalPad)
            #endif
        }
        .foregroundColor(isEnabled ? .primary : .secondary)
    }
}

struct DCStringSettingView: View {
    @Environment(\.isEnabled) var isEnabled

    let key: String
    let label: String
    let configuration: DCSettingConfiguration<String>?
    @Binding var value: String

    var body: some View {
        if let options = configuration?.options {
            DCOptionPickerView(key: key, label: label, options: options, value: $value)
        }
        else {
            TextField(label, text: $value)
                .foregroundColor(isEnabled ? .primary : .secondary)
                .accessibilityIdentifier(key)
        }
    }
}

struct DCDateSettingView: View {
    @Environment(\.isEnabled) var isEnabled

    let key: String
    let label: String
    let configuration: DCSettingConfiguration<Date>?
    @Binding var value: Date

    static func datePickerRange(for bounds: DCValueBounds<Date>) -> ClosedRange<Date> {
        return bounds.lowerBound...bounds.upperBound
    }

    var body: some View {
        #if os(watchOS)
            if #available(watchOS 10.0, *) {
                picker
            }
            else {
                DCDisplayOnlyDateView(key: key, label: label, value: value)
            }
        #else
            picker
        #endif
    }

    @available(watchOS 10.0, *)
    @ViewBuilder private var picker: some View {
        if let bounds = configuration?.bounds {
            DatePicker(selection: $value, in: Self.datePickerRange(for: bounds), displayedComponents: .date) {
                Text(label)
            }
            .foregroundColor(isEnabled ? .primary : .secondary)
            .accessibilityIdentifier(key)
        }
        else {
            DatePicker(selection: $value, displayedComponents: .date) {
                Text(label)
            }
            .foregroundColor(isEnabled ? .primary : .secondary)
            .accessibilityIdentifier(key)
        }
    }
}

struct DCDisplayOnlyDateView: View {
    @Environment(\.isEnabled) var isEnabled

    let key: String
    let label: String
    let value: Date

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value, style: .date)
                .foregroundColor(.secondary)
        }
        .foregroundColor(isEnabled ? .primary : .secondary)
        .accessibilityIdentifier(key)
    }
}

struct DCColorSettingView: View {
    @Environment(\.isEnabled) var isEnabled

    let key: String
    let label: String
    @Binding var value: Color

    var body: some View {
        #if os(watchOS)
            DCDisplayOnlyColorView(key: key, label: label, value: value)
        #else
            ColorPicker(label, selection: $value)
            .foregroundColor(isEnabled ? .primary : .secondary)
            .accessibilityIdentifier(key)
        #endif
    }
}

struct DCDisplayOnlyColorView: View {
    @Environment(\.isEnabled) var isEnabled

    let key: String
    let label: String
    let value: Color

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Circle()
                .fill(value)
                .frame(width: 22.0, height: 22.0)
                .overlay(
                    Circle()
                        .stroke(Color.secondary.opacity(0.6), lineWidth: 1.0)
                )
                .opacity(isEnabled ? 1.0 : 0.5)
                .accessibilityLabel(label)
        }
        .foregroundColor(isEnabled ? .primary : .secondary)
        .accessibilityIdentifier(key)
    }
}

struct DCSliderView: View {
    @Environment(\.isEnabled) var isEnabled

    let key: String
    let label: String
    @Binding var value: Double
    let bounds: DCValueBounds<Double>
    let step: Double?
    let specifier: String

    static func usableStep(_ step: Double?) -> Double? {
        guard let step, step > 0.0, step.isFinite else {
            return nil
        }

        return step
    }

    var body: some View {
        VStack {
            HStack {
                Text(label)
                Spacer()
                Text("\(value, specifier: specifier)")
                    .monospacedDigitIfAvailable()
            }
            if let valueStep = Self.usableStep(step) {
                Slider(value: $value, in: bounds.lowerBound...bounds.upperBound, step: valueStep) {
                    Text(label)
                } minimumValueLabel: {
                    Text("\(bounds.lowerBound, specifier: specifier)")
                        .monospacedDigitIfAvailable()
                        .foregroundColor(.secondary)
                        .font(.footnote)
                } maximumValueLabel: {
                    Text("\(bounds.upperBound, specifier: specifier)")
                        .monospacedDigitIfAvailable()
                        .foregroundColor(.secondary)
                        .font(.footnote)
                }
                .labelsHidden()
                .accessibilityIdentifier(key)
            }
            else {
                Slider(value: $value, in: bounds.lowerBound...bounds.upperBound) {
                    Text(label)
                } minimumValueLabel: {
                    Text("\(bounds.lowerBound, specifier: specifier)")
                        .monospacedDigitIfAvailable()
                        .foregroundColor(.secondary)
                        .font(.footnote)
                } maximumValueLabel: {
                    Text("\(bounds.upperBound, specifier: specifier)")
                        .monospacedDigitIfAvailable()
                        .foregroundColor(.secondary)
                        .font(.footnote)
                }
                .labelsHidden()
                .accessibilityIdentifier(key)
            }
        }
        .foregroundColor(isEnabled ? .primary : .secondary)
    }
}

struct DCOptionPickerView<ValueType>: View where ValueType: Equatable & Hashable {
    @Environment(\.isEnabled) var isEnabled

    let key: String
    let label: String
    let options: [DCSettingOption<ValueType>]
    @Binding var value: ValueType

    var body: some View {
        if DCOptionControlStyle(optionCount: options.count) == .menuPicker {
            DCMenuPickerView(key: key, label: label, options: options, value: $value)
        }
        else {
            HStack {
                Text(label)
                Spacer(minLength: 16.0)
                Picker(label, selection: $value) {
                    ForEach(options, id: \.value) { option in
                        option.labelView()
                            .tag(option.value)
                    }
                }
                .labelsHidden()
                .accessibilityIdentifier(key)
                #if os(macOS)
                    .pickerStyle(RadioGroupPickerStyle())
                    .horizontalRadioGroupLayout()
                #elseif !os(watchOS)
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(maxWidth: 140.0)
                #endif
            }
            .foregroundColor(isEnabled ? .primary : .secondary)
        }
    }
}

struct DCMenuPickerView<ValueType>: View where ValueType: Equatable & Hashable {
    @Environment(\.isEnabled) var isEnabled

    let key: String
    let label: String
    let options: [DCSettingOption<ValueType>]
    @Binding var value: ValueType

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(isEnabled ? .primary : .secondary)
            Spacer()
            #if os(macOS) || os(watchOS)
                Picker(label, selection: $value) {
                    ForEach(options, id: \.value) { option in
                        option.labelView()
                            .tag(option.value)
                    }
                }
                .labelsHidden()
                .fixedSize()
                .accessibilityIdentifier(key)
            #else
                Menu {
                    Picker(label, selection: $value) {
                        ForEach(options, id: \.value) { option in
                            option.labelView()
                                .tag(option.value)
                        }
                    }
                    .accessibilityIdentifier(key)
                } label: {
                    HStack {
                        Spacer()
                        if let selectedOptionLabel = options.first(where: { $0.value == value })?.label {
                            Text(selectedOptionLabel)
                        }
                        else {
                            if let doubleValue = value as? Double {
                                Text("\(doubleValue, specifier: "%.2f")")
                                    .monospacedDigitIfAvailable()
                            }
                            else if let intValue = value as? Int {
                                Text(String(intValue))
                            }
                            else if let stringValue = value as? String {
                                Text(stringValue)
                            }
                            else {
                                Text(String(describing: value))
                            }
                        }
                    }
                }
            #endif
        }
    }
}

/// A view that displays a user interface for changing a setting.
///
/// `DCSettingView` is a view that displays a user interface for changing a setting. The view takes a `DCSettable` instance as an argument
/// and displays the appropriate user interface for the value type of the setting,  if the setting's value is a supported type.
///
/// The view inspects the value type of the setting and displays the appropriate view for that type.
/// If no specific view is available for the value type, the view will be empty.
///
/// Supported types are: non-optional `Bool`, `Int`,  `Double`, `String`, `Date` and `Color`.
/// Color settings are intended for RGB-resolvable user-selected colors.
@MainActor public struct DCSettingView: View {

    private let setting: any DCSettable
    @ObservedObject private var observation: DCSettableObservation

    /// Initializes a new `DCSettingView` instance with the specified setting.
    ///
    /// This initializer creates a new instance of `DCSettingView` with the specified setting. The setting must be an instance of `DCSettable`.
    ///
    /// - Parameter setting: A `DCSettable` instance representing the setting to be managed.
    public init(_ setting: any DCSettable) {
        self.setting = setting
        _observation = ObservedObject(wrappedValue: DCSettableObservation(setting: setting))
    }

    public var body: some View {
        let _ = observation

        if let value = setting._typedBinding(as: Bool.self) {
            DCBoolSettingView(key: setting.key, label: setting.displayLabel, value: value)
        }
        else if let value = setting._typedBinding(as: Int.self) {
            DCIntSettingView(key: setting.key, label: setting.displayLabel, configuration: setting._typedConfiguration(as: Int.self), value: value)
        }
        else if let value = setting._typedBinding(as: Double.self) {
            DCDoubleSettingView(key: setting.key, label: setting.displayLabel, configuration: setting._typedConfiguration(as: Double.self), value: value)
        }
        else if let value = setting._typedBinding(as: String.self) {
            DCStringSettingView(key: setting.key, label: setting.displayLabel, configuration: setting._typedConfiguration(as: String.self), value: value)
        }
        else if let value = setting._typedBinding(as: Date.self) {
            DCDateSettingView(key: setting.key, label: setting.displayLabel, configuration: setting._typedConfiguration(as: Date.self), value: value)
        }
        else if let value = setting._typedBinding(as: Color.self) {
            DCColorSettingView(key: setting.key, label: setting.displayLabel, value: value)
        }
    }
}

struct DCSettingView_Previews: PreviewProvider {

    static var previews: some View {
        VStack {
            DCSettingView(DCSetting(key: "test0", defaultValue: false))
            DCSettingView(DCSetting(key: "test1", defaultValue: 1))
            DCSettingView(DCSetting(key: "test2", defaultValue: 1.0))
            DCSettingView(DCSetting(key: "test3", defaultValue: ""))
            DCSettingView(DCSetting(key: "test4", defaultValue: Date()))
            DCSettingView(DCSetting(key: "test5", defaultValue: Color.red))
        }
        .padding()
    }
}

#endif
