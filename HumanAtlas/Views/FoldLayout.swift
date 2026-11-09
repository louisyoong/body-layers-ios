import SwiftUI

/// Where iPhone Duo's fold (its `.division` reserved region) crosses the screen.
/// `nil` on every other device, and on iOS versions before 27.1.
///
/// Everything is in global (screen) coordinates, so views measured anywhere in the
/// hierarchy — inside or outside the safe area — can be compared against it directly.
struct FoldInfo: Equatable {
    var crease: CGRect

    /// Book pose: the crease runs top to bottom, splitting leading and trailing panes.
    /// Otherwise it runs side to side (tabletop), splitting top and bottom.
    var isVertical: Bool { crease.height > crease.width }

    static func read(_ proxy: GeometryProxy, includeInactive: Bool = false) -> FoldInfo? {
        guard #available(iOS 27.1, *) else { return nil }
        let options: ReservedRegion.QueryOptions = includeInactive ? .includeInactive : []
        guard let region = proxy.reservedRegions(kind: .division, options: options).first,
              region.frame.width > 0 || region.frame.height > 0 else { return nil }
        let origin = proxy.frame(in: .global).origin
        return FoldInfo(crease: region.frame.offsetBy(dx: origin.x, dy: origin.y))
    }
}

extension View {
    /// Reports this view's `FoldInfo` whenever its geometry or the device's fold changes.
    /// Attach it to a view whose size doesn't depend on the result, to avoid a layout loop.
    ///
    /// A closed iPhone Duo also counts as "folded", so the division region alone can't be
    /// trusted: the fold is only reported while the hinge says the device is open —
    /// partially open by default, or open at all with `includeInactive` (used for layout
    /// decisions that should hold steady while the device is flat).
    func onFoldChange(includeInactive: Bool = false, _ action: @escaping (FoldInfo?) -> Void) -> some View {
        modifier(FoldReader(includeInactive: includeInactive, action: action))
    }
}

private struct FoldReader: ViewModifier {
    let includeInactive: Bool
    let action: (FoldInfo?) -> Void

    @State private var regionFold: FoldInfo?
    /// Until the hinge reports in, assume it's closed and lay out normally.
    @State private var hingeAllowsFold = false

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: FoldInfo?.self) { proxy in
                FoldInfo.read(proxy, includeInactive: includeInactive)
            } action: { newFold in
                regionFold = newFold
                report()
            }
            .modifier(HingeStatusObserver(includeInactive: includeInactive) { allows in
                hingeAllowsFold = allows
                report()
            })
    }

    private func report() {
        action(hingeAllowsFold ? regionFold : nil)
    }
}

private struct HingeStatusObserver: ViewModifier {
    let includeInactive: Bool
    let onChange: (Bool) -> Void

    func body(content: Content) -> some View {
        if #available(iOS 27.1, *) {
            content.onHingeChange { _, context in
                guard let status = context.hinge?.status else { return onChange(false) }
                onChange(status == .partiallyOpen || (includeInactive && status == .fullyOpen))
            }
        } else {
            content
        }
    }
}

/// Shared page layout for the human and animal atlases: a full-bleed 3D scene, a header
/// pinned to the top, and controls (with an optional detail card above them) at the bottom.
///
/// The scene is told how much of it the header and controls cover, so the model is framed
/// in the visible gap between them rather than behind them. On wide screens the bottom
/// panel is capped so it doesn't stretch edge to edge. When iPhone Duo is partially
/// folded, nothing important sits on the crease: in tabletop pose the model renders in the
/// upper half and the controls stay below; in book pose the model takes the leading pane
/// and the controls move to the trailing one.
struct FoldAwareAtlasLayout<SceneContent: View, Header: View, Detail: View, Controls: View>: View {
    /// Builds the scene, given the insets (in the scene's own points) that overlays cover.
    var scene: (_ framingInsets: EdgeInsets) -> SceneContent
    @ViewBuilder var header: Header
    @ViewBuilder var detail: Detail
    @ViewBuilder var controls: Controls

    @State private var fold: FoldInfo?
    @State private var sceneFrame: CGRect = .zero
    @State private var headerFrame: CGRect = .zero
    @State private var controlsFrame: CGRect = .zero
    @State private var screenFrame: CGRect = .zero
    @State private var overlayFrame: CGRect = .zero

