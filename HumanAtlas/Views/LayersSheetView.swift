import SwiftUI

struct LayersSheetView: View {
    @ObservedObject var viewModel: AnatomyViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Find a structure…", text: $viewModel.searchQuery)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    if !viewModel.searchResults.isEmpty {
                        ForEach(viewModel.searchResults, id: \.id) { part in
                            Button {
                                viewModel.selectFromSearch(part)
                                dismiss()
                            } label: {
                                Text(part.name)
                                    .foregroundStyle(.primary)
                            }
                        }
                    } else if !viewModel.searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text("No structures found. Try “heart” or “femur”.")
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                    }
                }

                Section {
                    if viewModel.showInternalViewButton {
                        Button("Reveal inside the heart") {
                            viewModel.revealHeartInterior()
                        }
                    }
                } header: {
                    HStack {
                        Text(viewModel.layerTitle)
                        Spacer()
                        Button(viewModel.toggleAllLabel) {
                            viewModel.toggleAll()
                        }
                        .font(.footnote)
                    }
                }

                Section {
                    ForEach(viewModel.systems, id: \.id) { system in
                        Button {
                            viewModel.toggleSystem(system.id)
                        } label: {
                            HStack {
                                Circle()
                                    .fill(Color(UIColor(hex: system.colorHex)))
                                    .frame(width: 10, height: 10)
                                Text(system.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: viewModel.visibleSystemIds.contains(system.id) ? "circle.fill" : "circle")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("REFERENCE MODEL")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(viewModel.referenceName)
                            .font(.subheadline.weight(.semibold))
                        Text("BodyParts3D · Open anatomical data")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(viewModel.categoryName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
