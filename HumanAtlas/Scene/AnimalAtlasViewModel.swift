import Combine
import Foundation
import QuartzCore
import SceneKit
import UIKit
import simd

@MainActor
final class AnimalAtlasViewModel: AtlasViewModel {
    let species: [WhaleSpecies] = WhaleCatalog.all
    let systems: [BodySystem] = WhaleCatalog.parts

    @Published private(set) var currentSpeciesIndex = 0
    @Published var visibleSystemIds: Set<String> = Set(WhaleCatalog.parts.map(\.id))
    /// Mirrors the web app's "See-through body" toggle: the skin and fins turn into a
    /// faint shell so the organs read through them, and taps pass through to organs.
    @Published private(set) var seeThrough = true

    @Published private(set) var currentView: CameraViewDirection = .side
    @Published private(set) var explosion: Double = 0
    @Published private(set) var selectedPartId: String?
    @Published private(set) var selectedDetail: SelectedDetail?
    @Published private(set) var isolated = false
    @Published private(set) var isBuilding = false

    weak var sceneController: SceneControlling?
    let rootAnatomyNode = SCNNode()

    private var meshCache: [String: [AnimalPartMesh]] = [:]
    private var nodesById: [String: SCNNode] = [:]
    private var bodyCenter = SIMD3<Float>.zero
    private var bodySize: Float = 1.9

    private struct ExplosionOffset {
        let node: SCNNode
        let offset: SIMD3<Float>
    }
    private var explosionOffsets: [ExplosionOffset] = []
    private var isDraggingExplosion = false

    var currentSpecies: WhaleSpecies { species[currentSpeciesIndex] }
    var toggleAllLabel: String { visibleSystemIds.isEmpty ? "Show all" : "Hide all" }

    // MARK: - Species

    func loadIfNeeded() {
        guard nodesById.isEmpty, !isBuilding else { return }
        selectSpecies(currentSpeciesIndex)
    }

    func selectSpecies(_ index: Int) {
        guard species.indices.contains(index) else { return }
        currentSpeciesIndex = index
        selectedPartId = nil
        selectedDetail = nil
        isolated = false
        explosion = 0

        let slug = species[index].slug
        if let cached = meshCache[slug] {
            install(cached)
            return
        }
        isBuilding = true
        Task {
            let meshes = await Task.detached(priority: .userInitiated) {
                WhaleGeometry.build(slug: slug)
            }.value
            meshCache[slug] = meshes
            // The user may have picked another species while this one was generating.
            guard currentSpecies.slug == slug else { return }
            install(meshes)
            isBuilding = false
        }
    }

    private func install(_ meshes: [AnimalPartMesh]) {
        for node in nodesById.values { node.removeFromParentNode() }
        nodesById = [:]
        for mesh in meshes {
            let node = Self.makeNode(from: mesh)
            rootAnatomyNode.addChildNode(node)
            nodesById[mesh.id] = node
        }

        var lo = SIMD3<Float>(repeating: .greatestFiniteMagnitude)
        var hi = SIMD3<Float>(repeating: -.greatestFiniteMagnitude)
        for node in nodesById.values {
            let box = node.boundingBox
            lo = simd_min(lo, box.min.simd)
            hi = simd_max(hi, box.max.simd)
        }
        if lo.x <= hi.x {
            bodyCenter = (lo + hi) * 0.5
            bodySize = simd_length(hi - lo)
        }

        applyMaterialModes()
        updateVisibilityAndTransforms()
        sceneController?.frame(view: currentView, focusSelected: false)
    }

    private static func makeNode(from mesh: AnimalPartMesh) -> SCNNode {
        func source(_ values: [Float], _ semantic: SCNGeometrySource.Semantic) -> SCNGeometrySource {
            SCNGeometrySource(
                data: values.withUnsafeBufferPointer { Data(buffer: $0) },
                semantic: semantic,
                vectorCount: mesh.vertexCount,
                usesFloatComponents: true,
                componentsPerVector: 3,
                bytesPerComponent: MemoryLayout<Float>.size,
                dataOffset: 0,
                dataStride: MemoryLayout<Float>.size * 3
            )
        }
        let element = SCNGeometryElement(
            data: mesh.indices.withUnsafeBufferPointer { Data(buffer: $0) },
            primitiveType: .triangles,
            primitiveCount: mesh.indices.count / 3,
            bytesPerIndex: MemoryLayout<UInt32>.size
        )
        let geometry = SCNGeometry(
            sources: [source(mesh.positions, .vertex), source(mesh.normals, .normal), source(mesh.colors, .color)],
            elements: [element]
        )
        // White diffuse so the baked per-vertex colors come through unchanged.
        let material = GeometryBuilder.makeMaterial(colorHex: "#ffffff", isSkin: false)
        material.roughness.contents = 0.5
        geometry.firstMaterial = material

        let node = SCNNode(geometry: geometry)
        node.name = mesh.id
        return node
    }

    // MARK: - Visibility / transforms

    private func isGhosted(_ id: String) -> Bool {
        seeThrough && WhaleCatalog.exteriorIds.contains(id) && id != selectedPartId
    }

