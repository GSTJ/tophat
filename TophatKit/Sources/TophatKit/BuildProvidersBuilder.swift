//
//  BuildProvidersBuilder.swift
//  TophatUtilities
//
//  Created by Lukas Romsicki on 2024-09-07.
//  Copyright © 2024 Shopify. All rights reserved.
//

import Foundation

public protocol BuildProviders {}

extension BuildProviders {
	var arrayValue: [any BuildProvider]? {
		self as? [any BuildProvider]
	}
}

extension Array: BuildProviders where Element == any BuildProvider {}

@resultBuilder
public struct BuildProvidersBuilder {
	public static func buildBlock(_ components: (any BuildProvider)...) -> some BuildProviders {
		components
	}
}
