//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit) || canImport(AppKit)
extension Color {

    #if canImport(UIKit)
    typealias NativeColor = UIColor
    #elseif canImport(AppKit)
    typealias NativeColor = NSColor
    #endif

    func dcSettingsEncodedData() throws -> Data {
        let nativeColor = NativeColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        #if canImport(UIKit)
        guard nativeColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            throw DCColorCodingError.unsupportedColorSpace
        }
        #elseif canImport(AppKit)
        guard let rgbColor = nativeColor.usingColorSpace(.deviceRGB) else {
            throw DCColorCodingError.unsupportedColorSpace
        }

        rgbColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif

        let components = DCColorComponents(red: red, green: green, blue: blue, opacity: alpha)
        return try JSONEncoder().encode(components)
    }

    init(dcSettingsData data: Data) throws {
        let components = try JSONDecoder().decode(DCColorComponents.self, from: data)
        self.init(NativeColor(red: components.red, green: components.green, blue: components.blue, alpha: components.opacity))
    }
}

private enum DCColorCodingError: Error {
    case unsupportedColorSpace
}

private struct DCColorComponents: Codable {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
    let opacity: CGFloat

    private enum CodingKeys: String, CodingKey {
        case red
        case green
        case blue
        case opacity
    }

    init(red: CGFloat, green: CGFloat, blue: CGFloat, opacity: CGFloat) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(red, forKey: .red)
        try container.encode(green, forKey: .green)
        try container.encode(blue, forKey: .blue)
        try container.encode(opacity, forKey: .opacity)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        red = try container.decode(CGFloat.self, forKey: .red)
        green = try container.decode(CGFloat.self, forKey: .green)
        blue = try container.decode(CGFloat.self, forKey: .blue)
        opacity = try container.decode(CGFloat.self, forKey: .opacity)
    }
}
#endif
