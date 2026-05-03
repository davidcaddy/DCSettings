//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import XCTest
@testable import DCSettings

final class DCSettingOptionTests: XCTestCase {
    
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
    
    func testEquatable() {
        let option1 = DCSettingOption(value: "Value1", label: "Label1", image: "Image1")
        let option2 = DCSettingOption(value: "Value1", label: "Label1", image: "Image1")
        let option3 = DCSettingOption(value: "Value2", label: "Label2", image: "Image2")
        
        XCTAssertEqual(option1, option2)
        XCTAssertNotEqual(option1, option3)
    }
    
    func testLabel() {
        let option = DCSettingOption(value: "Value", label: "Label", image: "Image")
        XCTAssertEqual(option.label, "Label")
    }
    
    func testValue() {
        let option = DCSettingOption(value: "Value", label: "Label", image: "Image")
        XCTAssertEqual(option.value, "Value")
    }
    
    func testCustomImage() {
        let option = DCSettingOption(value: "Value", label: "Label", image: "Image")
        XCTAssertEqual(option.image, .custom("Image"))
    }
    
    func testSystemImage() {
        let option = DCSettingOption(value: "Value", label: "Label", systemImage: "SystemImage")
        XCTAssertEqual(option.image, .system("SystemImage"))
    }
    
    func testDefaultOption() {
        let option = DCSettingOption(value: "Value", default: true)
        XCTAssertTrue(option.isDefault)
    }
    
    func testDefaultModifierReturnsDefaultOption() {
        let option = DCSettingOption(value: "Value", label: "Label").default()
        
        XCTAssertTrue(option.isDefault)
        XCTAssertEqual(option.label, "Label")
        XCTAssertEqual(option.value, "Value")
    }
    
    func testImageOnlyInitializers() {
        let customImageOption = DCSettingOption(value: "Value", image: "Image")
        let systemImageOption = DCSettingOption(value: "Value", systemImage: "SystemImage")
        
        XCTAssertNil(customImageOption.label)
        XCTAssertEqual(customImageOption.image, .custom("Image"))
        XCTAssertNil(systemImageOption.label)
        XCTAssertEqual(systemImageOption.image, .system("SystemImage"))
    }
    
    func testDefaultOptionProvidingImplementations() {
        XCTAssertNil(StringDefaultOption.defaultCase)
        XCTAssertNil(StringDefaultOption.sample.label)
        XCTAssertNil(StringDefaultOption.sample.image)
    }
    
    func testOptionsProviderInitializerUsesProviderMetadata() {
        let setting = DCSetting(key: "optionProvider", optionsProvider: TestOption.self)
        
        XCTAssertEqual(setting?.value, TestOption.second.rawValue)
        XCTAssertEqual(setting?.configuation?.options?.first?.label, "First")
        XCTAssertEqual(setting?.configuation?.options?.first?.image, .system("first"))
    }
    
    private enum StringDefaultOption: String, DCSettingOptionProviding {
        case sample
    }
}
