//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import Testing
import Foundation
import SwiftUI
@testable import DCSettings
import Combine

#if !os(tvOS)

@Suite @MainActor struct DCSettingViewTests {

    @MainActor private final class CustomSettable<ValueType: Equatable>: DCSettable {
        let label: String?
        let key: String
        let configuration: DCSettingConfiguration<ValueType>?
        var store: DCSettingStore?
        var value: ValueType

        init(key: String, value: ValueType, label: String? = nil, configuration: DCSettingConfiguration<ValueType>? = nil) {
            self.key = key
            self.value = value
            self.label = label
            self.configuration = configuration
        }

        func refresh() {}
    }

    @Test func displayLabelUsesExplicitLabel() {
        let setting = DCSetting(key: "articleListLayout", defaultValue: true, label: "Layout")

        #expect(setting.displayLabel == "Layout")
    }

    @Test func displayLabelFormatsKeyWhenLabelIsMissing() {
        let setting = DCSetting(key: "articleListLayout", defaultValue: true)

        #expect(setting.displayLabel == "Article list layout")
    }

    @Test func displayLabelSupportsCustomSettableConformers() {
        let setting = CustomSettable(key: "articleListLayout", value: true)

        #expect(setting.displayLabel == "Article list layout")
    }

    @Test func settingViewAcceptsCustomSettableConformers() {
        let setting = CustomSettable(key: "showImages", value: true)
        let view = DCSettingView(setting)

        _ = view.body
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

    @Test func sliderUsableStepIgnoresInvalidSteps() {
        #expect(DCSliderView.usableStep(nil) == nil)
        #expect(DCSliderView.usableStep(0.0) == nil)
        #expect(DCSliderView.usableStep(-1.0) == nil)
        #expect(DCSliderView.usableStep(.nan) == nil)
        #expect(DCSliderView.usableStep(.infinity) == nil)
        #expect(DCSliderView.usableStep(0.25) == 0.25)
    }

    @Test func doubleSettingViewUsesSliderOnlyWhenBoundsAreDefined() {
        let boundedConfiguration = DCSettingConfiguration<Double>(bounds: DCValueBounds(lowerBound: 0.0, upperBound: 1.0))
        let optionConfiguration = DCSettingConfiguration<Double>(options: [
            DCSettingOption(value: 0.5, label: "Half"),
            DCSettingOption(value: 1.0, label: "Full")
        ])
        let optionAndBoundsConfiguration = DCSettingConfiguration<Double>(
            options: [
                DCSettingOption(value: 0.5, label: "Half"),
                DCSettingOption(value: 1.0, label: "Full")
            ],
            bounds: DCValueBounds(lowerBound: 0.0, upperBound: 1.0)
        )

        #expect(DCDoubleSettingView.usesSlider(configuration: boundedConfiguration))
        #expect(!DCDoubleSettingView.usesNumericTextField(configuration: boundedConfiguration))
        #expect(!DCDoubleSettingView.usesSlider(configuration: optionConfiguration))
        #expect(!DCDoubleSettingView.usesNumericTextField(configuration: optionConfiguration))
        #expect(!DCDoubleSettingView.usesSlider(configuration: optionAndBoundsConfiguration))
        #expect(!DCDoubleSettingView.usesNumericTextField(configuration: optionAndBoundsConfiguration))
        #expect(!DCDoubleSettingView.usesSlider(configuration: nil))
        #expect(DCDoubleSettingView.usesNumericTextField(configuration: nil))
    }

    @Test func doubleTextFieldFormatterSupportsDecimalValues() {
        let value = DCDoubleTextFieldView.formatter.string(from: NSNumber(value: 1.25))
        let decimalSeparator = DCDoubleTextFieldView.formatter.decimalSeparator ?? "."

        #expect(value == "1\(decimalSeparator)25")
    }

    @Test func displayOnlyDateViewExposesBody() {
        let view = DCDisplayOnlyDateView(key: "publishedDate", label: "Published Date", value: Date(timeIntervalSince1970: 1_704_067_200))

        _ = view.body
    }

    @Test func displayOnlyColorViewExposesBody() {
        let view = DCDisplayOnlyColorView(key: "highlightColor", label: "Highlight Color", value: .blue)

        _ = view.body
    }
}

#endif
