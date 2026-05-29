//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import Testing
@testable import DCSettings

@Suite struct StringExtendedTests {

    @Test func sentenceCapitalizedLowercasesRemainingCharacters() {
        #expect("hELLO WORLD".sentenceCapitalized == "Hello world")
    }

    @Test func sentenceFormattedReplacesUnderscoresAndCamelCase() {
        #expect("great_userSetting2".sentenceFormatted == "Great user setting 2")
    }

    @Test func sentenceFormattedFormatsAcronymCamelCaseInput() {
        #expect("URLScheme".sentenceFormatted == "URL scheme")
    }

    @Test func sentenceFormattedPreservesAcronymsAfterFirstWord() {
        #expect("callbackURLScheme".sentenceFormatted == "Callback URL scheme")
    }
}
