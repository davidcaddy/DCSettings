//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import SwiftUI

extension DCSetting {
    
    var displayLabel: String {
        return label ?? key.sentenceFormatted
    }
}

extension DCSettingOption {
    
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 9.0, *)
    public func labelView() -> some View {
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

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 9.0, *)
struct DCBoolSettingView: View {
    @Environment(\.isEnabled) var isEnabled
    
    @ObservedObject var setting: DCSetting<Bool>
    
    var body: some View {
        Toggle(setting.displayLabel, isOn: $setting.value)
            .toggleStyle(SwitchToggleStyle())
            .accessibilityIdentifier(setting.key)
            .foregroundColor(isEnabled ? .primary : .secondary)
            #if os(macOS)
                .controlSize(.mini)
            #endif
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 9.0, *)
struct DCIntSettingView: View {
    @Environment(\.isEnabled) var isEnabled
    
    @ObservedObject var setting: DCSetting<Int>
    
    var body: some View {
        if let options = setting.configuation?.options {
            if options.count > 2 {
                DCMenuPickerView(key: setting.key, label: setting.displayLabel, options: options, value: $setting.value)
            }
            else {
                HStack {
                    Text(setting.displayLabel)
                    Spacer(minLength: 16.0)
                    Picker(setting.displayLabel, selection: $setting.value) {
                        ForEach(options, id: \.value) { option in
                            option.labelView()
                                .tag(option.value)
                        }
                    }
                    .labelsHidden()
                    .accessibilityIdentifier(setting.key)
                    #if os(macOS)
                        .pickerStyle(RadioGroupPickerStyle())
                        .horizontalRadioGroupLayout()
                    #elseif !os(watchOS)
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(maxWidth: 150.0)
                    #endif
                }
                .foregroundColor(isEnabled ? .primary : .secondary)
            }
        }
        else if let bounds = setting.configuation?.bounds {
            DCSliderView(key: setting.key, label: setting.displayLabel, value: Binding(get: {
                Double(setting.value)
            }, set: { newValue in
                setting.value = Int(newValue)
            }), bounds: DCValueBounds(lowerBound: Double(bounds.lowerBound), upperBound: Double(bounds.upperBound)), step: Double(setting.configuation?.step ?? 0), specifier: "%.0f")
        }
        else {
            HStack {
                Text(setting.displayLabel)
                    .foregroundColor(isEnabled ? .primary : .secondary)
                Spacer()
                Text(String(setting.value))
                    .padding(.trailing, 8.0)
                Stepper(setting.displayLabel, value: $setting.value)
                    .labelsHidden()
                    .accessibilityIdentifier(setting.key)
            }
            .foregroundColor(isEnabled ? .primary : .secondary)
        }
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 9.0, *)
struct DCDoubleSettingView: View {
    @ObservedObject var setting: DCSetting<Double>
    
    var body: some View {
        if let options = setting.configuation?.options, options.count > 2 {
            DCMenuPickerView(key: setting.key, label: setting.displayLabel, options: options, value: $setting.value)
        }
        else {
            DCSliderView(key: setting.key, label: setting.displayLabel, value: $setting.value, bounds: setting.configuation?.bounds, step: setting.configuation?.step, specifier: "%.2f")
        }
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 9.0, *)
struct DCStringSettingView: View {
    @Environment(\.isEnabled) var isEnabled
    
    @ObservedObject var setting: DCSetting<String>
    
    var body: some View {
        if let options = setting.configuation?.options {
            if options.count > 2 {
                DCMenuPickerView(key: setting.key, label: setting.displayLabel, options: options, value: $setting.value)
            }
            else {
                HStack {
                    Text(setting.displayLabel)
                    Spacer(minLength: 16.0)
                    Picker(setting.displayLabel, selection: $setting.value) {
                        ForEach(options, id: \.value) { option in
                            option.labelView()
                                .tag(option.value)
                        }
                    }
                    .labelsHidden()
                    .accessibilityIdentifier(setting.key)
                    #if os(macOS)
                        .pickerStyle(RadioGroupPickerStyle())
                        .horizontalRadioGroupLayout()
                    #elseif os(iOS)
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(maxWidth: 150.0)
                    #endif
                }
                .foregroundColor(isEnabled ? .primary : .secondary)
            }
        }
        else {
            TextField(setting.displayLabel, text: $setting.value)
                .foregroundColor(isEnabled ? .primary : .secondary)
                .accessibilityIdentifier(setting.key)
        }
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 9.0, *)
struct DCDateSettingView: View {
    @Environment(\.isEnabled) var isEnabled
    
    @ObservedObject var setting: DCSetting<Date>
    
