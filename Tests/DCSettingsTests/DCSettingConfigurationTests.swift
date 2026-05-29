//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import Testing
@testable import DCSettings

@Suite struct DCSettingConfigurationTests {

    @Test func initWithOptions() {
        let options = [
            DCSettingOption(value: "option1"),
            DCSettingOption(value: "option2"),
            DCSettingOption(value: "option3")
        ]
        let configuration = DCSettingConfiguration(options: options, bounds: nil, step: nil)

        #expect(configuration.options?.count == 3)
        #expect(configuration.options == options)
    }

    @Test func duplicateOptionValuesAreDetected() {
        let uniqueOptions = [
            DCSettingOption(value: "option1"),
            DCSettingOption(value: "option2")
        ]
        let duplicateOptions = [
            DCSettingOption(value: "option1", label: "First"),
            DCSettingOption(value: "option1", label: "Duplicate")
        ]

        #expect(!DCSettingConfiguration<String>.hasDuplicateOptionValues(nil))
        #expect(!DCSettingConfiguration.hasDuplicateOptionValues(uniqueOptions))
        #expect(DCSettingConfiguration.hasDuplicateOptionValues(duplicateOptions))
    }

    @Test func initWithBounds() {
        let bounds = DCValueBounds(lowerBound: 0, upperBound: 10)
        let configuration = DCSettingConfiguration(options: nil, bounds: bounds, step: nil)

        #expect(configuration.bounds == bounds)
    }

    @Test func initWithStep() {
        let configuration = DCSettingConfiguration(options: nil, bounds: nil, step: 2)

        #expect(configuration.step == 2)
    }
}
