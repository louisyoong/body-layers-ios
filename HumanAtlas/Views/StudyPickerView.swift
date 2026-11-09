import SwiftUI

/// Landing page: choose whether to study human or animal anatomy.
struct StudyPickerView: View {
    let onSelect: (StudyCategory) -> Void
    @State private var showSettings = false
    @State private var fold: FoldInfo?
    /// The scroll view's frame on screen: the width the cards actually have, which on
    /// iPhone Duo excludes the vertical status/toolbar column.
    @State private var contentFrame: CGRect = .zero
    @Environment(\.colorScheme) private var colorScheme

    private var theme: AppTheme { AppTheme(colorScheme: colorScheme) }

    var body: some View {
        ZStack {
            Color(UIColor(hex: theme.sceneBackgroundHex))
                .ignoresSafeArea()
                // Inactive too: the crease position decides the column split even while
                // the device is flat, so the layout doesn't jump when someone folds it.
                .onFoldChange(includeInactive: true) { fold = $0 }

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                        .padding(.bottom, 12)

                    cards

                    Text("Simplified models and colors support exploration. For education, not diagnosis.")
                        .font(.caption)
                        .foregroundStyle(theme.secondaryText)
                        .padding(.top, 8)
                }
                .padding(.horizontal, Self.horizontalPadding)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { contentFrame = $0 }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    private var humanCard: some View {
        categoryCard(
            index: "01",
            title: "Human",
            subtitle: "Adult anatomy from the BodyParts3D reference.",
            tags: ["2,234 structures", "15 body systems", "9 organ views"],
            imageName: "StudyHuman"
        ) { onSelect(.human) }
    }

    private var animalCard: some View {
        categoryCard(
            index: "02",
            title: "Animal",
            subtitle: "Whales of the world, inside and out.",
            tags: ["6 whale species", "11 body parts", "Field notes"],
            imageName: "StudyAnimal"
        ) { onSelect(.animal) }
    }

    /// One column on phones; two side by side on wide screens such as iPhone Duo's
    /// inner display, with the gap between them straddling the fold.
    private var cards: some View {
        StudyCardsLayout(foldSplit: foldSplit) {
            humanCard
            animalCard
            comingSoonCard
        }
    }

    private static let horizontalPadding: CGFloat = 20

    /// Where the fold wants the column gap, relative to the cards' leading edge. Only a
    /// hint: `StudyCardsLayout` ignores it unless it fits the width it's actually given,
    /// so a stale measurement after the window resizes can't push cards off-screen.
    private var foldSplit: StudyCardsLayout.Split? {
        guard let fold, fold.isVertical, contentFrame.width > 0 else { return nil }
        let contentMinX = contentFrame.minX + Self.horizontalPadding
        return StudyCardsLayout.Split(
            leading: fold.crease.minX - 16 - contentMinX,
            gap: fold.crease.width + 32
        )
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("BODY LAYERS")
                    .font(.headline.weight(.bold))
                Text("What would you like\nto study today?")
                    .font(.largeTitle.weight(.bold))
                    .fixedSize(horizontal: false, vertical: true)
                Text("Human & animal anatomy, explained.")
                    .font(.subheadline)
                    .foregroundStyle(theme.secondaryText)
            }
            Spacer()
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.title3)
            }
            .accessibilityLabel("Settings")
        }
        .foregroundStyle(theme.primaryText)
    }

    /// Placeholder for the next study category: same footprint as the live cards,
    /// but dashed, dimmed and not tappable.
    private var comingSoonCard: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text("03")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                    Text("COMING SOON")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.cyan)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.cyan.opacity(0.15)))
                }
                Text("More to explore")
                    .font(.title.weight(.bold))
                Text("New study categories are on the way.")
                    .font(.subheadline)
                    .foregroundStyle(theme.secondaryText)
            }
            Spacer(minLength: 0)
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(theme.chipFill)
                .frame(width: 104, height: 104)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(.secondary)
                )
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(theme.primaryText)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(theme.secondaryText.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [6, 5]))
        )
        .opacity(0.75)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Coming soon: more study categories")
    }

    private func tagRow(_ tags: [String]) -> some View {
        HStack(spacing: 6) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                    .fixedSize()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(theme.chipFill))
            }
        }
    }

    private func categoryCard(
        index: String,
        title: String,
        subtitle: String,
        tags: [String],
        imageName: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(index)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                        Text(title)
                            .font(.title.weight(.bold))
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(theme.secondaryText)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: 0)
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 104, height: 128)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(theme.hairline))
                        .accessibilityHidden(true)
                }
                ViewThatFits(in: .horizontal) {
                    tagRow(tags)
                    tagRow(Array(tags.prefix(2)))
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(theme.hairline))
            .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
        .foregroundStyle(theme.primaryText)
        .accessibilityHint("Opens the \(title.lowercased()) atlas")
    }
}

