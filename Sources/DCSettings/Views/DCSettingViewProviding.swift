//
//  DCSettingViewProviding.swift
//
//  Created by David Caddy on 17/5/2023.
//

import SwiftUI

/// A protocol that defines the requirements for a type that provides custom views for settings.
///
/// The `DCSettingViewProviding` protocol defines the requirements for a type that provides custom views for settings.
/// The protocol includes a `content` method that takes a `DCSettable` instance as an argument
/// and returns an optional view representing the user interface for changing the setting.
public protocol DCSettingViewProviding {
    
    /// The type of view returned by the `content` method.
    associatedtype Content: View
    
    /// Returns a view representing the user interface for changing the specified setting.
    ///
    /// This method takes a `DCSettable` instance as an argument and returns an optional view representing the user interface for managing the setting.
    /// If no custom view is available for the specified setting, this method should return `nil`.
    ///
    /// - Parameter setting: A `DCSettable` instance representing the setting to be managed.
    /// - Returns: An optional view representing the user interface for managing the specified setting.
    func content(for setting: any DCSettable) -> Content?
}

/// A type that provides no custom views for settings.
///
/// `DCDefaultViewProvider` is a concrete implementation of the `DCSettingViewProviding` protocol that provides no custom views for settings.
/// This type can be used as a placeholder when no custom views are needed.
public struct DCDefaultViewProvider: DCSettingViewProviding {
    
    /// Returns a view representing the user interface for changing the specified setting.
    ///
    /// This default implementation of the `content` method always returns `nil`, indicating that no custom view is available for the specified setting.
    ///
    /// - Parameter setting: A `DCSettable` instance representing the setting to be changed.
    /// - Returns: An optional view representing the user interface for changing the specified setting. The default implementation always returns `nil`.
    @ViewBuilder public func content(for setting: any DCSettable) -> (some View)? {}
}
