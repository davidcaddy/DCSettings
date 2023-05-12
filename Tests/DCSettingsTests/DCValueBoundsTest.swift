//
//  DCValueBoundsTests.swift
//
//  Created by David Caddy on 12/5/2023.
//

import XCTest
@testable import DCSettings

final class DCValueBoundsTests: XCTestCase {

    func testDCValueBounds() {
        let valueBounds = DCValueBounds(lowerBound: 1, upperBound: 10)
        XCTAssertEqual(valueBounds.lowerBound, 1)
        XCTAssertEqual(valueBounds.upperBound, 10)
    }

}

