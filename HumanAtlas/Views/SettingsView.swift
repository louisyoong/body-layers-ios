import SwiftUI
import UIKit

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appearanceMode") private var appearanceModeRaw: String = AppearanceMode.dark.rawValue

    private let appStoreID = "6816426498"
    // Flip to true once the app is actually live on the App Store — until then the
    // review link 404s, so keep the row hidden rather than show a dead link.
    private let isPublishedOnAppStore = false
    private let websiteURL = URL(string: "https://human-altas-organs-louis.vercel.app")!
    private let dataLicenseURL = URL(string: "https://dbarchive.biosciencedbc.jp/en/bodyparts3d/lic.html")!

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Appearance") {
                    Picker("Appearance", selection: $appearanceModeRaw) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.label).tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowSeparator(.hidden)
                }

                Section("About This Atlas") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("A body, revealed.")
                            .font(.headline)
                        Text("Choose the full body, heart, brain, kidneys, lungs, liver, stomach, pancreas, or spleen. Explore 2,234 anatomical meshes from the adult male BodyParts3D reference. Select a system, search for a structure, or tap directly on the body to inspect it.")
                        Text("Organ categories follow named concepts in the source dataset; the heart uses a focused selection of 93 structures. Chamber cavities appear as solid volumes. Hide Heart walls to inspect the interior. Colors and simplified geometry support exploration. For education, not diagnosis or surgical planning.")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
                }

                Section("About This App") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("\(appVersion) (\(buildNumber))")
                            .foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Source & License")
                        Text("Built with SwiftUI and SceneKit. Anatomical data from BodyParts3D, © The Database Center for Life Science.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    externalLinkRow("BodyParts3D Data License", url: dataLicenseURL)
                }

                Section {
                    if isPublishedOnAppStore {
                        Button {
                            rateOnAppStore()
                        } label: {
                            Label("Rate on the App Store", systemImage: "star.fill")
                        }
                    }
                    externalLinkRow("Visit Our Website", url: websiteURL, systemImage: "safari")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func externalLinkRow(_ title: String, url: URL, systemImage: String? = nil) -> some View {
        Link(destination: url) {
            HStack {
                if let systemImage {
                    Label(title, systemImage: systemImage)
                } else {
                    Text(title)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(.primary)
    }

    private func rateOnAppStore() {
        guard let url = URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review") else { return }
        UIApplication.shared.open(url)
    }
}