    private func applyMaterialModes() {
        for (id, node) in nodesById {
            guard let material = node.geometry?.firstMaterial else { continue }
            let ghost = isGhosted(id)
            // Node opacity rather than `material.transparency`: with baked vertex colors the
            // latter left the shell nearly opaque and tinted every organ skin-blue.
            node.opacity = ghost ? 0.16 : 1
            material.writesToDepthBuffer = !ghost
            node.renderingOrder = ghost ? 10 : 0
        }
    }

    private func updateVisibilityAndTransforms() {
        let others = systems.filter { $0.id != "Skin" }
        var newOffsets: [ExplosionOffset] = []

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.15
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)

        for (id, node) in nodesById {
            let isSelected = id == selectedPartId
            let visible = isolated ? isSelected : (visibleSystemIds.contains(id) || isSelected)
            node.isHidden = !visible
            node.geometry?.firstMaterial?.emission.contents = isSelected ? GeometryBuilder.highlightColor : UIColor.black

            // The skin stays put as the reference shell; everything else fans out
            // around the body's long axis so organs separate from each other.
            if visible, id != "Skin", let idx = others.firstIndex(where: { $0.id == id }) {
                let box = node.boundingBox
                let center = (box.min.simd + box.max.simd) * 0.5
                let angle = Float(idx) / Float(others.count) * 2 * Float.pi
                let offset = SIMD3<Float>(
                    (center.x - bodyCenter.x) * 0.5,
                    sin(angle) * bodySize * 0.28,
                    cos(angle) * bodySize * 0.28
                )
                newOffsets.append(ExplosionOffset(node: node, offset: offset))
            } else {
                node.position = SCNVector3Zero
            }
        }

        explosionOffsets = newOffsets
        let explosionF = Float(explosion)
        for item in explosionOffsets {
            item.node.position = SCNVector3(item.offset * explosionF)
        }
        SCNTransaction.commit()
    }

    // MARK: - Selection

    func select(partId: String) {
        guard let part = systems.first(where: { $0.id == partId }) else { return }
        selectedPartId = partId
        // Like the web app: picking an organ switches the body back to see-through.
        if !WhaleCatalog.exteriorIds.contains(partId) { seeThrough = true }
        selectedDetail = SelectedDetail(
            systemName: currentSpecies.name,
            partName: part.name,
            copy: part.info,
            partId: part.id
        )
        applyMaterialModes()
        updateVisibilityAndTransforms()
        if isolated {
            sceneController?.frame(view: currentView, focusSelected: true)
        }
    }

    func handleTap(partId: String) {
        select(partId: partId)
    }

    func clearSelection() {
        selectedPartId = nil
        selectedDetail = nil
        isolated = false
        applyMaterialModes()
        updateVisibilityAndTransforms()
        sceneController?.frame(view: currentView, focusSelected: false)
    }

    func resetView() {
        explosion = 0
        currentView = .side
        clearSelection()
    }

    func toggleIsolate() {
        isolated.toggle()
        updateVisibilityAndTransforms()
        sceneController?.frame(view: currentView, focusSelected: isolated)
    }

    func toggleSeeThrough() {
        seeThrough.toggle()
        applyMaterialModes()
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
        if visibleSystemIds.isEmpty {
            visibleSystemIds = Set(systems.map(\.id))
        } else {
            visibleSystemIds.removeAll()
        }
        isolated = false
        updateVisibilityAndTransforms()
    }

    func setExplosion(_ value: Double) {
        explosion = value
        if isolated {
            isolated = false
            updateVisibilityAndTransforms()
        } else {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.08
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .linear)
            for item in explosionOffsets {
                item.node.position = SCNVector3(item.offset * Float(value))
            }
            SCNTransaction.commit()
        }
        if !isDraggingExplosion {
            sceneController?.frame(view: currentView, focusSelected: false)
        }
    }

    func explosionEditingChanged(_ isEditing: Bool) {
        isDraggingExplosion = isEditing
        if !isEditing {
            sceneController?.frame(view: currentView, focusSelected: false)
        }
    }

    func setViewDirection(_ direction: CameraViewDirection) {
        currentView = direction
        sceneController?.frame(view: direction, focusSelected: isolated)
    }

    // MARK: - AtlasViewModel

    var visibleNodes: [SCNNode] {
        nodesById.values.filter { !$0.isHidden }
    }

    func node(for partId: String) -> SCNNode? {
        nodesById[partId]
    }

    func tappablePartId(forNodeName name: String) -> String? {
        guard nodesById[name] != nil, !isGhosted(name) else { return nil }
        return name
    }

    /// The whale lies along x with its head toward −x, so "front" looks at the head,
    /// "back" at the flukes, and "side" is the classic field-guide profile.
    func cameraDirection(for view: CameraViewDirection) -> SIMD3<Float> {
        switch view {
        case .front: return simd_normalize(SIMD3<Float>(-1, 0.15, 0.3))
        case .back: return simd_normalize(SIMD3<Float>(1, 0.15, 0.3))
        case .side: return simd_normalize(SIMD3<Float>(-0.22, 0.18, 1))
        }
    }
}
