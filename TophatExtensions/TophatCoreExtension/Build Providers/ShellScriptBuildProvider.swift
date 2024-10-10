//
//  ShellScriptBuildProvider.swift
//  TophatCoreExtension
//
//  Created by Lukas Romsicki on 2024-10-09.
//  Copyright © 2024 Shopify. All rights reserved.
//

import Foundation
import TophatKit

struct ShellScriptBuildProvider: BuildProvider {
	static let id = "shell"
	static let title: LocalizedStringResource = "Shell Script"

	@Parameter(
		key: "script",
		title: "Script",
		description: "The name of the script to run.",
		prompt: "File Name"
	)
	var script: String

	func retrieve() async throws -> some BuildProviderResult {
		let temporaryDirectoryURL: URL = .temporaryDirectory.appending(path: UUID().uuidString)
		let stagingDirectoryURL = temporaryDirectoryURL.appending(path: "Staging")
		let outputDirectoryURL = temporaryDirectoryURL.appending(path: "Output")

		try FileManager.default.createDirectory(at: stagingDirectoryURL, withIntermediateDirectories: true)
		try FileManager.default.createDirectory(at: outputDirectoryURL, withIntermediateDirectories: true)

		let applicationScriptsURL = try FileManager.default.url(
			for: .applicationScriptsDirectory,
			in: .userDomainMask,
			appropriateFor: nil,
			create: true
		)

		let task = try NSUserUnixTask(url: applicationScriptsURL.appending(component: script))
		try await task.execute(withArguments: [stagingDirectoryURL.path(), outputDirectoryURL.path()])

		let directoryContents = try FileManager.default.contentsOfDirectory(
			at: outputDirectoryURL,
			includingPropertiesForKeys: nil
		)

		guard let fileURL = directoryContents.first else {
			throw ShellScriptBuildProviderError.fileNotFound
		}

		return .result(localURL: fileURL)
	}

	func cleanUp(localURL: URL) async throws {
		try FileManager.default.removeItem(
			at: localURL.deletingLastPathComponent().deletingLastPathComponent()
		)
	}
}

enum ShellScriptBuildProviderError: Error {
	case fileNotFound
}
