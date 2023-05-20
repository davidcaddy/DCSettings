//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
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
        XCTAssertEqual(configuration.options, options)
    }
    
    func testInitWithBounds() {
        let bounds = DCValueBounds(lowerBound: 0, upperBound: 10)
        let configuration = DCSettingConfiguration(options: nil, bounds: bounds, step: nil)
        
        XCTAssertEqual(configuration.bounds, bounds)
    }
    
    func testInitWithStep() {
        let configuration = DCSettingConfiguration(options: nil, bounds: nil, step: 2)
        
        XCTAssertEqual(configuration.step, 2)
    }
}
