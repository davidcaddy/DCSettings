//
//  DCSettingConfigurationTests.swift
//
//  Created by David Caddy on 17/5/2023.
//

import XCTest
@testable import DCSettings

class DCSettingConfigurationTests: XCTestCase {
    
    func testInitWithOptions() {
        let options = [
            DCSettingOption(value: "option1"),
            DCSettingOption(value: "option2"),
            DCSettingOption(value: "option3")
        ]
        let configuration = DCSettingConfiguration(options: options, bounds: nil, step: nil)
        XCTAssertEqual(configuration.options?.count, 3)
    }
    
    func testInitWithBounds() {
        let bounds = DCValueBounds(lowerBound: 0, upperBound: 10)
        let configuration = DCSettingConfiguration(options: nil, bounds: bounds, step: nil)
        XCTAssertEqual(configuration.bounds?.lowerBound, 0)
        XCTAssertEqual(configuration.bounds?.upperBound, 10)
    }
    
    func testInitWithStep() {
        let step = 2
        let configuration = DCSettingConfiguration(options: nil, bounds: nil, step: step)
        XCTAssertEqual(configuration.step, 2)
    }
}