import Combine
import Foundation
import QuartzCore
import SceneKit
import UIKit
import simd

struct SelectedDetail: Equatable {
    let systemName: String
    let partName: String
    let copy: String
    let partId: String
}

@MainActor
final class AnatomyViewModel: ObservableObject {
    // Static system palettes shown immediately, mirroring the web app's
    // module-level `systems`/`visible` constants that render before data loads.
    @Published var systems: [BodySystem] = BodySystems.all
    @Published var visibleSystemIds: Set<String> = Set(
        BodySystems.all.map(\.id).filter { $0 != "integumentary" && $0 != "connective" }
    )

    @Published var categories: [AnatomyCategory] = []
    @Published var currentCategoryId: String = "body"
    @Published var categoryName: String = "Full body"
    @Published var categoryNote: String = "Explore every body system in context."
    @Published var referenceName: String = "Adult male anatomy"
    @Published var partCountLabel: String = "Loading anatomy"
    @Published var layerCountLabel: String = "15 body systems"
    @Published var layerTitle: String = "Body systems"
    @Published var showInternalViewButton: Bool = false

    @Published var currentView: CameraViewDirection = .front
    @Published var viewLabel: String = CameraViewDirection.front.label
    @Published var explosion: Double = 0

    @Published var selectedPartId: String?
    @Published var selectedDetail: SelectedDetail?
    @Published var isolated: Bool = false

    @Published var searchQuery: String = "" {
        didSet { performSearch() }
    }
    @Published var searchResults: [AtlasPart] = []

    @Published var loadingProgress: Double = 0
    @Published var isLoaded: Bool = false
    @Published var loadError: String?

    weak var sceneController: SceneControlling?
    let rootAnatomyNode = SCNNode()

    private var atlas: Atlas?
    private var partsById: [String: AtlasPart] = [:]
    private var nodesById: [String: SCNNode] = [:]
    private var systemOverrides: [String: String] = [:]
    private var heartGroups: [String: String] = [:]
    private var allowedPartIds: Set<String>?
    private var categoryCenter = SIMD3<Float>(0, 0.85, 0)
    private var categorySize: Float = 1.8
    private var loadedPartsCount = 0

    /// Per-visible-part "at full explosion" offset, cached whenever visibility/grouping
    /// changes so that dragging the explode slider is a cheap O(visible) loop with no
    /// dictionary lookups or set/array scans — the expensive `updateVisibilityAndTransforms`
    /// pass only needs to re-run when what's visible actually changes, not on every tick.
    private struct ExplosionOffset {
        let node: SCNNode
        let offset: SIMD3<Float>
    }
    private var explosionOffsets: [ExplosionOffset] = []
    private var isDraggingExplosion = false

    var toggleAllLabel: String { visibleSystemIds.isEmpty ? "Show all" : "Hide all" }

    // MARK: - Loading

    func load() async {
        do {
            let (atlas, catalog) = try AtlasLoader.loadCatalog()
            self.atlas = atlas
            self.partsById = Dictionary(uniqueKeysWithValues: atlas.parts.map { ($0.id, $0) })
            self.heartGroups = catalog.heartGroups
            self.categories = catalog.categories

            if let brain = catalog.categories.first(where: { $0.id == "brain" }) {
                let brainSet = Set(brain.parts)
                for part in atlas.parts where part.system == "cardiac" && brainSet.contains(part.id) {
                    systemOverrides[part.id] = "nervous"
                }
            }
            partCountLabel = "\(atlas.parts.count) structures"

            for try await meshData in AtlasLoader.streamGeometry(atlas: atlas) {
                let sysId = systemOverrides[meshData.part.id] ?? meshData.part.system
                let colorHex = BodySystems.find(sysId, in: BodySystems.all)?.colorHex ?? "#b8bdaf"
                let node = GeometryBuilder.makeNode(from: meshData, colorHex: colorHex)
                nodesById[meshData.part.id] = node
                rootAnatomyNode.addChildNode(node)
                loadedPartsCount += 1
                loadingProgress = Double(loadedPartsCount) / Double(atlas.parts.count)
            }
            isLoaded = true
            setCategory(currentCategoryId)
        } catch {
            loadError = "\(error)"
        }
    }

    // MARK: - Grouping helpers

    private func effectiveSystem(_ part: AtlasPart) -> String {
        systemOverrides[part.id] ?? part.system
    }

    private func group(for part: AtlasPart) -> String {
        if currentCategoryId == "heart" {
            return heartGroups[part.id] ?? effectiveSystem(part)
        }
        return effectiveSystem(part)
    }

