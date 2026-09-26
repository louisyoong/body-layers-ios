import SwiftUI

struct AboutSheetView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("SOURCE & SCOPE")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.cyan)
                    Text("A body, revealed.")
                        .font(.title2.weight(.bold))
                    Text("Choose the full body, heart, brain, kidneys, lungs, liver, stomach, pancreas, or spleen. Explore 2,234 anatomical meshes from the adult male BodyParts3D reference. Select a system, search for a structure, or click directly on the body to inspect it.")
                    Text("Organ categories follow named concepts in the source dataset; the heart uses a focused selection of 93 structures. Chamber cavities appear as solid volumes. Hide Heart walls to inspect the interior. This model does not represent every structure or human variation. Colors and simplified geometry support exploration. For education, not diagnosis or surgical planning.")
                    Text("BodyParts3D, © The Database Center for Life Science, licensed under Creative Commons Attribution 4.0 International.")
                    Link("Dataset & license ↗", destination: URL(string: "https://dbarchive.biosciencedbc.jp/en/bodyparts3d/lic.html")!)
                }
                .font(.body)
                .padding()
            }
            .navigationTitle("About this atlas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
