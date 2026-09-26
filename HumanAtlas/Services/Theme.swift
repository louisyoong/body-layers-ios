import SwiftUI

/// Centralizes the handful of colors our custom chrome hardcodes, so the whole
/// app (not just standard system controls) responds to the Light/Dark setting
/// in Settings — not only the SceneKit viewport background, but the overlay
/// panels, pills, and text drawn on top of it.
struct AppTheme {
    let colorScheme: ColorScheme

    var isDark: Bool { colorScheme == .dark }

    var sceneBackgroundHex: String { isDark ? "#101820" : "#eef1f4" }
    var ambientLightHex: String { isDark ? "#a9b0a0" : "#ffffff" }
    var ambientLightIntensity: CGFloat { isDark ? 350 : 550 }

    var primaryText: Color { isDark ? .white : .black }
    var secondaryText: Color { isDark ? .white.opacity(0.8) : .black.opacity(0.65) }

    var panelFill: Color { isDark ? Color.black.opacity(0.35) : Color.white.opacity(0.9) }
    var chipFill: Color { isDark ? Color.white.opacity(0.1) : Color.black.opacity(0.06) }
    var selectedFill: Color { isDark ? Color.white.opacity(0.9) : Color.black.opacity(0.85) }
    var selectedText: Color { isDark ? .black : .white }
    var hairline: Color { isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.1) }
    var scrim: Color { isDark ? Color.black.opacity(0.92) : Color.white.opacity(0.94) }
}

extension View {
    func appTheme(_ colorScheme: ColorScheme) -> AppTheme {
        AppTheme(colorScheme: colorScheme)
    }
}
