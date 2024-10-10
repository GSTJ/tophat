//
//  FetchExtensionSpecification.swift
//  TophatUtilities
//
//  Created by Lukas Romsicki on 2024-09-09.
//  Copyright © 2024 Shopify. All rights reserved.
//

import Foundation

@_spi(TophatKitInternal)
public struct FetchExtensionSpecification: ExtensionXPCMessage {
	public typealias Reply = ExtensionSpecification

	public init() {}
}

@_spi(TophatKitInternal)
public struct ExtensionSpecification: Codable {
	public let title: LocalizedStringResource
	public let buildProviders: [BuildProviderSpecification]

	init(provider: some TophatExtension) {
		let providerType = type(of: provider)

		self.title = providerType.title

		self.buildProviders = if let buildProviding = provider as? any BuildProviding {
			type(of: buildProviding).buildProviders.arrayValue?.map { .init(provider: $0) } ?? []
		} else {
			[]
		}
	}
}

@_spi(TophatKitInternal)
public struct BuildProviderSpecification: Identifiable, Codable {
	public let id: String
	public let title: LocalizedStringResource
	public let parameters: [BuildProviderParameterSpecification]

	init(provider: some BuildProvider) {
		let providerType = type(of: provider)

		self.id = providerType.id
		self.title = providerType.title
		self.parameters = provider.parameters.map { .init(parameter: $0) }
	}
}

@_spi(TophatKitInternal)
public struct BuildProviderParameterSpecification: Codable {
	public let key: String
	public let title: LocalizedStringResource
	public let description: LocalizedStringResource?
	public let prompt: LocalizedStringResource?

	init(parameter: some AnyBuildProviderParameter) {
		self.key = parameter.key
		self.title = parameter.title
		self.description = parameter.description
		self.prompt = parameter.prompt
	}
}