    var body: some View {
        #if os(watchOS)
            // TODO: watchOS implementation
            Text(setting.displayLabel)
        #else
            if let bounds = setting.configuation?.bounds {
                DatePicker(selection: $setting.value, in: bounds.upperBound...bounds.upperBound, displayedComponents: .date) {
                    Text(setting.displayLabel)
                }
                .foregroundColor(isEnabled ? .primary : .secondary)
                .accessibilityIdentifier(setting.key)
            }
            else {
                DatePicker(selection: $setting.value, in: ...Date.now, displayedComponents: .date) {
                    Text(setting.displayLabel)
                }
                .foregroundColor(isEnabled ? .primary : .secondary)
                .accessibilityIdentifier(setting.key)
            }
        #endif
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 9.0, *)
struct DCColorSettingView: View {
    @Environment(\.isEnabled) var isEnabled
    
    @ObservedObject var setting: DCSetting<Color>
    
    var body: some View {
        #if os(watchOS)
            // TODO: watchOS implementation
            Text(setting.displayLabel)
        #else
            ColorPicker(setting.displayLabel, selection: $setting.value)
            .foregroundColor(isEnabled ? .primary : .secondary)
            .accessibilityIdentifier(setting.key)
        #endif
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 9.0, *)
struct DCSliderView: View {
    @Environment(\.isEnabled) var isEnabled
    
    let key: String
    let label: String
    @Binding var value: Double
    let bounds: DCValueBounds<Double>?
    let step: Double?
    let specifier: String
    
    var body: some View {
        VStack {
            HStack {
                Text(label)
                Spacer()
                Text("\(value, specifier: specifier)")
                    .monospacedDigit()
            }
            if let valueBounds = bounds {
                if let valueStep = step {
                    Slider(value: $value, in: valueBounds.lowerBound...valueBounds.upperBound, step: valueStep) {
                        Text(label)
                    } minimumValueLabel: {
                        Text("\(valueBounds.lowerBound, specifier: specifier)")
                            .monospacedDigit()
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    } maximumValueLabel: {
                        Text("\(valueBounds.upperBound, specifier: specifier)")
                            .monospacedDigit()
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                    .labelsHidden()
                    .accessibilityIdentifier(key)
                }
                else {
                    Slider(value: $value, in: valueBounds.lowerBound...valueBounds.upperBound) {
                        Text(label)
                    } minimumValueLabel: {
                        Text("\(valueBounds.lowerBound, specifier: specifier)")
                            .monospacedDigit()
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    } maximumValueLabel: {
                        Text("\(valueBounds.upperBound, specifier: specifier)")
                            .monospacedDigit()
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                    .labelsHidden()
                    .accessibilityIdentifier(key)
                }
            }
            else {
                Slider(value: $value)
                    .accessibilityIdentifier(key)
            }
        }
        .foregroundColor(isEnabled ? .primary : .secondary)
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 9.0, *)
struct DCMenuPickerView<ValueType>: View where ValueType: Equatable & Hashable {
    @Environment(\.isEnabled) var isEnabled
    
    let key: String
    let label: String
    let options: [DCSettingOption<ValueType>]
    @Binding var value: ValueType
    
    var body: some View {
        HStack {
            Text(label)
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
                                    .monospacedDigit()
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
        .foregroundColor(isEnabled ? .primary : .secondary)
    }
}

/// A view that displays a user interface for changing a setting.
///
/// `DCSettingView` is a view that displays a user interface for changing a setting. The view takes a `DCSettable` instance as an argument
/// and displays the appropriate user interface for the value type of the setting,  if the setting's value is a supported type.
///
/// The view uses type casting to determine the value type of the setting and displays the appropriate view for that type.
/// If no specific view is available for the value type, the view will be empty.
///
/// Supported types are: `Bool`, `Int`,  `Double`, `String`, `Date` and `Color`.
@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 9.0, *)
public struct DCSettingView: View {
    
    private let setting: any DCSettable
    
    /// Initializes a new `DCSettingView` instance with the specified setting.
    ///
    /// This initializer creates a new instance of `DCSettingView` with the specified setting. The setting must be an instance of `DCSettable`.
    ///
    /// - Parameter setting: A `DCSettable` instance representing the setting to be managed.
    public init(_ setting: any DCSettable) {
        self.setting = setting
    }
    
    public var body: some View {
        if let concreteSetting = setting as? DCSetting<Bool> {
            DCBoolSettingView(setting: concreteSetting)
        }
        else if let concreteSetting = setting as? DCSetting<Int> {
            DCIntSettingView(setting: concreteSetting)
        }
        else if let concreteSetting = setting as? DCSetting<Double> {
            DCDoubleSettingView(setting: concreteSetting)
        }
        else if let concreteSetting = setting as? DCSetting<String> {
            DCStringSettingView(setting: concreteSetting)
        }
        else if let concreteSetting = setting as? DCSetting<Date> {
            DCDateSettingView(setting: concreteSetting)
        }
        else if let concreteSetting = setting as? DCSetting<Color> {
            DCColorSettingView(setting: concreteSetting)
        }
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 9.0, *)
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
