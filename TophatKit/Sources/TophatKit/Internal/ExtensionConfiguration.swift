//
//  ExtensionConfiguration.swift
//  TophatUtilities
//
//  Created by Lukas Romsicki on 2024-09-08.
//  Copyright © 2024 Shopify. All rights reserved.
//

import Foundation
import ExtensionFoundation

struct ExtensionConfiguration: AppExtensionConfiguration {
	private let service: ExtensionService

	init(appExtension: some TophatExtension) {
		self.service = ExtensionService(appExtension: appExtension)
	}

	func accept(connection: NSXPCConnection) -> Bool {
		let session = ExtensionXPCSession(connection: connection)
		session.activate()

		Task {
			for await message in session.receivedMessages {
				if let retrieveBuildMessage = try? message.decode(as: RetrieveBuild.self) {
					do {
						let result = try await service.handleRetreiveBuild(message: retrieveBuildMessage.value)
						retrieveBuildMessage.reply(.success(result))
					} catch {
						retrieveBuildMessage.reply(.failure(error))
					}
				}

				if let fetchExtensionDescriptorMessage = try? message.decode(as: FetchExtensionSpecification.self) {
					let reply = await service.handleExtensionDescriptor(message: fetchExtensionDescriptorMessage.value)
					fetchExtensionDescriptorMessage.reply(.success(reply))
				}

				if let cleanUpBuildMessage = try? message.decode(as: CleanUpBuild.self) {
					try? await service.handleCleanUp(message: cleanUpBuildMessage.value)
				}
			}
		}

		return true
	}
}
