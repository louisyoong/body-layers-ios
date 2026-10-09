import SwiftUI
import UIKit

/// Species field notes, ported from the Whale Atlas web app's species guide.
struct SpeciesInfoView: View {
    let species: WhaleSpecies
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    illustration

                    VStack(alignment: .leading, spacing: 4) {
                        Text(species.classification)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.cyan)
                        Text(species.name)
                            .font(.largeTitle.weight(.bold))
                        Text(species.latin)
                            .font(.subheadline.italic())
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(species.headline)
                            .font(.title3.weight(.semibold))
                        Text(species.description)
                            .foregroundStyle(.secondary)
                    }

                    HStack(alignment: .top, spacing: 8) {
                        stat("MAX LENGTH", species.length)
                        stat("DIET", species.diet)
                        stat("RANGE", species.habitat)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("A CLOSER LOOK")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.cyan)
                        Text(species.fact)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.cyan.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("THE LIFE OF A \(species.name.uppercased())")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                        guideCard("01", "Where they live", species.whereTheyLive, places: species.places)
                        guideCard("02", "Movement & behaviour", species.movement)
                        guideCard("03", "History", species.history)
                        guideCard("04", "Conservation", species.protection)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Link(destination: species.noaaURL) {
                            Label("NOAA Fisheries species profile", systemImage: "arrow.up.right.square")
                        }
                        Text("Illustration & species references: NOAA Fisheries. 3D whale is a simplified educational model.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Field notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private var illustration: some View {
        if let image = UIImage(named: species.imageFile) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                // The source gray whale illustration faces the other way.
                .scaleEffect(x: species.slug == "gray-whale" ? -1 : 1, y: 1)
                .padding(8)
                .frame(maxWidth: .infinity)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .accessibilityLabel("NOAA Fisheries side-view illustration of a \(species.name.lowercased())")
        }
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func guideCard(_ number: String, _ title: String, _ body: String, places: [String] = []) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(number)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.headline)
            }
            Text(body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if !places.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(places, id: \.self) { place in
                            Text(place)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.cyan.opacity(0.15)))
                        }
                    }
                }
                Text("Typical range, not live sightings.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
