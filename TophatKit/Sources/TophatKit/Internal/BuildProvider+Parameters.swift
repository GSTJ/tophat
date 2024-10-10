//
//  BuildProvider+Parameters.swift
//  TophatUtilities
//
//  Created by Lukas Romsicki on 2024-09-06.
//  Copyright © 2024 Shopify. All rights reserved.
//

import Foundation

extension BuildProvider {
	func setParameters(to parameterDictionary: [String: String]) throws {
		for parameter in parameters {
			let key = parameter.key

			guard let value = parameterDictionary[key] else {
				throw BuildProviderError.missingParameter
			}

			try parameter.store(stringRepresentation: value)
		}
	}

	var parameters: [any AnyBuildProviderParameter] {
		Mirror(reflecting: self)
			.children
			.compactMap { child in
				child.value as? any AnyBuildProviderParameter
			}
	}
}

private extension AnyBuildProviderParameter {
	func store(stringRepresentation: String) throws {
		guard let parameter = self as? BuildProviderParameter<Value> else {
			throw BuildProviderError.invalidType
		}

		parameter.storage = Value(stringRepresentation: stringRepresentation)
	}
}

enum BuildProviderError: Error {
	case missingParameter
	case invalidType
}
