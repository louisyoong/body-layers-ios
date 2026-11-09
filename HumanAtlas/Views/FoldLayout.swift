import SwiftUI

/// Where iPhone Duo's fold (its `.division` reserved region) crosses a view.
/// `nil` on every other device, and on iOS versions before 27.1.
struct FoldInfo: Equatable {
    /// The crease, in the reading view's local (safe-area) coordinates.
    var crease: CGRect
    var container: CGSize
    var safeArea: EdgeInsets

    /// Book pose: the crease runs top to bottom, splitting leading and trailing panes.
    /// Otherwise it runs side to side (tabletop), splitting top and bottom.
    var isVertical: Bool { crease.height > crease.width }

    static func read(_ proxy: GeometryProxy, includeInactive: Bool = false) -> FoldInfo? {
        guard #available(iOS 27.1, *) else { return nil }
        let options: ReservedRegion.QueryOptions = includeInactive ? .includeInactive : []
        guard let region = proxy.reservedRegions(kind: .division, options: options).first,
              region.frame.width > 0 || region.frame.height > 0 else { return nil }
        return FoldInfo(crease: region.frame, container: proxy.size, safeArea: proxy.safeAreaInsets)
    }
}

extension View {
    /// Reports this view's `FoldInfo` whenever its geometry or the device's fold changes.
    /// Attach it to a view whose size doesn't depend on the result, to avoid a layout loop.
    func onFoldChange(includeInactive: Bool = false, _ action: @escaping (FoldInfo?) -> Void) -> some View {
        onGeometryChange(for: FoldInfo?.self) { proxy in
            FoldInfo.read(proxy, includeInactive: includeInactive)
        } action: { action($0) }
    }
}

/// Shared page layout for the human and animal atlases: a full-bleed 3D scene, a header
/// pinned to the top, and a control panel at the bottom.
///
/// On wide screens the panel is capped so it doesn't stretch edge to edge. When iPhone Duo
/// is partially folded, nothing important sits on the crease: in tabletop pose the model
/// renders in the upper half and the controls stay below; in book pose the model takes the
/// leading pane and the controls move to the trailing one.
struct FoldAwareAtlasLayout<SceneContent: View, Header: View, Panel: View>: View {
    @ViewBuilder var scene: SceneContent
    @ViewBuilder var header: Header
    @ViewBuilder var panel: Panel

    @State private var fold: FoldInfo?

    private static var maxPanelWidth: CGFloat { 600 }

    var body: some View {
        ZStack {
            scene
                .padding(sceneInsets)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Spacer(minLength: 0)
                panel
                    .frame(maxWidth: panelWidth)
                    .frame(maxWidth: .infinity, alignment: panelAlignment)
                    .padding(.bottom, 8)
            }
        }
        .onFoldChange { newFold in
            withAnimation(.easeInOut(duration: 0.25)) { fold = newFold }
        }
    }

    /// Shrinks the scene (which ignores the safe area, so these are full-screen insets)
    /// to the pane on one side of the crease.
    private var sceneInsets: EdgeInsets {
        guard let fold else { return EdgeInsets() }
        if fold.isVertical {
            let trailing = fold.container.width - fold.crease.minX + fold.safeArea.trailing
            return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: max(0, trailing))
        }
        let bottom = fold.container.height - fold.crease.minY + fold.safeArea.bottom
        return EdgeInsets(top: 0, leading: 0, bottom: max(0, bottom), trailing: 0)
    }

    private var panelWidth: CGFloat {
        guard let fold, fold.isVertical else { return Self.maxPanelWidth }
        return min(Self.maxPanelWidth, max(0, fold.container.width - fold.crease.maxX))
    }

    private var panelAlignment: Alignment {
        fold?.isVertical == true ? .trailing : .center
    }
}
