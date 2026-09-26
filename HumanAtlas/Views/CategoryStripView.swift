import SwiftUI

struct CategoryStripView: View {
    @ObservedObject var viewModel: AnatomyViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(viewModel.categories.enumerated()), id: \.element.id) { index, category in
                    Button {
                        viewModel.setCategory(category.id)
                    } label: {
                        HStack(spacing: 6) {
                            Text(String(format: "%02d", index + 1))
                                .font(.caption2.monospaced())
                                .foregroundStyle(.secondary)
                            Text(category.name)
                                .font(.subheadline.weight(.semibold))
                            Text(category.id == "body" ? "ALL" : "\(category.parts.count)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(category.id == viewModel.currentCategoryId
                                ? Color.cyan.opacity(0.25)
                                : Color.black.opacity(0.35))
                        )
                        .overlay(
                            Capsule().stroke(
                                category.id == viewModel.currentCategoryId ? Color.cyan : .clear,
                                lineWidth: 1
                            )
                        )
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
