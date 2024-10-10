//
//  ExtensionsTab.swift
//  Tophat
//
//  Created by Lukas Romsicki on 2024-09-24.
//  Copyright © 2024 Shopify. All rights reserved.
//

import SwiftUI
import ExtensionFoundation
import ExtensionKit

struct ExtensionsTab: View {
	@Environment(ExtensionHost.self) private var extensionHost

	@State private var selectedIdentity: AppExtensionIdentity?

	var body: some View {
		HStack(alignment: .top) {
			List(extensionHost.identities, id: \.self, selection: $selectedIdentity) { identity in
				HStack {
					SymbolChip(systemName: "puzzlepiece.extension.fill", color: .purple)
						.imageScale(.medium)

					Text(identity.localizedName)
				}
			}

			if let selectedIdentity {
				ExtensionSettingsHostingView(identity: selectedIdentity)
			}
		}
		.onAppear {
			selectedIdentity = extensionHost.identities.first
		}
		.frame(height: 400)
	}
}

struct ExtensionSettingsHostingView: NSViewControllerRepresentable {
	var identity: AppExtensionIdentity

	func makeNSViewController(context: Context) -> EXHostViewController {
		let hostViewController = EXHostViewController()
		hostViewController.configuration = EXHostViewController.Configuration(
			appExtension: identity,
			sceneID: "TophatExtensionSettings"
		)

		return hostViewController
	}

	func updateNSViewController(_ nsViewController: EXHostViewController, context: Context) {
		nsViewController.configuration = EXHostViewController.Configuration(
			appExtension: identity,
			sceneID: "TophatExtensionSettings"
		)
	}
}
