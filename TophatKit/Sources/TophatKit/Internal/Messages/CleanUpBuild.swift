//
//  CleanUpBuild.swift
//  TophatKitBeta
//
//  Created by Lukas Romsicki on 2024-10-05.
//

import Foundation

@_spi(TophatKitInternal)
public struct CleanUpBuild: ExtensionXPCMessage {
	public typealias Reply = Never

	let providerID: String
	let url: URL

	public init(providerID: String, url: URL) {
		self.providerID = providerID
		self.url = url
	}
}
