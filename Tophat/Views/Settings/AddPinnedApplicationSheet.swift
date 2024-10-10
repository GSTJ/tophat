//
//  AddPinnedApplicationSheet.swift
//  Tophat
//
//  Created by Lukas Romsicki on 2022-11-30.
//  Copyright © 2022 Shopify. All rights reserved.
//

import SwiftUI
import TophatFoundation
@_spi(TophatKitInternal) import TophatKit

struct AddPinnedApplicationSheet: View {
	@Environment(\.presentationMode) private var presentationMode
	@Environment(ExtensionHost.self) private var extensionHost
	@EnvironmentObject private var pinnedApplicationState: PinnedApplicationState

	private var editingApplicationID: String?

	@State private var name: String = ""
	@State private var platform: Platform = .iOS

	@State private var destinationPreset: DestinationPreset = .any

	@State private var buildProviderID: String?
	@State private var simulatorBuildProviderParameters: [String: String] = [:]
	@State private var deviceBuildProviderParameters: [String: String] = [:]

	private var addOrUpdateText: String {
		editingApplicationID != nil ? "Update Quick Launch App" : "Add App to Quick Launch"
	}
	private var addOrUpdateButtonText: String {
		editingApplicationID != nil ? "Update App" : "Add App"
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 0) {
			Form {
				Section(addOrUpdateText) {
					TextField("Name", text: $name, prompt: Text("Name"))

					Picker("Platform", selection: $platform) {
						ForEach([Platform.iOS, Platform.android], id: \.self) { platform in
							Text(platform.description)
								.tag(platform)
						}
					}

					Picker("Source", selection: $buildProviderID) {
						ForEach(buildProviders) { buildProvider in
							Text(buildProvider.title)
								.tag(buildProvider.id)
						}
					}
				}

				Section {
					Picker(selection: $destinationPreset) {
						ForEach(DestinationPreset.allCases, id: \.self) { type in
							Text(type.description)
						}
					} label: {
						Text("Destination")
						Text(destinationPreset.helpText)
					}
				}

				if let selectedBuildProvider {
					if destinationPreset == .all || destinationPreset == .simulatorOnly || destinationPreset == .any {
						Section(destinationPreset == .all ? "Simulator" : "Parameters") {
							ForEach(selectedBuildProvider.parameters, id: \.key) { parameter in
								TextField(
									text: simulatorBuildProviderParameter(key: parameter.key),
									prompt: Text(parameter.prompt ?? parameter.title)
								) {
									Text(parameter.title)

									if let description = parameter.description {
										Text(description)
									}
								}
							}
						}
					}

					if destinationPreset == .all || destinationPreset == .deviceOnly {
						Section(destinationPreset == .all ? "Device" : "Parameters") {
							ForEach(selectedBuildProvider.parameters, id: \.key) { parameter in
								TextField(
									text: deviceBuildProviderParameter(key: parameter.key),
									prompt: Text(parameter.prompt ?? parameter.title)
								) {
									Text(parameter.title)

									if let description = parameter.description {
										Text(description)
									}
								}
							}
						}
					}
				}
			}
			.formStyle(.grouped)

			Divider()

			HStack {
				Spacer()

				Button("Cancel", action: performCancelAction)
					.keyboardShortcut(.cancelAction)

				Button(addOrUpdateButtonText, action: performDefaultAction)
					.keyboardShortcut(.defaultAction)
					.disabled(primaryActionDisabled)
			}
			.padding(20)
		}
		.frame(width: 500)
		.fixedSize()
		.scrollDisabled(true)
		.onAppear {
			if editingApplicationID == nil {
				buildProviderID = buildProviders.first?.id
			}
		}
		.onChange(of: buildProviderID) { oldValue, newValue in
			simulatorBuildProviderParameters.removeAll()
			deviceBuildProviderParameters.removeAll()
		}
	}

	private var buildProviders: [BuildProviderSpecification] {
		extensionHost.specifications.flatMap(\.buildProviders)
	}

	private var selectedBuildProvider: BuildProviderSpecification? {
		buildProviders.first { $0.id == buildProviderID }
	}

	private func simulatorBuildProviderParameter(key: String) -> Binding<String> {
		.init(
			get: { simulatorBuildProviderParameters[key, default: ""] },
			set: { simulatorBuildProviderParameters[key] = $0 })
	}

	private func deviceBuildProviderParameter(key: String) -> Binding<String> {
		.init(
			get: { deviceBuildProviderParameters[key, default: ""] },
			set: { deviceBuildProviderParameters[key] = $0 })
	}

	private var primaryActionDisabled: Bool {
		name.isEmpty || installRecipes.isEmpty
	}

	private func performCancelAction() {
		presentationMode.wrappedValue.dismiss()
	}

	private func performDefaultAction() {
		if let editingApplicationID,
		   let existingIndex = pinnedApplicationState.pinnedApplications.firstIndex(where: { $0.id == editingApplicationID }) {
			let existingItem = pinnedApplicationState.pinnedApplications[existingIndex]

			var newPinnedApplication = PinnedApplication(
				id: editingApplicationID,
				name: name,
				platform: platform,
				recipes: installRecipes
			)
			newPinnedApplication.icon = existingItem.icon
			pinnedApplicationState.pinnedApplications[existingIndex] = newPinnedApplication

		} else {
			let newPinnedApplication = PinnedApplication(
				name: name,
				platform: platform,
				recipes: installRecipes
			)
			pinnedApplicationState.pinnedApplications.append(newPinnedApplication)
		}

		presentationMode.wrappedValue.dismiss()
	}

	private var installRecipes: [InstallRecipe] {
		guard let selectedBuildProvider else {
			return []
		}

		return switch destinationPreset {
			case .any:
				[
					.init(
						buildProviderID: selectedBuildProvider.id,
						buildProviderParameters: simulatorBuildProviderParameters,
						launchArguments: [],
						platformHint: platform
					)
				]
			case .all:
				[
					.init(
						buildProviderID: selectedBuildProvider.id,
						buildProviderParameters: simulatorBuildProviderParameters,
						launchArguments: [],
						platformHint: platform,
						destinationHint: .virtual
					),
					.init(
						buildProviderID: selectedBuildProvider.id,
						buildProviderParameters: deviceBuildProviderParameters,
						launchArguments: [],
						platformHint: platform,
						destinationHint: .physical
					)
				]
			case .simulatorOnly:
				[
					.init(
						buildProviderID: selectedBuildProvider.id,
						buildProviderParameters: simulatorBuildProviderParameters,
						launchArguments: [],
						platformHint: platform,
						destinationHint: .virtual
					)
				]
			case .deviceOnly:
				[
					.init(
						buildProviderID: selectedBuildProvider.id,
						buildProviderParameters: deviceBuildProviderParameters,
						launchArguments: [],
						platformHint: platform,
						destinationHint: .physical
					)
				]
		}
	}
}

