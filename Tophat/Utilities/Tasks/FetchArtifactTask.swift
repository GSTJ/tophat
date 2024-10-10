//
//  FetchArtifactTask.swift
//  Tophat
//
//  Created by Lukas Romsicki on 2023-01-11.
//  Copyright © 2023 Shopify. All rights reserved.
//

import Foundation
import TophatFoundation

import TophatFoundation

extension FetchArtifactTask: BuildDownloading {
	func download(metadata: some BuildProviderMetadata) async throws -> any Application {
		try await callAsFunction(from: .buildProvider(metadata: metadata)).application
	}
}

struct FetchArtifactTask {
	struct Result {
		let application: Application
	}

	let taskStatusReporter: TaskStatusReporter
	let pinnedApplicationState: PinnedApplicationState
	let buildProviderCoordinator: BuildProviderCoordinator
	let context: LaunchContext?

//	private let status: TaskStatus

	init(taskStatusReporter: TaskStatusReporter, pinnedApplicationState: PinnedApplicationState, buildProviderCoordinator: BuildProviderCoordinator, context: LaunchContext?) {
		self.taskStatusReporter = taskStatusReporter
		self.pinnedApplicationState = pinnedApplicationState
		self.buildProviderCoordinator = buildProviderCoordinator
		self.context = context

//		self.status = TaskStatus(displayName: "Downloading \(context?.appName ?? "App")", initialState: .preparing)
	}

	func callAsFunction(from source: InstallationTicket.Source) async throws -> Result {
		let status = TaskStatus(displayName: "Downloading \(context?.appName ?? "App")", initialState: .preparing)
		await taskStatusReporter.add(status: status)

		defer {
			Task {
				await status.markAsDone()
			}
		}

		await status.update(state: .running(message: "Downloading"))
		taskStatusReporter.notify(message: "Downloading \(context?.appName ?? "application")…")
		let downloadedArtifactUrl = switch source {
			case .buildProvider(let metadata):
				try await buildProviderCoordinator.retrieve(metadata: metadata)
			case .local(let fileURL):
				try await downloadArtifact(at: fileURL, status: status)
			case .application(let application):
				application.url
		}
		log.info("Artifact downloaded to \(downloadedArtifactUrl.path(percentEncoded: false))")

		let copiedURL = try await ArtifactDownloader().download(artifactUrl: downloadedArtifactUrl)

		log.info("Unpacking artifact at \(downloadedArtifactUrl.path(percentEncoded: false))")
		await status.update(state: .running(message: "Unpacking"))
		let application = try ArtifactUnpacker().unpack(artifactURL: copiedURL)
		log.info("Artifact unpacked to \(application.url.path(percentEncoded: false))")

		if case .buildProvider(let metadata) = source {
			try await buildProviderCoordinator.cleanUp(buildProviderIdentifier: metadata.id, localURL: downloadedArtifactUrl)
		}

		Task {
			let updateIcon = UpdateIconTask(
				taskStatusReporter: taskStatusReporter,
				pinnedApplicationState: pinnedApplicationState,
				context: context
			)

			try await updateIcon(application: application)
		}

		return Result(application: application)
	}

	private func downloadArtifact(at url: URL, status: TaskStatus) async throws -> URL {
		log.info("Downloading artifact from \(url.absoluteString)")
		let artifactDownloader = ArtifactDownloader()

		let task = Task {
			for await progress in artifactDownloader.progressUpdates {
				await status.update(state: .running(message: "Downloading", progress: progress))
			}
		}

		let downloadedArtifactURL = try await artifactDownloader.download(artifactUrl: url)
		task.cancel()

		return downloadedArtifactURL
	}
}
