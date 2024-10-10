//
//  AnyBuildProviderParameter.swift
//  TophatUtilities
//
//  Created by Lukas Romsicki on 2024-09-06.
//  Copyright © 2024 Shopify. All rights reserved.
//

import Foundation

protocol AnyBuildProviderParameter: AnyObject, Sendable {
	associatedtype Value: BuildProviderValue, Sendable

	var key: String { get }
	var title: LocalizedStringResource { get }
	var description: LocalizedStringResource? { get }
	var prompt: LocalizedStringResource? { get }
}
