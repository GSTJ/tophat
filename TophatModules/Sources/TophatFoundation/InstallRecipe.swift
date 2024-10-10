//
//  InstallRecipe.swift
//  TophatModules
//
//  Created by Lukas Romsicki on 2024-09-27.
//  Copyright © 2024 Shopify. All rights reserved.
//

/// Structure representing instructions for installing a build from a remote source.
public struct InstallRecipe: Equatable, Hashable, Codable {
	/// The identifier of the build provider that should retrieve the build.
	public let buildProviderID: String

	/// The parameters passed to the build provider used to retrieve the build.
	public let buildProviderParameters: [String: String]

	/// The arguments to pass to the application at launch.
	public let launchArguments: [String]

	/// The expected platform of the build, used to preheat the target device.
	public let platformHint: Platform?

	/// The expected destination of the build, used to preheat the target device.
	public let destinationHint: DeviceType?

	public init(
		buildProviderID: String,
		buildProviderParameters: [String: String],
		launchArguments: [String],
		platformHint: Platform? = nil,
		destinationHint: DeviceType? = nil
	) {
		self.buildProviderID = buildProviderID
		self.buildProviderParameters = buildProviderParameters
		self.launchArguments = launchArguments
		self.platformHint = platformHint
		self.destinationHint = destinationHint
	}
}
