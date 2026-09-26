import Foundation

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
