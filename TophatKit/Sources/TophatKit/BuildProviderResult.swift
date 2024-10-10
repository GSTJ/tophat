//
//  BuildProviderResult.swift
//  TophatUtilities
//
//  Created by Lukas Romsicki on 2024-09-06.
//  Copyright © 2024 Shopify. All rights reserved.
//

import Foundation

public protocol BuildProviderResult {}

public struct BuildProviderResultContainer: Codable, BuildProviderResult {
	public var localURL: URL
}

public extension BuildProviderResult {
	static func result(localURL: URL) -> Self where Self == BuildProviderResultContainer {
		return .init(localURL: localURL)
	}
}
