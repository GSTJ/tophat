//
//  BuildProviderValue.swift
//  TophatUtilities
//
//  Created by Lukas Romsicki on 2024-09-06.
//  Copyright © 2024 Shopify. All rights reserved.
//

import Foundation

public protocol BuildProviderValue {
	init?(stringRepresentation: String)
}

extension String: BuildProviderValue {
	public init?(stringRepresentation: String) {
		self = stringRepresentation
	}
}

// MARK: - RawRepresentable

extension RawRepresentable where Self: BuildProviderValue, RawValue: BuildProviderValue {
	public init?(stringRepresentation: String) {
		if let value = RawValue(stringRepresentation: stringRepresentation) {
			self.init(rawValue: value)
		} else {
			return nil
		}
	}
}

// MARK: - Optional

extension Optional: BuildProviderValue where Wrapped: BuildProviderValue {
	public init?(stringRepresentation: String) {
		if let value = Wrapped(stringRepresentation: stringRepresentation) {
			self.init(value)
		} else {
			return nil
		}
	}
}

// MARK: - URL

extension URL: BuildProviderValue {
	public init?(stringRepresentation: String) {
		self.init(string: stringRepresentation)
	}
}

// MARK: - LosslessStringConvertible

extension LosslessStringConvertible where Self: BuildProviderValue {
	public init?(stringRepresentation: String) {
		self.init(stringRepresentation)
	}
}

extension Int: BuildProviderValue {}
extension Double: BuildProviderValue {}
extension Float: BuildProviderValue {}
extension Bool: BuildProviderValue {}
