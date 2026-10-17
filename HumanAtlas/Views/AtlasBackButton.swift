import SwiftUI

/// Back chevron for the atlas top bars. The glyph alone is ~17pt wide, so taps that
/// miss it fall through to the 3D scene; this pads it to a full 44pt hit target.
struct AtlasBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.title3.weight(.semibold))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .padding(.leading, -12)
        .accessibilityLabel("Back to study categories")
    }
}

extension View {
    /// iOS-style swipe-from-left-edge to go back. A thin strip on the leading edge
    /// claims the drag so it doesn't rotate the 3D scene instead. It starts below the
    /// top bar so it never sits on top of (and swallows taps meant for) the back button.
    func edgeSwipeBack(perform action: @escaping () -> Void) -> some View {
        overlay(alignment: .leading) {
            Color.clear
                .frame(width: 20)
                .contentShape(Rectangle())
                .padding(.top, 120)
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onEnded { value in
                            if value.translation.width > 80,
                               abs(value.translation.height) < value.translation.width {
                                action()
                            }
                        }
                )
        }
    }
}
