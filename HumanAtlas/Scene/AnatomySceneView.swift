import SceneKit
import SwiftUI
import simd

final class OrbitSCNView: SCNView {
    var onLayout: (() -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        onLayout?()
    }
}

struct AnatomySceneView: UIViewRepresentable {
    let viewModel: any AtlasViewModel
    @Environment(\.colorScheme) private var colorScheme

    func makeCoordinator() -> SceneCoordinator {
        SceneCoordinator(viewModel: viewModel)
    }

    func makeUIView(context: Context) -> OrbitSCNView {
        let scnView = OrbitSCNView()
        context.coordinator.setup(scnView: scnView)
        context.coordinator.applyTheme(AppTheme(colorScheme: colorScheme))
        return scnView
    }

    func updateUIView(_ uiView: OrbitSCNView, context: Context) {
        // Most state changes are pushed imperatively through `viewModel.sceneController`;
        // the color scheme is the one input this representable reads directly, since it
        // drives the viewport background/lighting rather than the anatomy itself.
        context.coordinator.applyTheme(AppTheme(colorScheme: colorScheme))
    }
}

@MainActor
final class SceneCoordinator: NSObject, SceneControlling {
    private let viewModel: any AtlasViewModel
    private weak var scnView: SCNView?
    private let scene = SCNScene()
    private let cameraNode = SCNNode()

    private var target = SIMD3<Float>(0, 0.85, 0)
    private var radius: Float = 2.4
    private var yaw: Float = 0.12
    private var pitch: Float = 0.2
    private var lastPanTranslation: CGPoint = .zero
    private var lastPanTranslation2: CGPoint = .zero
    private var ambientLight: SCNLight?

    init(viewModel: any AtlasViewModel) {
        self.viewModel = viewModel
    }

