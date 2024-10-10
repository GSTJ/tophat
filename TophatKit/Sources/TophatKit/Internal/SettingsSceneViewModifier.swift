//
//  SettingsSceneViewModifier.swift
//  TophatUtilities
//
//  Created by Lukas Romsicki on 2024-09-24.
//  Copyright © 2024 Shopify. All rights reserved.
//

import SwiftUI

struct SettingsSceneViewModifier: ViewModifier {
	func body(content: Content) -> some View {
		content.fixedSize(horizontal: false, vertical: true)
	}
}
