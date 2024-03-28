//
//  DCSettings
//  Copyright (c) David Caddy 2024
//  MIT license, see LICENSE file for details
//

import SwiftUI

extension Text {
    
    public func monospacedDigitIfAvailable() -> Text {
        if #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 9.0, visionOS 1.0, *) {
            return self.monospacedDigit()
        } else {
            return self
        }
    }
}
