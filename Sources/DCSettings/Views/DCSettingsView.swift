//
//  DCSettingsView.swift
//
//  Created by David Caddy on 26/4/2023.
//

import SwiftUI

extension DCSetting {
    var displayLabel: String {
        return label ?? key
    }
}

extension DCSettingOption {
    
    @available(iOS 14.0, *)
    public func labelView() -> some View {
        return HStack {
            if let string = label {
                if let imageName = image {
                    Label(string, image: imageName)
                }
                else if let imageName = systemImage {
                    Label(string, systemImage: imageName)
                }
                else {
                    Text(string)
                }
            }
            else if let imageName = image {
                Image(imageName)
            }
            else if let imageName = systemImage {
                Image(systemName: imageName)
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
            if options.count > 3 {
                HStack {
                    Text(setting.displayLabel)
                    Spacer()
                    Menu {
                        ForEach(options, id: \.label) { option in
                            Button {
                                setting.value = option.value
                            } label: {
                                option.labelView()
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
            if options.count > 3 {
                HStack {
                    Text(setting.displayLabel)
                    Spacer()
                    Menu {
                        ForEach(options, id: \.value) { option in
                            Button {
                                setting.value = option.value
                            } label: {
                                option.labelView()
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
            .animation(nil)
        }
        else {
            DatePicker(selection: $setting.value, in: ...Date.now, displayedComponents: .date) {
                Text(setting.displayLabel)
            }
            .animation(nil)
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

@available(iOS 15.0, *)
public struct DCSettingsView<Provider: DCSettingViewProviding>: View {
    
    private let settingsManager: DCSettingsManager
    
    private let contentProvider: Provider?
    
    private var hiddenKeys: [KeyRepresentable]

    public init(settingsManager: DCSettingsManager = .shared, hiddenKeys: [KeyRepresentable] = [], contentProvider: Provider? = DCDefaultViewProvider()) {
        self.settingsManager = settingsManager
        self.hiddenKeys = hiddenKeys
        self.contentProvider = contentProvider
    }
    
    public var body: some View {
        Self._printChanges()
        return List(settingsManager.groups) { section in
            if !hiddenKeys.contains(where: { $0.keyValue == section.key.keyValue }) {
                Section(section.label ?? "") {
                    ForEach(section.settings, id: \.key) { setting in
                        if !hiddenKeys.contains(where: { $0.keyValue == setting.key.keyValue }) {
                            if let content = contentProvider?.content(for: setting), !(content is EmptyView) {
                                content
                            }
                            else {
                                DCSettingView(setting)
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