    func setup(scnView: OrbitSCNView) {
        self.scnView = scnView
        scnView.scene = scene
        scnView.backgroundColor = UIColor(hex: "#101820")
        scnView.rendersContinuously = true
        scnView.antialiasingMode = .multisampling4X
        scnView.isUserInteractionEnabled = true

        let camera = SCNCamera()
        camera.fieldOfView = 35
        camera.zNear = 0.005
        camera.zFar = 100
        cameraNode.camera = camera
        scene.rootNode.addChildNode(cameraNode)
        updateCameraTransform()

        setupLighting()
        scene.rootNode.addChildNode(viewModel.rootAnatomyNode)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.maximumNumberOfTouches = 1
        let twoFingerPan = UIPanGestureRecognizer(target: self, action: #selector(handleTwoFingerPan(_:)))
        twoFingerPan.minimumNumberOfTouches = 2
        twoFingerPan.maximumNumberOfTouches = 2
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        scnView.addGestureRecognizer(pan)
        scnView.addGestureRecognizer(twoFingerPan)
        scnView.addGestureRecognizer(pinch)
        scnView.addGestureRecognizer(tap)

        scnView.onLayout = { [weak self] in
            guard let self else { return }
            self.frame(view: self.viewModel.currentView, focusSelected: self.viewModel.isolated)
        }

        viewModel.sceneController = self
    }

    /// Applies the current Light/Dark setting to the viewport itself — the background
    /// behind the anatomy and its ambient fill — while leaving each system's tissue
    /// color (bone, muscle, vessels, etc.) untouched, since those encode meaning.
    func applyTheme(_ theme: AppTheme) {
        scnView?.backgroundColor = UIColor(hex: theme.sceneBackgroundHex)
        ambientLight?.color = UIColor(hex: theme.ambientLightHex)
        ambientLight?.intensity = theme.ambientLightIntensity
    }

    private func setupLighting() {
        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.color = UIColor(hex: "#a9b0a0")
        ambient.intensity = 350
        ambientLight = ambient
        let ambientNode = SCNNode()
        ambientNode.light = ambient
        scene.rootNode.addChildNode(ambientNode)

        let key = SCNLight()
        key.type = .directional
        key.intensity = 1300
        key.color = UIColor.white
        let keyNode = SCNNode()
        keyNode.light = key
        keyNode.position = SCNVector3(-3, 4, 5)
        keyNode.look(at: SCNVector3(0, 0.85, 0))
        scene.rootNode.addChildNode(keyNode)

        let fill = SCNLight()
        fill.type = .directional
        fill.intensity = 800
        fill.color = UIColor.white
        let fillNode = SCNNode()
        fillNode.light = fill
        fillNode.position = SCNVector3(3, 2, -3)
        fillNode.look(at: SCNVector3(0, 0.85, 0))
        scene.rootNode.addChildNode(fillNode)

        scene.lightingEnvironment.contents = UIColor(white: 0.55, alpha: 1)
    }

    private func updateCameraTransform() {
        let cosPitch = cos(pitch)
        let x = target.x + radius * cosPitch * sin(yaw)
        let y = target.y + radius * sin(pitch)
        let z = target.z + radius * cosPitch * cos(yaw)
        let position = SIMD3<Float>(x, y, z)
        cameraNode.position = SCNVector3(position)
        cameraNode.simdOrientation = Self.lookAtOrientation(from: position, target: target)
    }

    /// Builds an absolute look-at orientation instead of using `SCNNode.look(at:)`,
    /// which derives an *incremental* rotation from the node's current orientation
    /// and produces a degenerate (zero) quaternion when the new direction is exactly
    /// 180° from the old one (e.g. flipping from the "front" to the "back" view).
    private static func lookAtOrientation(from position: SIMD3<Float>, target: SIMD3<Float>) -> simd_quatf {
        let forward = simd_normalize(target - position)
        var worldUp = SIMD3<Float>(0, 1, 0)
        if abs(simd_dot(forward, worldUp)) > 0.999 {
            worldUp = SIMD3<Float>(0, 0, 1)
        }
        let right = simd_normalize(simd_cross(forward, worldUp))
        let up = simd_cross(right, forward)
        let rotationMatrix = simd_float3x3(columns: (right, up, -forward))
        return simd_quatf(rotationMatrix)
    }

    // MARK: - Gestures

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            lastPanTranslation = .zero
        case .changed:
            let t = gesture.translation(in: gesture.view)
            let dx = Float(t.x - lastPanTranslation.x)
            let dy = Float(t.y - lastPanTranslation.y)
            yaw -= dx * 0.006
            pitch = min(max(pitch - dy * 0.006, -1.4), 1.4)
            updateCameraTransform()
            lastPanTranslation = t
        default:
            lastPanTranslation = .zero
        }
    }

    /// Two-finger drag shifts the orbit target (pivot) itself, so users can recenter
    /// the view on a specific area — e.g. the head — instead of being stuck orbiting
    /// and zooming around whatever point was framed initially.
    @objc private func handleTwoFingerPan(_ gesture: UIPanGestureRecognizer) {
        guard let scnView else { return }
        switch gesture.state {
        case .began:
            lastPanTranslation2 = .zero
        case .changed:
            let t = gesture.translation(in: gesture.view)
            let dx = Float(t.x - lastPanTranslation2.x)
            let dy = Float(t.y - lastPanTranslation2.y)

            let fovRadians = Float(cameraNode.camera?.fieldOfView ?? 35) * .pi / 180
            let viewHeight = Float(scnView.bounds.height)
            guard viewHeight > 0 else { return }
            let worldUnitsPerPoint = (2 * radius * tan(fovRadians / 2)) / viewHeight

            let right = cameraNode.simdWorldRight
            let up = cameraNode.simdWorldUp
            target -= right * (dx * worldUnitsPerPoint)
            target += up * (dy * worldUnitsPerPoint)
            updateCameraTransform()
            lastPanTranslation2 = t
        default:
            lastPanTranslation2 = .zero
        }
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard gesture.state == .changed else { return }
        radius = min(max(radius / Float(gesture.scale), 0.05), 12)
        gesture.scale = 1
        updateCameraTransform()
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let scnView else { return }
        let point = gesture.location(in: scnView)
        let hitResults = scnView.hitTest(point, options: [
            .searchMode: SCNHitTestSearchMode.all.rawValue,
            .ignoreHiddenNodes: true,
            .backFaceCulling: false,
        ])
        for hit in hitResults {
            guard let name = hit.node.name,
                  let partId = viewModel.tappablePartId(forNodeName: name) else { continue }
            viewModel.handleTap(partId: partId)
            return
        }
    }

    // MARK: - SceneControlling

    func frame(view: CameraViewDirection, focusSelected: Bool) {
        guard let scnView else { return }
        let nodes: [SCNNode]
        if focusSelected, let id = viewModel.selectedPartId, let n = viewModel.node(for: id) {
            nodes = [n]
        } else {
            nodes = viewModel.visibleNodes
        }

        var lo = SIMD3<Float>(repeating: .greatestFiniteMagnitude)
        var hi = SIMD3<Float>(repeating: -.greatestFiniteMagnitude)
        var found = false
        for n in nodes {
            guard let geo = n.geometry else { continue }
            let box = geo.boundingBox
            let p = n.position.simd
            lo = simd_min(lo, box.min.simd + p)
            hi = simd_max(hi, box.max.simd + p)
            found = true
        }

        let center = found ? (lo + hi) * 0.5 : target
        let size = found ? (hi - lo) : SIMD3<Float>(0.7, 1.8, 0.4)

        let dir = viewModel.cameraDirection(for: view)

        // Measure the box as seen from `dir` (not just its x/y extents), so long
        // horizontal subjects like the whale frame correctly from every preset.
        var worldUp = SIMD3<Float>(0, 1, 0)
        if abs(simd_dot(dir, worldUp)) > 0.999 { worldUp = SIMD3<Float>(0, 0, 1) }
        let right = simd_normalize(simd_cross(worldUp, dir))
        let up = simd_cross(dir, right)
        let width = simd_dot(simd_abs(right), size)
        let height = simd_dot(simd_abs(up), size)

        let fovRadians = Float(cameraNode.camera?.fieldOfView ?? 35) * .pi / 180
        let bounds = scnView.bounds
        let aspect: Float = bounds.height > 0 ? Float(bounds.width / bounds.height) : 1
        let distance = max(
            0.06,
            max(width / min(aspect, 1), height) / (2 * tan(fovRadians / 2)) * 1.3
        )

        target = center
        let position = target + dir * distance
        cameraNode.position = SCNVector3(position)
        cameraNode.simdOrientation = Self.lookAtOrientation(from: position, target: target)

        let rel = position - target
        radius = simd_length(rel)
        if radius > 0.0001 {
            yaw = atan2(rel.x, rel.z)
            pitch = asin(min(max(rel.y / radius, -1), 1))
        }
    }

    func zoom(by factor: Float) {
        radius = min(max(radius * factor, 0.05), 12)
        updateCameraTransform()
    }
}
