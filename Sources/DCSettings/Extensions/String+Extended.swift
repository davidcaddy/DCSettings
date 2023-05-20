//
//  String+Extended.swift
//
//  Created by David Caddy on 27/4/2023.
//

import Foundation

extension String {
    
    var sentenceCapitalized: String {
        let firstLetter = self.prefix(1).capitalized
        let remainingLetters = self.dropFirst().lowercased()
        return firstLetter + remainingLetters
    }
    
    var sentenceFormatted: String {
        self.replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: "([A-Z0-9]+)", with: " $1", options: .regularExpression, range: range(of: self)).trimmingCharacters(in: .whitespacesAndNewlines).sentenceCapitalized
    }
}
