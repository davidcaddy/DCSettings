//
//  DCSettingOptionTests.swift
//  
//  Created by David Caddy on 12/5/2023.
//

import XCTest
@testable import DCSettings

final class DCSettingOptionTests: XCTestCase {
    
    func testEquatable() {
        let option1 = DCSettingOption(value: "Value1", label: "Label1", image: "Image1")
        let option2 = DCSettingOption(value: "Value1", label: "Label1", image: "Image1")
        let option3 = DCSettingOption(value: "Value2", label: "Label2", image: "Image2")
        
        XCTAssertEqual(option1, option2)
        XCTAssertNotEqual(option1, option3)
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
}