#Preview {
    StudyPickerView { _ in }
}

/// Lays out the three study cards in one column, or in two (Human | Animal, then
/// Coming soon) when there's room. The choice is made from the width offered during
/// layout itself, so it is always right for the current window, including the moment
/// iPhone Duo switches between its inner and outer displays.
private struct StudyCardsLayout: Layout {
    struct Split: Equatable {
        var leading: CGFloat
        var gap: CGFloat
    }

    var foldSplit: Split?
    var spacing: CGFloat = 16
    /// Each card needs ~340pt for its title, subtitle and artwork to sit side by side
    /// without truncating, so anything narrower than two of those stays one column
    /// (iPhone Duo's inner display held upright is 669pt).
    var minColumnWidth: CGFloat = 340

    private func columns(for width: CGFloat) -> (leading: CGFloat, trailing: CGFloat, gap: CGFloat)? {
        if let split = foldSplit {
            let trailing = width - split.leading - split.gap
            if split.leading >= minColumnWidth, trailing >= minColumnWidth {
                return (split.leading, trailing, split.gap)
            }
        }
        let equal = (width - spacing) / 2
        guard equal >= minColumnWidth else { return nil }
        return (equal, equal, spacing)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? subviews.map { $0.sizeThatFits(.unspecified).width }.max() ?? 0
        return arrange(width: width, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for (subview, frame) in zip(subviews, arrange(width: bounds.width, subviews: subviews).frames) {
            subview.place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                // Width only: the card picks its own height, as it would in a VStack.
                proposal: ProposedViewSize(width: frame.width, height: nil)
            )
        }
    }

    private func measuredHeight(_ subview: LayoutSubview, width: CGFloat) -> CGFloat {
        subview.sizeThatFits(ProposedViewSize(width: width, height: nil)).height
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        var frames: [CGRect] = []
        guard let columns = columns(for: width), subviews.count == 3 else {
            var y: CGFloat = 0
            for subview in subviews {
                let height = measuredHeight(subview, width: width)
                frames.append(CGRect(x: 0, y: y, width: width, height: height))
                y += height + spacing
            }
            return (CGSize(width: width, height: max(0, y - spacing)), frames)
        }

        func height(_ index: Int, _ columnWidth: CGFloat) -> CGFloat {
            measuredHeight(subviews[index], width: columnWidth)
        }
        // Each card keeps its own height (proposing a taller one than it measured can
        // squeeze its text); the second row starts below the taller of the two.
        let leadingHeight = height(0, columns.leading)
        let trailingHeight = height(1, columns.trailing)
        let rowHeight = max(leadingHeight, trailingHeight)
        let trailingX = columns.leading + columns.gap
        frames.append(CGRect(x: 0, y: 0, width: columns.leading, height: leadingHeight))
        frames.append(CGRect(x: trailingX, y: 0, width: columns.trailing, height: trailingHeight))
        let secondRowY = rowHeight + spacing
        let lastHeight = height(2, columns.leading)
        frames.append(CGRect(x: 0, y: secondRowY, width: columns.leading, height: lastHeight))
        return (CGSize(width: width, height: secondRowY + lastHeight), frames)
    }
}