    private func included(_ part: AtlasPart) -> Bool {
        guard let allowed = allowedPartIds else { return true }
        return allowed.contains(part.id)
    }

    // MARK: - Category switching

    func setCategory(_ id: String) {
        guard let atlas, let cat = categories.first(where: { $0.id == id }) else { return }
        currentCategoryId = id
        allowedPartIds = id == "body" ? nil : Set(cat.parts)
        selectedPartId = nil
        selectedDetail = nil
        isolated = false
        explosion = 0
        searchQuery = ""
        searchResults = []

        if id == "heart" {
            systems = BodySystems.heart
        } else {
            systems = BodySystems.all.filter { sys in
                id == "body" || atlas.parts.contains { p in included(p) && effectiveSystem(p) == sys.id }
            }
        }
        visibleSystemIds = []
        for s in systems where id != "body" || (s.id != "integumentary" && s.id != "connective") {
            visibleSystemIds.insert(s.id)
        }

        recomputeCategoryBox()
        applyCategoryColors()
        updateVisibilityAndTransforms()

        categoryName = cat.name
        categoryNote = cat.note
        referenceName = id == "body" ? "Adult male anatomy" : cat.name + " anatomy"
        partCountLabel = "\(id == "body" ? atlas.parts.count : cat.parts.count) structures"
        layerCountLabel = "\(systems.count) layers"
        layerTitle = id == "body" ? "Body systems" : "Anatomical layers"
        showInternalViewButton = id == "heart"
        currentView = .front
        viewLabel = CameraViewDirection.front.label

        sceneController?.frame(view: .front, focusSelected: false)
    }

    private func recomputeCategoryBox() {
        guard let atlas else { return }
        var lo = SIMD3<Float>(repeating: .greatestFiniteMagnitude)
        var hi = SIMD3<Float>(repeating: -.greatestFiniteMagnitude)
        var found = false
        for part in atlas.parts where included(part) {
            guard let node = nodesById[part.id], let geo = node.geometry else { continue }
            node.position = SCNVector3Zero
            let box = geo.boundingBox
            lo = simd_min(lo, box.min.simd)
            hi = simd_max(hi, box.max.simd)
            found = true
        }
        if found {
            categoryCenter = (lo + hi) * 0.5
            categorySize = simd_length(hi - lo)
        }
    }

    private func applyCategoryColors() {
        guard let atlas else { return }
        for part in atlas.parts {
            guard let node = nodesById[part.id] else { continue }
            let g = group(for: part)
            var colorHex = BodySystems.find(g, in: systems)?.colorHex
                ?? BodySystems.find(effectiveSystem(part), in: BodySystems.all)?.colorHex
                ?? "#b8bdaf"
            if currentCategoryId == "heart" {
                let nameLower = part.name.lowercased()
                if g == "coronary", nameLower.contains("vein") || nameLower.contains("sinus") {
                    colorHex = "#617dae"
                }
                if g == "chambers", nameLower.contains("right") {
                    colorHex = "#758bb8"
                }
            }
            node.geometry?.firstMaterial?.diffuse.contents = UIColor(hex: colorHex)
        }
    }

    // MARK: - Visibility / transforms

    private func updateVisibilityAndTransforms() {
        guard let atlas else { return }

        // Systems only has a handful of entries, but `firstIndex` inside the 2234-part
        // loop below still adds up — resolve it once per system id instead.
        var systemIndexById: [String: Int] = [:]
        for (i, s) in systems.enumerated() { systemIndexById[s.id] = i }
        let systemCount = max(systems.count, 1)

        var newOffsets: [ExplosionOffset] = []
        newOffsets.reserveCapacity(atlas.parts.count)

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.15
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)

        for part in atlas.parts {
            guard let node = nodesById[part.id] else { continue }
            let inc = included(part)
            let g = group(for: part)
            let isSelected = part.id == selectedPartId
            let visible = inc && (isolated ? isSelected : (visibleSystemIds.contains(g) || isSelected))
            node.isHidden = !visible
            if visible {
                let idx = systemIndexById[g] ?? 0
                let angle = Float(idx) / Float(systemCount) * 2 * Float.pi
                let center = part.center
                let offset = SIMD3<Float>(
                    sin(angle) * categorySize * 0.65,
                    (center.y - categoryCenter.y) * 0.85,
                    cos(angle) * categorySize * 0.65
                )
                newOffsets.append(ExplosionOffset(node: node, offset: offset))
            }
            node.geometry?.firstMaterial?.emission.contents = isSelected ? GeometryBuilder.highlightColor : UIColor.black
        }

