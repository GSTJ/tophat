//
//  ExtensionHost.swift
//  Tophat
//
//  Created by Lukas Romsicki on 2024-09-06.
//  Copyright © 2024 Shopify. All rights reserved.
//

import Foundation
import ExtensionFoundation
import ExtensionKit
import Observation
import TophatFoundation
@_spi(TophatKitInternal) import TophatKit

@MainActor @Observable final class ExtensionHost {
	private(set) var identities: [AppExtensionIdentity] = []
	private(set) var specifications: [ExtensionSpecification] = []

	var availabilityUpdates: AsyncStream<AppExtensionIdentity.Availability> {
		AppExtensionIdentity.availabilityUpdates
	}

	func discover() {
		Task {
			do {
				let sequence = try AppExtensionIdentity.matching(
					appExtensionPointIDs: "com.shopify.Tophat.extension"
				)

				for await identities in sequence {
					self.identities = identities

					self.specifications = try await withThrowingTaskGroup(of: ExtensionSpecification.self, returning: [ExtensionSpecification].self) { group in
						for identity in identities {
							group.addTask {
								let session = try await identity.makeXPCSession()
								session.activate()
								defer { session.invalidate() }

								return try await session.send(FetchExtensionSpecification())
							}
						}

						var specifications: [ExtensionSpecification] = []

						for try await specification in group {
							specifications.append(specification)
						}

						return specifications
					}
				}
			} catch {
				print("Failed to discover extensions: \(error)")
			}
		}

		Task {
			for await update in availabilityUpdates {
				print(update)
			}
		}
	}
}

struct BuildProviderCoordinator {
	private let extensionHost: ExtensionHost

	init(extensionHost: ExtensionHost) {
		self.extensionHost = extensionHost
	}

	func retrieve(metadata: some BuildProviderMetadata) async throws -> URL {
		let indexOfIdentity = await extensionHost.specifications.firstIndex { specification in
			specification.buildProviders.contains { $0.id == metadata.id }
		}

		guard let indexOfIdentity else {
			throw BuildProviderCoordinatorError.buildProviderNotFound
		}

		let extensionIdentity = await extensionHost.identities[indexOfIdentity]

		let session = try await extensionIdentity.makeXPCSession()
		session.activate()
		defer { session.invalidate() }

		let message = RetrieveBuild(
			providerID: metadata.id,
			parameters: metadata.parameters
		)

		let result = try await session.send(message)

		return result.localURL
	}

	func cleanUp(buildProviderIdentifier: String, localURL: URL) async throws {
		let indexOfIdentity = await extensionHost.specifications.firstIndex { specification in
			specification.buildProviders.contains { $0.id == buildProviderIdentifier }
		}

		guard let indexOfIdentity else {
			throw BuildProviderCoordinatorError.buildProviderNotFound
		}

		let extensionIdentity = await extensionHost.identities[indexOfIdentity]

		let session = try await extensionIdentity.makeXPCSession()
		session.activate()
		defer { session.invalidate() }

		let message = CleanUpBuild(providerID: buildProviderIdentifier, url: localURL)
		try await session.send(message)
	}
}

enum BuildProviderCoordinatorError: Error {
	case buildProviderNotFound
}

extension AppExtensionIdentity {
	func makeXPCSession() async throws -> ExtensionXPCSession {
		let configuration = AppExtensionProcess.Configuration(appExtensionIdentity: self)
		let process = try await AppExtensionProcess(configuration: configuration)

		// Despite AppExtensionProcess' documentation, it does not wait long
		// enough for the process to start, so add some extra buffer just in case.
		// Attempting to create an XPC connection too early will cause the extension
		// process to hang during launch.
		try await Task.sleep(for: .seconds(0.2), tolerance: .zero)

		let connection = try process.makeXPCConnection()

		return ExtensionXPCSession(connection: connection)
	}
}
