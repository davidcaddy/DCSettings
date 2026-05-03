//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import XCTest
@testable import DCSettings

final class DCSettingViewTests: XCTestCase {
    
    func testDisplayLabelUsesExplicitLabel() {
        let setting = DCSetting(key: "articleListLayout", defaultValue: true, label: "Layout")
        
        XCTAssertEqual(setting.displayLabel, "Layout")
    }
    
    func testDisplayLabelFormatsKeyWhenLabelIsMissing() {
        let setting = DCSetting(key: "articleListLayout", defaultValue: true)
        
        XCTAssertEqual(setting.displayLabel, "Article list layout")
    }
    
    func testOptionControlStyleUsesPickerForTwoOrFewerOptions() {
        XCTAssertEqual(DCOptionControlStyle(optionCount: 0), .picker)
        XCTAssertEqual(DCOptionControlStyle(optionCount: 1), .picker)
        XCTAssertEqual(DCOptionControlStyle(optionCount: 2), .picker)
    }
    
    func testOptionControlStyleUsesMenuPickerForMoreThanTwoOptions() {
        XCTAssertEqual(DCOptionControlStyle(optionCount: 3), .menuPicker)
        XCTAssertEqual(DCOptionControlStyle(optionCount: 10), .menuPicker)
    }
}

