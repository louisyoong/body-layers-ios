import SwiftUI

struct HumanAtlasView: View {
    @ObservedObject var viewModel: AnatomyViewModel
    let onBack: () -> Void
    @State private var showLayers = false
    @State private var showSettings = false
    @Environment(\.colorScheme) private var colorScheme

    private var theme: AppTheme { AppTheme(colorScheme: colorScheme) }

    var body: some View {
        ZStack {
            AnatomySceneView(viewModel: viewModel)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                CategoryStripView(viewModel: viewModel)
                    .padding(.top, 8)

                Spacer()

                VStack(spacing: 12) {
                    if let detail = viewModel.selectedDetail {
                        DetailCardView(viewModel: viewModel, detail: detail)
                    }
                    ViewControlsBar(viewModel: viewModel)
                }
                .padding(.bottom, 8)
            }

            if !viewModel.isLoaded {
                LoadingOverlayView(viewModel: viewModel)
            }
        }
        .sheet(isPresented: $showLayers) {
            LayersSheetView(viewModel: viewModel)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .task {
            await viewModel.load()
        }
    }

    private var topBar: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
            }
            .accessibilityLabel("Back to study categories")
            VStack(alignment: .leading, spacing: 2) {
                Text("HUMAN ATLAS")
                    .font(.headline.weight(.bold))
                Text("3D ANATOMY EXPLORER")
                    .font(.caption2)
                    .foregroundStyle(theme.secondaryText)
            }
            Spacer()
            Button {
                showLayers = true
            } label: {
                Image(systemName: "square.3.layers.3d")
                    .font(.title3)
            }
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.title3)
            }
        }
        .foregroundStyle(theme.primaryText)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

#Preview {
    HumanAtlasView(viewModel: AnatomyViewModel(), onBack: {})
}
