//
//  TophatBaseExtension.swift
//  TophatBaseExtension
//
//  Created by Lukas Romsicki on 2024-10-04.
//  Copyright © 2024 Shopify. All rights reserved.
//

import Foundation
import TophatKit

@main
struct TophatCoreExtension: TophatExtension, BuildProviding {
	static let title: LocalizedStringResource = "Core"

	static var buildProviders: some BuildProviders {
		HTTPBuildProvider()
		ShellScriptBuildProvider()
	}
}
