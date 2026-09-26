import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AnatomyViewModel()
    @State private var showLayers = false
    @State private var showAbout = false

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
        .sheet(isPresented: $showAbout) {
            AboutSheetView()
        }
        .task {
            await viewModel.load()
        }
    }

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("HUMAN ATLAS")
                    .font(.headline.weight(.bold))
                Text("ANATOMY EXPLORER")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                showAbout = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.title3)
            }
            Button {
                showLayers = true
            } label: {
                Image(systemName: "square.3.layers.3d")
                    .font(.title3)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

#Preview {
    ContentView()
}