private enum DestinationPreset {
	case any
	case all
	case simulatorOnly
	case deviceOnly
}

extension DestinationPreset {
	var helpText: LocalizedStringResource {
		switch self {
			case .any:
				return "This build can run on both simulators and devices."
			case .all:
				return "Simulators and devices require separate builds."
			case .simulatorOnly:
				return "This build can only run on simulators."
			case .deviceOnly:
				return "This build can only run on devices."
		}
	}
}

extension DestinationPreset: CaseIterable {}
extension DestinationPreset: CustomStringConvertible {
	var description: String {
		switch self {
			case .any:
				return "Any"
			case .all:
				return "All"
			case .simulatorOnly:
				return "Simulator"
			case .deviceOnly:
				return "Device"
		}
	}
}

extension AddPinnedApplicationSheet {
	init(applicationToEdit: PinnedApplication) {
		self.editingApplicationID = applicationToEdit.id
		_name = State(initialValue: applicationToEdit.name)
		_platform = State(initialValue: applicationToEdit.platform)

		let recipes = applicationToEdit.recipes

		_buildProviderID = State(initialValue: recipes.first?.buildProviderID)

		if let virtualRecipe = recipes.first(where: { $0.destinationHint == .virtual }),
		   let physicalRecipe = recipes.first(where: { $0.destinationHint == .physical }) {
			_destinationPreset = State(initialValue: .all)
			_simulatorBuildProviderParameters = State(initialValue: virtualRecipe.buildProviderParameters)
			_deviceBuildProviderParameters = State(initialValue: physicalRecipe.buildProviderParameters)
		} else if let physicalRecipe = recipes.first(where: { $0.destinationHint == .physical }) {
			_destinationPreset = State(initialValue: .deviceOnly)
			_deviceBuildProviderParameters = State(initialValue: physicalRecipe.buildProviderParameters)
		} else if let virtualRecipe = recipes.first(where: { $0.destinationHint == .virtual }) {
			_destinationPreset = State(initialValue: .simulatorOnly)
			_simulatorBuildProviderParameters = State(initialValue: virtualRecipe.buildProviderParameters)
		} else if let firstRecipe = recipes.first {
			_destinationPreset = State(initialValue: .any)
			_simulatorBuildProviderParameters = State(initialValue: firstRecipe.buildProviderParameters)
		}
	}
}

private extension State where Value == String {
	init(from artifact: Artifact) {
		self.init(initialValue: artifact.url.absoluteString)
	}
}
