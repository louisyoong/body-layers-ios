import SceneKit

enum GeometryBuilder {
    static func makeNode(from mesh: PartMeshData, colorHex: String) -> SCNNode {
        let vertexSource = SCNGeometrySource(
            data: mesh.positions.withUnsafeBufferPointer { Data(buffer: $0) },
            semantic: .vertex,
            vectorCount: mesh.part.vertexCount,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<Float>.size * 3
        )
        let normalSource = SCNGeometrySource(
            data: mesh.normals.withUnsafeBufferPointer { Data(buffer: $0) },
            semantic: .normal,
            vectorCount: mesh.part.vertexCount,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<Float>.size * 3
        )
        let element = SCNGeometryElement(
            data: mesh.indices.withUnsafeBufferPointer { Data(buffer: $0) },
            primitiveType: .triangles,
            primitiveCount: mesh.part.indexCount / 3,
            bytesPerIndex: MemoryLayout<UInt32>.size
        )

        let geometry = SCNGeometry(sources: [vertexSource, normalSource], elements: [element])
        geometry.firstMaterial = makeMaterial(colorHex: colorHex, isSkin: mesh.part.system == "integumentary")

        let node = SCNNode(geometry: geometry)
        node.name = mesh.part.id
        return node
    }

    static func makeMaterial(colorHex: String, isSkin: Bool) -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = UIColor(hex: colorHex)
        material.roughness.contents = 0.58
        material.metalness.contents = 0.03
        material.isDoubleSided = true
        if isSkin {
            material.transparency = 0.12
            material.writesToDepthBuffer = false
            material.blendMode = .alpha
        }
        return material
    }

    static let highlightColor = UIColor(hex: "#0d727a")
}
