//
//  TophatExtension.swift
//  TophatKit
//
//  Created by Lukas Romsicki on 2024-09-06.
//  Copyright © 2024 Shopify. All rights reserved.
//

import Foundation
import ExtensionFoundation
import ExtensionKit
import SwiftUI

/// The primary entry point for a Tophat extension.
///
/// Use this type to register the components of an extension to provide Tophat with
/// the functionality you implement.
public protocol TophatExtension: AppExtension {
	/// The human-readable name for the extension.
	static var title: LocalizedStringResource { get }
}

/// A type that supports registering build providers in a Tophat extension.
public protocol BuildProviding {
	associatedtype ExtensionBuildProviders: BuildProviders

	/// A collection of `BuildProvider` objects that Tophat can use to retrieve
	/// builds from various sources.
	@BuildProvidersBuilder static var buildProviders: ExtensionBuildProviders { get }
}

/// A type that supports providing a settings view in a Tophat extension.
public protocol SettingsProviding {
	associatedtype SettingsBody: View

	/// The view to display in the Tophat Settings window to allow
	/// the extension to be configured.
	@ViewBuilder static var settings: SettingsBody { get }
}

public extension TophatExtension {
	var configuration: some AppExtensionConfiguration {
		ExtensionConfiguration(appExtension: self)
	}
}

public extension TophatExtension where Self: SettingsProviding {
	var configuration: AppExtensionSceneConfiguration {
		AppExtensionSceneConfiguration(
			PrimitiveAppExtensionScene(id: "TophatExtensionSettings") {
				Self.settings
					.modifier(SettingsSceneViewModifier())
			},
			configuration: ExtensionConfiguration(appExtension: self)
		)
	}
}
