import SwiftUI

/// Landing page: choose whether to study human or animal anatomy.
struct StudyPickerView: View {
    let onSelect: (StudyCategory) -> Void
    @State private var showSettings = false
    @Environment(\.colorScheme) private var colorScheme

    private var theme: AppTheme { AppTheme(colorScheme: colorScheme) }

    var body: some View {
        ZStack {
            Color(UIColor(hex: theme.sceneBackgroundHex))
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                        .padding(.bottom, 12)

                    categoryCard(
                        index: "01",
                        title: "Human",
                        subtitle: "Adult anatomy from the BodyParts3D reference.",
                        tags: ["2,234 structures", "15 body systems", "9 organ views"],
                        imageName: "StudyHuman"
                    ) { onSelect(.human) }

                    categoryCard(
                        index: "02",
                        title: "Animal",
                        subtitle: "Whales of the world, inside and out.",
                        tags: ["6 whale species", "11 body parts", "Field notes"],
                        imageName: "StudyAnimal"
                    ) { onSelect(.animal) }

                    comingSoonCard

                    Text("Simplified models and colors support exploration. For education, not diagnosis.")
                        .font(.caption)
                        .foregroundStyle(theme.secondaryText)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
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
