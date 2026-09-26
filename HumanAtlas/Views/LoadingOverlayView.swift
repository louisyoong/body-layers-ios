import SwiftUI

struct LoadingOverlayView: View {
    @ObservedObject var viewModel: AnatomyViewModel

    var body: some View {
        ZStack {
            Color.black.opacity(0.92).ignoresSafeArea()
            VStack(spacing: 16) {
                if let error = viewModel.loadError {
                    Text("Unable to load the 3D atlas")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Button("Try again") {
                        Task { await viewModel.load() }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    ProgressView(value: viewModel.loadingProgress)
                        .frame(width: 200)
                        .tint(.cyan)
                    Text("Preparing your atlas")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("\(Int(viewModel.loadingProgress * 100))% · Loading anatomical structures")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
