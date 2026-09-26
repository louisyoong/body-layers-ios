import SwiftUI

struct ViewControlsBar: View {
    @ObservedObject var viewModel: AnatomyViewModel

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                ForEach(CameraViewDirection.allCases, id: \.self) { direction in
                    Button {
                        viewModel.setViewDirection(direction)
                    } label: {
                        Text(direction.buttonTitle)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(viewModel.currentView == direction
                                    ? Color.white.opacity(0.9)
                                    : Color.white.opacity(0.1))
                            )
                            .foregroundStyle(viewModel.currentView == direction ? .black : .white)
                    }
                }
                Spacer()
                Button { viewModel.zoomIn() } label: {
                    Image(systemName: "plus.magnifyingglass")
                }
                Button { viewModel.zoomOut() } label: {
                    Image(systemName: "minus.magnifyingglass")
                }
                Button { viewModel.resetView() } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
            }
            .foregroundStyle(.white)
            .buttonStyle(.plain)

            HStack(spacing: 10) {
                Text("Assembled")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Slider(
                    value: Binding(
                        get: { viewModel.explosion },
                        set: { viewModel.setExplosion($0) }
                    ),
                    in: 0...1,
                    onEditingChanged: { editing in
                        viewModel.explosionEditingChanged(editing)
                    }
                )
                Text("Separated")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08)))
        .padding(.horizontal, 16)
    }
}
