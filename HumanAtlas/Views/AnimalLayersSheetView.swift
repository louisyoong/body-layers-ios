import SwiftUI

struct AnimalLayersSheetView: View {
    @ObservedObject var viewModel: AnimalAtlasViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(isOn: Binding(
                        get: { viewModel.seeThrough },
                        set: { if $0 != viewModel.seeThrough { viewModel.toggleSeeThrough() } }
                    )) {
                        Label("See-through body", systemImage: "cube.transparent")
                    }
                    .tint(.cyan)
                } footer: {
                    Text("Tap a name to inspect it, or the eye to show or hide it.")
                }

                Section {
                    ForEach(viewModel.systems, id: \.id) { part in
                        let isOn = viewModel.visibleSystemIds.contains(part.id)
                        HStack(spacing: 12) {
                            Button {
                                viewModel.select(partId: part.id)
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(Color(UIColor(hex: part.colorHex)))
                                        .frame(width: 14, height: 14)
                                        .opacity(isOn ? 1 : 0.3)
                                    Text(part.name)
                                        .foregroundStyle(isOn ? .primary : .secondary)
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            Button {
                                viewModel.toggleSystem(part.id)
                            } label: {
                                Image(systemName: isOn ? "eye.fill" : "eye.slash")
                                    .foregroundStyle(isOn ? Color.cyan : Color.secondary.opacity(0.6))
                                    .frame(width: 32, height: 28)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(isOn ? "Hide \(part.name)" : "Show \(part.name)")
                        }
                        .padding(.vertical, 2)
                        .listRowBackground(isOn ? Color.cyan.opacity(0.08) : Color.clear)
                    }
                } header: {
                    HStack {
                        Text("Whale anatomy")
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
                    VStack(alignment: .leading, spacing: 4) {
                        Text("REFERENCE MODEL")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(viewModel.currentSpecies.name) · simplified model")
                            .font(.subheadline.weight(.semibold))
                        Text("Organ shapes, positions and proportions are schematic, not species-specific anatomical scans.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(viewModel.currentSpecies.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
