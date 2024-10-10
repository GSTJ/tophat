//
//  ExtensionService.swift
//  TophatUtilities
//
//  Created by Lukas Romsicki on 2024-09-08.
//  Copyright © 2024 Shopify. All rights reserved.
//

import Foundation

struct ExtensionService {
	private let appExtension: any TophatExtension

	init(appExtension: some TophatExtension) {
		self.appExtension = appExtension
	}

	func handleRetreiveBuild(message: RetrieveBuild) async throws -> RetrieveBuild.Reply {
		guard let buildProvider = buildProvider(id: message.providerID) else {
			throw RetreiveBuildError.noBuildProviders
		}

		try buildProvider.setParameters(to: message.parameters)

		guard let resultContainer = try await buildProvider.retrieve() as? BuildProviderResultContainer else {
			throw RetreiveBuildError.invalidResult
		}

		return resultContainer
	}

	func handleExtensionDescriptor(message: FetchExtensionSpecification) -> FetchExtensionSpecification.Reply {
		ExtensionSpecification(provider: appExtension)
	}

	func handleCleanUp(message: CleanUpBuild) async throws {
		guard let buildProvider = buildProvider(id: message.providerID) else {
			throw RetreiveBuildError.noBuildProviders
		}

		try await buildProvider.cleanUp(localURL: message.url)
	}

	private func buildProvider(id: String) -> (any BuildProvider)? {
		guard
			let buildProviding = appExtension as? any BuildProviding,
			let buildProviders = type(of: buildProviding).buildProviders.arrayValue
		else {
			return nil
		}

		return buildProviders.first { type(of: $0).id == id }
	}
}

enum RetreiveBuildError: Error {
	case noBuildProviders
	case invalidResult
}
