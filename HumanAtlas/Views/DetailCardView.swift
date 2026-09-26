import SwiftUI

struct DetailCardView: View {
    @ObservedObject var viewModel: AnatomyViewModel
    let detail: SelectedDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(detail.systemName.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.cyan)
                Spacer()
                Button {
                    viewModel.clearSelection()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
            Text(detail.partName)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
            Text(detail.copy)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.8))
            Text("STRUCTURE ID \(detail.partId)")
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Button {
                    viewModel.toggleIsolate()
                } label: {
                    Text(viewModel.isolated ? "Show surrounding anatomy" : "Isolate structure ↗")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.cyan.opacity(0.85)))
                        .foregroundStyle(.black)
                }
                Button {
                    viewModel.clearSelection()
                } label: {
                    Text("Clear")
                        .font(.subheadline.weight(.semibold))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(Capsule().fill(Color.white.opacity(0.12)))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08)))
        .padding(.horizontal, 16)
    }
}
