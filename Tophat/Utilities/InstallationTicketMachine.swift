//
//  InstallationTicketMachine.swift
//  Tophat
//
//  Created by Lukas Romsicki on 2024-10-02.
//  Copyright © 2024 Shopify. All rights reserved.
//

import Foundation
import TophatFoundation

protocol DeviceSelecting {
	var selectedDevices: [Device] { get }
}

protocol BuildDownloading {
	func download(metadata: some BuildProviderMetadata) async throws -> Application
}

extension DeviceSelectionManager: DeviceSelecting {}

extension InstallRecipe: @retroactive Hashable {}
extension InstallRecipe: BuildProviderMetadata {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(id)
		hasher.combine(parameters)
	}

	var id: String {
		buildProviderID
	}

	var parameters: [String: String] {
		buildProviderParameters
	}
}

/// A mechanism for producing installation tickets for selected devices based on the information
/// provided by installation recipes.
struct InstallationTicketMachine {
	typealias Ticket = InstallationTicket
	typealias TicketSequence = AsyncThrowingStream<Ticket, Error>

	private let deviceSelector: DeviceSelecting
	private let buildDownloader: BuildDownloading

	/// Creates a new instance of the processor.
	/// - Parameters:
	///   - deviceSelector: An instance that provides user-selected devices.
	///   - buildDownloader: An instance that provides downloading capability
	init(deviceSelector: DeviceSelecting, buildDownloader: BuildDownloading) {
		self.deviceSelector = deviceSelector
		self.buildDownloader = buildDownloader
	}

	/// Begins producing tickets for the provided recipes and returns them in an asynchronous
	/// sequence.
	/// - Parameter recipes: The recipes to be processed.
	/// - Returns: An asynchronous sequence of tickets.
	func process(recipes: [InstallRecipe]) -> TicketSequence {
		AsyncThrowingStream { continuation in
			Task {
				do {
					try await process(recipes: recipes, continuation: continuation)
					continuation.finish()
				} catch {
					continuation.finish(throwing: error)
				}
			}
		}
	}

	private func process(recipes: [InstallRecipe], continuation: TicketSequence.Continuation) async throws {
		let selectedDevices = deviceSelector.selectedDevices

		guard !selectedDevices.isEmpty else {
			throw InstallationTicketMachineError.noSelectedDevices
		}

		var processedTicketCount = 0

		var providedBuildTypes: [Platform: Set<DeviceType>] = recipes.reduce(into: [:]) { partialResult, recipe in
			if let platform = recipe.platformHint, let destination = recipe.destinationHint {
				partialResult[platform, default: []].insert(destination)
			}
		}

		try await withThrowingTaskGroup(of: Void.self) { group in
			for device in selectedDevices {
				group.addTask {
					// If this ends up in the else case, it means there was not enough
					// information in any recipe to be confident that the build will install
					// to the device.
					if let recipe = compatibleRecipeBasedOnHints(for: device, in: recipes) {
						let ticket = Ticket(
							device: device,
							source: .buildProvider(metadata: recipe),
							launchArguments: recipe.launchArguments
						)

						processedTicketCount += 1
						continuation.yield(ticket)
					} else {
						recipeLoop: for recipe in recipes where recipe.platformHint == nil {
							if let destinationHint = recipe.destinationHint, device.type != destinationHint {
								continue recipeLoop
							}

							let application = try await buildDownloader.download(metadata: recipe)

							providedBuildTypes[application.platform, default: []].formUnion(application.targets)

							guard
								device.runtime.platform == application.platform,
								application.targets.contains(device.type)
							else {
								continue recipeLoop
							}

							let ticket = Ticket(
								device: device,
								source: .application(application: application),
								launchArguments: recipe.launchArguments
							)

							processedTicketCount += 1
							continuation.yield(ticket)
						}
					}
				}
			}

			try await group.waitForAll()
		}

		guard processedTicketCount > 0 else {
			throw InstallationTicketMachineError.noCompatibleDevices(providedBuildTypes: providedBuildTypes)
		}
	}

	private func compatibleRecipeBasedOnHints(for device: Device, in recipes: [InstallRecipe]) -> InstallRecipe? {
		recipes.first { $0.platformHint == device.runtime.platform && $0.destinationHint == device.type }
		?? recipes.first { $0.platformHint == device.runtime.platform && $0.destinationHint == nil }
	}
}

enum InstallationTicketMachineError: Error {
	case noCompatibleDevices(providedBuildTypes: [Platform: Set<DeviceType>])
	case noSelectedDevices
}

/// Structure representing a request to install an application on a given device.
struct InstallationTicket {
	let device: Device
	let source: Source
	let launchArguments: [String]

	enum Source {
		case buildProvider(metadata: any BuildProviderMetadata)
		case application(application: Application)
		case local(fileURL: URL)
	}
}
