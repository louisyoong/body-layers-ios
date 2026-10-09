import Combine
import SceneKit
import simd

enum CameraViewDirection: String, CaseIterable {
    case front, back, side

    var label: String {
        switch self {
        case .front: return "Anterior perspective"
        case .back: return "Posterior perspective"
        case .side: return "Lateral perspective"
        }
    }

    var buttonTitle: String {
        switch self {
        case .front: return "Front"
        case .back: return "Back"
        case .side: return "Side"
        }
    }
}

@MainActor
protocol SceneControlling: AnyObject {
    func frame(view: CameraViewDirection, focusSelected: Bool)
    func zoom(by factor: Float)
}

/// What the shared 3D viewport and its overlay controls need from an atlas, so the
/// same `AnatomySceneView`, `ViewControlsBar` and `DetailCardView` can drive either
/// the human BodyParts3D atlas or an animal atlas.
@MainActor
protocol AtlasViewModel: ObservableObject {
    var rootAnatomyNode: SCNNode { get }
    var sceneController: SceneControlling? { get set }

    var currentView: CameraViewDirection { get }
    var isolated: Bool { get }
    var explosion: Double { get }
    var selectedPartId: String? { get }
    var visibleNodes: [SCNNode] { get }

    func node(for partId: String) -> SCNNode?
    /// The selectable part id for a hit-tested node, or nil if taps should pass through it.
    func tappablePartId(forNodeName name: String) -> String?
    /// Unit vector from the framed target toward the camera for each view preset.
    func cameraDirection(for view: CameraViewDirection) -> SIMD3<Float>

    func handleTap(partId: String)
    func clearSelection()
    func resetView()
    func toggleIsolate()
    func setExplosion(_ value: Double)
    func explosionEditingChanged(_ isEditing: Bool)
    func setViewDirection(_ direction: CameraViewDirection)
}

extension AtlasViewModel {
    func zoomIn() { sceneController?.zoom(by: 0.8) }
    func zoomOut() { sceneController?.zoom(by: 1.25) }
}
