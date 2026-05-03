//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import Foundation

extension String {
    
    var sentenceCapitalized: String {
        let firstLetter = self.prefix(1).capitalized
        let remainingLetters = self.dropFirst().lowercased()
        return firstLetter + remainingLetters
    }
    
    var sentenceFormatted: String {
        let separatedWords = self
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "([A-Z]+)([A-Z][a-z])", with: "$1 $2", options: .regularExpression)
            .replacingOccurrences(of: "([a-z0-9])([A-Z])", with: "$1 $2", options: .regularExpression)
            .replacingOccurrences(of: "([A-Za-z])([0-9])", with: "$1 $2", options: .regularExpression)
            .replacingOccurrences(of: "([0-9])([A-Za-z])", with: "$1 $2", options: .regularExpression)
        
        return separatedWords
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .enumerated()
            .map { index, word in
                if word.isUppercaseAcronym {
                    return word
                }
                
                return index == 0 ? word.sentenceCapitalized : word.lowercased()
            }
            .joined(separator: " ")
    }
}

private extension String {
    
    var isUppercaseAcronym: Bool {
        range(of: #"^[A-Z0-9]+$"#, options: .regularExpression) != nil
    }
}
