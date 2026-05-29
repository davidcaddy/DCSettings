//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import Testing
@testable import DCSettings

@Suite @MainActor struct DCSettingOptionTests {

    private enum TestOption: String, DCSettingOptionProviding {
        case first
        case second

        static var defaultCase: TestOption? {
            return .second
        }

        var label: String? {
            return rawValue.sentenceFormatted
        }

        var image: DCImageName? {
            return .system(rawValue)
        }
    }

    @Test func equatable() {
        let option1 = DCSettingOption(value: "Value1", label: "Label1", image: "Image1")
        let option2 = DCSettingOption(value: "Value1", label: "Label1", image: "Image1")
        let option3 = DCSettingOption(value: "Value2", label: "Label2", image: "Image2")

        #expect(option1 == option2)
        #expect(option1 != option3)
    }

    @Test func label() {
        let option = DCSettingOption(value: "Value", label: "Label", image: "Image")
        #expect(option.label == "Label")
    }

    @Test func value() {
        let option = DCSettingOption(value: "Value", label: "Label", image: "Image")
        #expect(option.value == "Value")
    }

    @Test func customImage() {
        let option = DCSettingOption(value: "Value", label: "Label", image: "Image")
        #expect(option.image == .custom("Image"))
    }

    @Test func systemImage() {
        let option = DCSettingOption(value: "Value", label: "Label", systemImage: "SystemImage")
        #expect(option.image == .system("SystemImage"))
    }

    @Test func defaultOption() {
        let option = DCSettingOption(value: "Value", default: true)
        #expect(option.isDefault)
    }

    @Test func defaultModifierReturnsDefaultOption() {
        let option = DCSettingOption(value: "Value", label: "Label").default()

        #expect(option.isDefault)
        #expect(option.label == "Label")
        #expect(option.value == "Value")
    }

    @Test func imageOnlyInitializers() {
        let customImageOption = DCSettingOption(value: "Value", image: "Image")
        let systemImageOption = DCSettingOption(value: "Value", systemImage: "SystemImage")

        #expect(customImageOption.label == nil)
        #expect(customImageOption.image == .custom("Image"))
        #expect(systemImageOption.label == nil)
        #expect(systemImageOption.image == .system("SystemImage"))
    }

    @Test func defaultOptionProvidingImplementations() {
        #expect(StringDefaultOption.defaultCase == nil)
        #expect(StringDefaultOption.sample.label == nil)
        #expect(StringDefaultOption.sample.image == nil)
    }

    @Test func optionsProviderInitializerUsesProviderMetadata() throws {
        let setting = try #require(DCSetting(key: "optionProvider", optionsProvider: TestOption.self))

        #expect(setting.value == TestOption.second.rawValue)
        #expect(setting.configuration?.options?.first?.label == "First")
        #expect(setting.configuration?.options?.first?.image == .system("first"))
    }

    @Test func optionsBuilderSupportsEmptyBody() {
        let setting: DCSetting<String>? = DCSetting(key: "emptyOptions") {
        }

        #expect(setting == nil)
    }

    @Test func optionsBuilderSupportsControlFlow() throws {
        let includeSecond = false
        let selectedValue = "switch"
        let setting = try #require(DCSetting(key: "controlFlowOptions") {
            DCSettingOption(value: "first", label: "First")

            if includeSecond {
                DCSettingOption(value: "second", label: "Second").default()
            }
            else {
                DCSettingOption(value: "fallback", label: "Fallback").default()
            }

            for value in ["third", "fourth"] {
                DCSettingOption(value: value, label: value.sentenceFormatted)
            }

            switch selectedValue {
            case "switch":
                DCSettingOption(value: "switch", label: "Switch")
            default:
                DCSettingOption(value: "default", label: "Default")
            }
        })

        #expect(setting.value == "fallback")
        #expect(setting.configuration?.options?.map(\.value) == ["first", "fallback", "third", "fourth", "switch"])
    }

    private enum StringDefaultOption: String, DCSettingOptionProviding {
        case sample
    }
}