        explosionOffsets = newOffsets
        let explosionF = Float(explosion)
        for item in explosionOffsets {
            item.node.position = SCNVector3(item.offset * explosionF)
        }

        SCNTransaction.commit()
    }

    /// Cheap path for live-dragging the explode slider: no visibility/grouping work,
    /// just scales the cached per-part offsets — safe as long as what's visible hasn't
    /// changed since the last `updateVisibilityAndTransforms` call.
    private func applyExplosionOffsets(animated: Bool) {
        let explosionF = Float(explosion)
        if animated {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.08
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .linear)
        }
        for item in explosionOffsets {
            item.node.position = SCNVector3(item.offset * explosionF)
        }
        if animated {
            SCNTransaction.commit()
        }
    }

    // MARK: - Selection

    func select(partId: String) {
        guard let part = partsById[partId] else { return }
        selectedPartId = partId
        let g = group(for: part)
        let sys = BodySystems.find(g, in: systems)
        selectedDetail = SelectedDetail(
            systemName: sys?.name ?? "",
            partName: part.name,
            copy: sys?.info ?? "",
            partId: part.id
        )
        updateVisibilityAndTransforms()
        if isolated {
            sceneController?.frame(view: .front, focusSelected: true)
        }
    }

    func clearSelection() {
        selectedPartId = nil
        selectedDetail = nil
        isolated = false
        updateVisibilityAndTransforms()
        sceneController?.frame(view: .front, focusSelected: false)
    }

    func resetView() {
        explosion = 0
        clearSelection()
    }

    func toggleIsolate() {
        isolated.toggle()
        updateVisibilityAndTransforms()
        sceneController?.frame(view: currentView, focusSelected: isolated)
    }

    func toggleSystem(_ id: String) {
        if visibleSystemIds.contains(id) {
            visibleSystemIds.remove(id)
        } else {
            visibleSystemIds.insert(id)
        }
        isolated = false
        updateVisibilityAndTransforms()
    }

    func toggleAll() {
        if !visibleSystemIds.isEmpty {
            visibleSystemIds.removeAll()
        } else {
            for s in systems where s.id != "integumentary" {
                visibleSystemIds.insert(s.id)
            }
        }
        isolated = false
        updateVisibilityAndTransforms()
    }

    func revealHeartInterior() {
        visibleSystemIds.remove("walls")
        isolated = false
        updateVisibilityAndTransforms()
        sceneController?.frame(view: currentView, focusSelected: false)
    }

    func setExplosion(_ value: Double) {
        explosion = value
        if isolated {
            isolated = false
            updateVisibilityAndTransforms()
        } else {
            applyExplosionOffsets(animated: true)
        }
        // Re-framing walks every visible node's bounding box — too costly to do on
        // every intermediate tick while the slider is actively being dragged, so it's
        // deferred to `explosionEditingChanged` once the gesture actually ends.
        if !isDraggingExplosion {
            sceneController?.frame(view: currentView, focusSelected: false)
        }
    }

    /// Hook up to the explode `Slider`'s `onEditingChanged` so the expensive camera
    /// re-frame only happens once, when the user lifts their finger — not on every tick.
    func explosionEditingChanged(_ isEditing: Bool) {
        isDraggingExplosion = isEditing
        if !isEditing {
            sceneController?.frame(view: currentView, focusSelected: false)
        }
    }

    func setViewDirection(_ direction: CameraViewDirection) {
        currentView = direction
        viewLabel = direction.label
        sceneController?.frame(view: direction, focusSelected: isolated)
    }

    func zoomIn() { sceneController?.zoom(by: 0.8) }
    func zoomOut() { sceneController?.zoom(by: 1.25) }

    // MARK: - Search

    private func performSearch() {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty, let atlas else {
            searchResults = []
            return
        }
        searchResults = Array(
            atlas.parts
                .filter { included($0) }
                .filter { $0.name.lowercased().contains(query) || $0.id.lowercased().contains(query) }
                .prefix(35)
        )
    }

    func selectFromSearch(_ part: AtlasPart) {
        isolated = true
        select(partId: part.id)
        searchQuery = ""
        searchResults = []
    }

    // MARK: - Scene events

    func handleTap(partId: String) {
        guard partsById[partId] != nil else { return }
        select(partId: partId)
    }

    func isPartVisible(id: String) -> Bool {
        nodesById[id]?.isHidden == false
    }

    var visibleNodes: [SCNNode] {
        nodesById.values.filter { !$0.isHidden }
    }

    func node(for partId: String) -> SCNNode? {
        nodesById[partId]
    }

    func system(withId id: String) -> String? {
        partsById[id]?.system
    }
}