    private static var maxPanelWidth: CGFloat { 600 }
    /// Width of the card and of the controls when they sit side by side (padding included).
    private static var sidePanelWidth: CGFloat { 380 }

    private var measuredControls: some View {
        controls
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { controlsFrame = $0 }
    }

    /// Side by side needs room for both columns plus a gap. Book pose keeps the stacked
    /// panel, since it already has the whole trailing pane to itself.
    private var usesSideBySidePanel: Bool {
        if let fold, fold.isVertical { return false }
        return overlayFrame.width >= Self.sidePanelWidth * 2 - 60
    }

    var body: some View {
        ZStack {
            // Full-screen reference for the fold and the scene's insets.
            Color.clear
                .ignoresSafeArea()
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { screenFrame = $0 }
                .onFoldChange { newFold in
                    withAnimation(.easeInOut(duration: 0.25)) { fold = newFold }
                }

            scene(framingInsets)
                .padding(sceneInsets)
                .ignoresSafeArea()
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { sceneFrame = $0 }

            VStack(spacing: 0) {
                VStack(spacing: 0) { header }
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { headerFrame = $0 }
                Spacer(minLength: 0)
                if usesSideBySidePanel {
                    // Short, wide screens (a phone in landscape, iPad, iPhone Duo open):
                    // stacking the card on the controls would bury the model, so they
                    // share one row along the bottom instead.
                    HStack(alignment: .bottom, spacing: 0) {
                        detail
                            .frame(maxWidth: Self.sidePanelWidth, alignment: .bottomLeading)
                        Spacer(minLength: 0)
                        measuredControls
                            .frame(width: Self.sidePanelWidth)
                    }
                    .padding(.bottom, 8)
                } else {
                    VStack(spacing: 12) {
                        detail
                        measuredControls
                    }
                    .frame(maxWidth: panelWidth)
                    .frame(maxWidth: .infinity, alignment: panelAlignment)
                    .padding(.bottom, 8)
                }
            }
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { overlayFrame = $0 }
        }
    }

    /// How far the header and the controls bar reach into the scene. The detail card is
    /// left out on purpose: it comes and goes with selection, and reframing the camera
    /// every time would throw away the user's zoom and rotation.
    private var framingInsets: EdgeInsets {
        guard sceneFrame.width > 0, sceneFrame.height > 0 else { return EdgeInsets() }
        let margin: CGFloat = 8
        func overlapsHorizontally(_ rect: CGRect) -> Bool {
            rect.width > 0 && rect.minX < sceneFrame.maxX && rect.maxX > sceneFrame.minX
        }
        var insets = EdgeInsets()
        if overlapsHorizontally(headerFrame), headerFrame.maxY > sceneFrame.minY {
            insets.top = min(sceneFrame.height / 2, headerFrame.maxY - sceneFrame.minY + margin)
        }
        if overlapsHorizontally(controlsFrame), controlsFrame.minY < sceneFrame.maxY {
            insets.bottom = min(sceneFrame.height / 2, sceneFrame.maxY - controlsFrame.minY + margin)
        }
        return insets
    }

    /// Shrinks the scene (which ignores the safe area, so these are full-screen insets)
    /// to the pane on one side of the crease.
    private var sceneInsets: EdgeInsets {
        guard let fold, screenFrame.width > 0 else { return EdgeInsets() }
        if fold.isVertical {
            return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: max(0, screenFrame.maxX - fold.crease.minX))
        }
        return EdgeInsets(top: 0, leading: 0, bottom: max(0, screenFrame.maxY - fold.crease.minY), trailing: 0)
    }

    /// In book pose the panel fills the trailing pane: from the crease to the safe edge.
    private var panelWidth: CGFloat {
        guard let fold, fold.isVertical, overlayFrame.width > 0 else { return Self.maxPanelWidth }
        return min(Self.maxPanelWidth, max(0, overlayFrame.maxX - fold.crease.maxX))
    }

    private var panelAlignment: Alignment {
        fold?.isVertical == true ? .trailing : .center
    }
}
