//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import Testing
import Foundation
@testable import DCSettings

@Suite @MainActor struct DCSettingViewTests {

    @Test func displayLabelUsesExplicitLabel() {
        let setting = DCSetting(key: "articleListLayout", defaultValue: true, label: "Layout")

        #expect(setting.displayLabel == "Layout")
    }

    @Test func displayLabelFormatsKeyWhenLabelIsMissing() {
        let setting = DCSetting(key: "articleListLayout", defaultValue: true)

        #expect(setting.displayLabel == "Article list layout")
    }

    @Test func optionControlStyleUsesPickerForTwoOrFewerOptions() {
        #expect(DCOptionControlStyle(optionCount: 0) == .picker)
        #expect(DCOptionControlStyle(optionCount: 1) == .picker)
        #expect(DCOptionControlStyle(optionCount: 2) == .picker)
    }

    @Test func optionControlStyleUsesMenuPickerForMoreThanTwoOptions() {
        #expect(DCOptionControlStyle(optionCount: 3) == .menuPicker)
        #expect(DCOptionControlStyle(optionCount: 10) == .menuPicker)
    }

    @Test func datePickerRangeUsesLowerAndUpperBounds() {
        let lowerBound = Date(timeIntervalSince1970: 1_704_067_200)
        let upperBound = Date(timeIntervalSince1970: 1_735_689_600)
        let bounds = DCValueBounds(lowerBound: lowerBound, upperBound: upperBound)

        let range = DCDateSettingView.datePickerRange(for: bounds)

        #expect(range.lowerBound == lowerBound)
        #expect(range.upperBound == upperBound)
    }
}
