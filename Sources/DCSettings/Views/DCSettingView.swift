//
//  DCSettingView.swift
//
//  Created by David Caddy on 17/5/2023.
//

import SwiftUI

extension DCSetting {
    
    var displayLabel: String {
        return label ?? key.replacingOccurrences(of: "_", with: " ").sentenceCapitalized
    }
}

extension DCSettingOption {
    
    @available(iOS 14.0, *)
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

@available(iOS 15.0, *)
struct DCBoolSettingView: View {
    @ObservedObject var setting: DCSetting<Bool>
    
    var body: some View {
        Toggle(setting.displayLabel, isOn: $setting.value)
    }
}

@available(iOS 15.0, *)
struct DCIntSettingView: View {
    @ObservedObject var setting: DCSetting<Int>
    
    var body: some View {
        if let options = setting.configuation?.options {
            if options.count > 2 {
                HStack {
                    Text(setting.displayLabel)
                    Spacer()
                    Menu {
                        Picker(setting.displayLabel, selection: $setting.value) {
                            ForEach(options, id:\.label) { option in
                                option.labelView()
                                    .tag(option.value)
                            }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text(String(setting.value))
                        }
                    }
                }
            }
            else {
                HStack {
                    Text(setting.displayLabel)
                    Spacer(minLength: 16.0)
                    Picker(setting.displayLabel, selection: $setting.value) {
                        ForEach(options, id:\.label) { option in
                            option.labelView()
                                .tag(option.value)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(maxWidth: 160.0)
                }
            }
        }
        else if let bounds = setting.configuation?.bounds {
            VStack {
                HStack {
                    Text(setting.displayLabel)
                    Spacer()
                    Text(String(setting.value))
                        .monospacedDigit()
                }
                if let step = setting.configuation?.step {
                    Slider(value: Binding(get: {
                        Double(setting.value)
                    }, set: { newValue in
                        setting.value = Int(newValue)
                    }), in: Double(bounds.lowerBound)...Double(bounds.upperBound), step: Double(step))
                }
                else {
                    Slider(value: Binding(get: {
                        Double(setting.value)
                    }, set: { newValue in
                        setting.value = Int(newValue)
                    }), in: Double(bounds.lowerBound)...Double(bounds.upperBound))
                }
            }
        }
        else {
            HStack {
                Text(setting.displayLabel)
                Spacer()
                Text(String(setting.value))
                    .padding(.trailing, 8.0)
                Stepper(setting.displayLabel, value: $setting.value)
                    .labelsHidden()
            }
        }
    }
}

@available(iOS 15.0, *)
struct DCDoubleSettingView: View {
    @ObservedObject var setting: DCSetting<Double>
    
    var body: some View {
        VStack {
            HStack {
                Text(setting.displayLabel)
                Spacer()
                Text("\(setting.value, specifier: "%.2f")")
                    .monospacedDigit()
            }
            if let bounds = setting.configuation?.bounds {
                if let step = setting.configuation?.step {
                    Slider(value: $setting.value, in: bounds.lowerBound...bounds.upperBound, step: step)
                }
                else {
                    Slider(value: $setting.value, in: bounds.lowerBound...bounds.upperBound)
                }
            }
            else {
                Slider(value: $setting.value)
            }
        }
    }
}

@available(iOS 15.0, *)
struct DCStringSettingView: View {
    @ObservedObject var setting: DCSetting<String>
    
    var body: some View {
        if let options = setting.configuation?.options {
            if options.count > 2 {
                HStack {
                    Text(setting.displayLabel)
                    Spacer()
                    Menu {
                        Picker(setting.displayLabel, selection: $setting.value) {
                            ForEach(options, id:\.label) { option in
                                option.labelView()
                                    .tag(option.value)
                            }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text(setting.value)
                        }
                    }
                }
            }
            else {
                HStack {
                    Text(setting.displayLabel)
                    Spacer(minLength: 16.0)
                    Picker(setting.displayLabel, selection: $setting.value) {
                        ForEach(options, id:\.label) { option in
                            option.labelView()
                                .tag(option.value)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(maxWidth: 160.0)
                }
            }
        }
        else {
            TextField(setting.displayLabel, text: $setting.value)
        }
    }
}

@available(iOS 15.0, *)
struct DCDateSettingView: View {
    @ObservedObject var setting: DCSetting<Date>
    
    var body: some View {
        if let bounds = setting.configuation?.bounds {
            DatePicker(selection: $setting.value, in: bounds.upperBound...bounds.upperBound, displayedComponents: .date) {
                Text(setting.displayLabel)
            }
        }
        else {
            DatePicker(selection: $setting.value, in: ...Date.now, displayedComponents: .date) {
                Text(setting.displayLabel)
            }
        }
    }
}

@available(iOS 15.0, *)
struct DCColorSettingView: View {
    @ObservedObject var setting: DCSetting<Color>
    
    private var label: String {
        return setting.label ?? setting.key
    }
    
    var body: some View {
        ColorPicker(label, selection: $setting.value)
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
@available(iOS 15.0, *)
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

@available(iOS 15.0, *)
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
