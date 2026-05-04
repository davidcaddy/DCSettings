//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import XCTest
@testable import DCSettings

final class StringExtendedTests: XCTestCase {

    func testSentenceCapitalizedLowercasesRemainingCharacters() {
        XCTAssertEqual("hELLO WORLD".sentenceCapitalized, "Hello world")
    }

    func testSentenceFormattedReplacesUnderscoresAndCamelCase() {
        XCTAssertEqual("great_userSetting2".sentenceFormatted, "Great user setting 2")
    }

    func testSentenceFormattedFormatsAcronymCamelCaseInput() {
        XCTAssertEqual("URLScheme".sentenceFormatted, "URL scheme")
    }

    func testSentenceFormattedPreservesAcronymsAfterFirstWord() {
        XCTAssertEqual("callbackURLScheme".sentenceFormatted, "Callback URL scheme")
    }
}
