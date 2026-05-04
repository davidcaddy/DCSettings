//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import Testing
@testable import DCSettings

@Suite struct DCValueBoundsTests {

    @Test func equatable() {
        let bounds1 = DCValueBounds(lowerBound: 0, upperBound: 10)
        let bounds2 = DCValueBounds(lowerBound: 0, upperBound: 10)
        let bounds3 = DCValueBounds(lowerBound: 5, upperBound: 15)

        #expect(bounds1 == bounds2)
        #expect(bounds1 != bounds3)
    }

    @Test func lowerBound() {
        let bounds = DCValueBounds(lowerBound: 0, upperBound: 10)
        #expect(bounds.lowerBound == 0)
    }

    @Test func upperBound() {
        let bounds = DCValueBounds(lowerBound: 0, upperBound: 10)
        #expect(bounds.upperBound == 10)
    }
}
