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
                        Button {
                            viewModel.revealHeartInterior()
                        } label: {
                            Label("Reveal inside the heart", systemImage: "heart.text.square")
                        }
                    }
                } header: {
                    HStack {
                        Text(viewModel.layerTitle)
                        Spacer()
                        Button {
                            viewModel.toggleAll()
                        } label: {
                            Text(viewModel.toggleAllLabel)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.secondary.opacity(0.15)))
                        }
                    }
                }

                Section {
                    ForEach(viewModel.systems, id: \.id) { system in
                        let isOn = viewModel.visibleSystemIds.contains(system.id)
                        Button {
                            viewModel.toggleSystem(system.id)
                        } label: {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color(UIColor(hex: system.colorHex)))
                                    .frame(width: 14, height: 14)
                                    .opacity(isOn ? 1 : 0.3)
                                Text(system.name)
                                    .foregroundStyle(isOn ? .primary : .secondary)
                                Spacer()
                                Image(systemName: isOn ? "eye.fill" : "eye.slash")
                                    .foregroundStyle(isOn ? Color.cyan : Color.secondary.opacity(0.6))
                                    .font(.body)
                                    .frame(width: 22)
                            }
                            .padding(.vertical, 2)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(isOn ? Color.cyan.opacity(0.08) : Color.clear)
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
