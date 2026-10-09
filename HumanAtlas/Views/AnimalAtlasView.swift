import SwiftUI

struct AnimalAtlasView: View {
    @ObservedObject var viewModel: AnimalAtlasViewModel
    let onBack: () -> Void
    @State private var showLayers = false
    @State private var showSpeciesInfo = false
    @Environment(\.colorScheme) private var colorScheme

    private var theme: AppTheme { AppTheme(colorScheme: colorScheme) }

    var body: some View {
        ZStack {
            AnatomySceneView(viewModel: viewModel)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                speciesStrip
                    .padding(.top, 8)

                if viewModel.isBuilding {
                    ProgressView()
                        .tint(.cyan)
                        .padding(.top, 24)
                }

                Spacer()

                VStack(spacing: 12) {
                    if let detail = viewModel.selectedDetail {
                        DetailCardView(viewModel: viewModel, detail: detail)
                    }
                    ViewControlsBar(viewModel: viewModel)
                }
                .padding(.bottom, 8)
            }
        }
        .sheet(isPresented: $showLayers) {
            AnimalLayersSheetView(viewModel: viewModel)
        }
        .sheet(isPresented: $showSpeciesInfo) {
            SpeciesInfoView(species: viewModel.currentSpecies)
        }
        .onAppear {
            viewModel.loadIfNeeded()
        }
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
            }
            .accessibilityLabel("Back to study categories")
            VStack(alignment: .leading, spacing: 2) {
                Text("ANIMAL ATLAS")
                    .font(.headline.weight(.bold))
                Text("WHALES · \(viewModel.currentSpecies.latin.uppercased())")
                    .font(.caption2)
                    .foregroundStyle(theme.secondaryText)
                    .lineLimit(1)
            }
            Spacer()
            Button {
                viewModel.toggleSeeThrough()
            } label: {
                Image(systemName: viewModel.seeThrough ? "cube.transparent.fill" : "cube.transparent")
                    .font(.title3)
            }
            .accessibilityLabel(viewModel.seeThrough ? "Show solid body" : "See through body")
            Button {
                showSpeciesInfo = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.title3)
            }
            .accessibilityLabel("Species field notes")
            Button {
                showLayers = true
            } label: {
                Image(systemName: "square.3.layers.3d")
                    .font(.title3)
            }
            .accessibilityLabel("Body parts")
        }
        .foregroundStyle(theme.primaryText)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var speciesStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(viewModel.species.enumerated()), id: \.element.id) { index, species in
                        let isCurrent = index == viewModel.currentSpeciesIndex
                        Button {
                            viewModel.selectSpecies(index)
                            withAnimation { proxy.scrollTo(species.id, anchor: .center) }
                        } label: {
                            HStack(spacing: 6) {
                                Text(String(format: "%02d", index + 1))
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                                Text(species.name)
                                    .font(.subheadline.weight(.semibold))
                                Text(species.type.uppercased())
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(isCurrent ? Color.cyan.opacity(0.25) : theme.panelFill))
                            .overlay(Capsule().stroke(isCurrent ? Color.cyan : .clear, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(theme.primaryText)
                        .id(species.id)
                    }
                }
                .padding(.horizontal, 16)
            }
            .onAppear {
                proxy.scrollTo(viewModel.currentSpecies.id, anchor: .center)
            }
        }
    }
}
