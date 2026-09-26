import SwiftUI

@main
struct HumanAtlasApp: App {
    @AppStorage("appearanceMode") private var appearanceModeRaw: String = AppearanceMode.dark.rawValue

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme((AppearanceMode(rawValue: appearanceModeRaw) ?? .dark).colorScheme)
        }
    }
}
