//
//  Extensions
//
//  Created by David Caddy on 27/4/2023.
//

import Foundation
import SwiftUI

extension Collection {
    func get(_ index: Index) -> Element? {
        if indices.contains(index) {
            return self[index]
        }
        else {
            return nil
        }
    }
}

extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var seen: Set<Iterator.Element> = []
        return filter { seen.insert($0).inserted }
    }
}

public protocol KeyRepresentable {
    var keyValue: String { get }
}

extension String: KeyRepresentable {
    public var keyValue: String {
        return self
    }
}

extension UUID: KeyRepresentable {
    public var keyValue: String {
        return self.uuidString
    }
}

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@available(iOS 14.0, *)
extension Color: Codable {
    #if canImport(UIKit)
    typealias NativeColor = UIColor
    #elseif canImport(AppKit)
    typealias NativeColor = NSColor
    #endif
    
    private enum CodingKeys: String, CodingKey {
        case red
        case green
        case blue
        case opacity
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let nativeColor = NativeColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        nativeColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        try container.encode(red, forKey: .red)
        try container.encode(green, forKey: .green)
        try container.encode(blue, forKey: .blue)
        try container.encode(alpha, forKey: .opacity)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let red = try container.decode(CGFloat.self, forKey: .red)
        let green = try container.decode(CGFloat.self, forKey: .green)
        let blue = try container.decode(CGFloat.self, forKey: .blue)
        let opacity = try container.decode(CGFloat.self, forKey: .opacity)
        self.init(NativeColor(red: red, green: green, blue: blue, alpha: opacity))
    }
}
