//
//  DCSettings
//  Copyright (c) David Caddy 2024
//  MIT license, see LICENSE file for details
//

import SwiftUI

extension Text {
    
    public func monospacedDigitIfAvailable() -> Text {
        if #available(iOS 15.0, *) {
            return self.monospacedDigit()
        } else {
            return self
        }
    }
}
