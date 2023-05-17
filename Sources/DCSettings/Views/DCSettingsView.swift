//
//  DCSettingsView.swift
//
//  Created by David Caddy on 26/4/2023.
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

@available(iOS 15.0, *)
public struct DCSettingView: View {
    let setting: any DCSettable
    
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


public protocol DCSettingViewProviding {
    associatedtype Content: View
    
    func content(for setting: any DCSettable) -> Content?
}

public extension DCSettingViewProviding {
    @ViewBuilder func content(for setting: any DCSettable) -> (some View)? {}
}

public struct DCDefaultViewProvider: DCSettingViewProviding {}

/**
 `DCSettingsView` is a SwiftUI view that displays a list of your app's settings.
 
 You can create an instance of `DCSettingsView` and add it to your app's view hierarchy like any other SwiftUI view. When displayed, the view will show a list of all the setting groups and settings that you've configured using the `DCSettingsManager.shared.configure` method.
 
 `DCSettingsView` has several customization options available. For example, you can specify an array of hidden keys to hide certain setting groups or individual settings. You can also provide a custom content provider to control how each setting is displayed.
 */
@available(iOS 15.0, *)
public struct DCSettingsView<Provider: DCSettingViewProviding>: View {
    
    private let settingsManager: DCSettingsManager
    
    private var includeSettingsWithoutLabels: Bool
    
    private var hiddenKeys: [String]
    
    private let contentProvider: Provider?

    public init(settingsManager: DCSettingsManager = .shared, includeSettingsWithoutLabels: Bool = false, hiddenKeys: [KeyRepresentable] = [], contentProvider: Provider? = DCDefaultViewProvider()) {
        self.settingsManager = settingsManager
        self.includeSettingsWithoutLabels = includeSettingsWithoutLabels
        self.hiddenKeys = hiddenKeys.map({ $0.keyValue })
        self.contentProvider = contentProvider
    }
    
    public var body: some View {
        List(settingsManager.groups) { group in
            if !hiddenKeys.contains(group.key.keyValue) {
                Section(group.label ?? "") {
                    ForEach(group.settings, id: \.key) { setting in
                        if ((setting.label != nil) || includeSettingsWithoutLabels) && !hiddenKeys.contains(setting.key.keyValue) {
                            if let content = contentProvider?.content(for: setting), !(content is EmptyView) {
                                content
                                    .animation(nil)
                            }
                            else {
                                DCSettingView(setting)
                                    .animation(nil)
                            }
                        }
                    }
                }
            }
        }
        .animation(.default)
    }
}

@available(iOS 15.0, *)
struct DCSettingsView_Previews: PreviewProvider {

    static var previews: some View {
        DCSettingsView()
    }
}
