import Foundation

enum AtlasLoaderError: Error {
    case missingResource(String)
    case sizeMismatch(String)
}

struct PartMeshData: Sendable {
    let part: AtlasPart
    let positions: [Float]
    let normals: [Float]
    let indices: [UInt32]
}

enum AtlasLoader {
    static func loadCatalog() throws -> (Atlas, CategoryCatalog) {
        guard let atlasURL = Bundle.main.url(forResource: "atlas", withExtension: "json") else {
            throw AtlasLoaderError.missingResource("atlas.json")
        }
        guard let categoriesURL = Bundle.main.url(forResource: "categories", withExtension: "json") else {
            throw AtlasLoaderError.missingResource("categories.json")
        }
        let atlas = try JSONDecoder().decode(Atlas.self, from: Data(contentsOf: atlasURL))
        let catalog = try JSONDecoder().decode(CategoryCatalog.self, from: Data(contentsOf: categoriesURL))
        return (atlas, catalog)
    }

    /// Streams decoded part geometry as chunks are decompressed on background workers,
    /// mirroring the web app's concurrent chunk loading (3 workers).
    static func streamGeometry(atlas: Atlas) -> AsyncThrowingStream<PartMeshData, Error> {
        AsyncThrowingStream { continuation in
            let task = Task.detached(priority: .userInitiated) {
                let chunkCount = atlas.chunks.count
                let counter = ChunkCounter(total: chunkCount)
                do {
                    try await withThrowingTaskGroup(of: Void.self) { group in
                        let workerCount = min(3, chunkCount)
                        for _ in 0..<workerCount {
                            group.addTask {
                                while let i = await counter.next() {
                                    try Task.checkCancellation()
                                    try processChunk(i, atlas: atlas, continuation: continuation)
                                }
                            }
                        }
                        try await group.waitForAll()
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private static func processChunk(
        _ i: Int,
        atlas: Atlas,
        continuation: AsyncThrowingStream<PartMeshData, Error>.Continuation
    ) throws {
        let chunk = atlas.chunks[i]
        let fileName = "body-\(i)"
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "bin.gz") else {
            throw AtlasLoaderError.missingResource(fileName)
        }
        let compressed = try Data(contentsOf: url)
        let buffer = try Gzip.decompress(compressed)
        guard buffer.count == chunk.bytes else {
            throw AtlasLoaderError.sizeMismatch(fileName)
        }

        let parts = atlas.parts.filter { $0.chunk == i }
        for part in parts {
            let positionsByteCount = part.vertexCount * 3 * MemoryLayout<Float32>.size
            let normalsByteCount = part.vertexCount * 3 * MemoryLayout<Int16>.size
            let indicesByteCount = part.indexCount * MemoryLayout<UInt32>.size

            let positions: [Float] = buffer
                .subdata(in: part.positions..<(part.positions + positionsByteCount))
                .withUnsafeBytes { Array($0.bindMemory(to: Float32.self)) }

            let normalsRaw: [Int16] = buffer
                .subdata(in: part.normals..<(part.normals + normalsByteCount))
                .withUnsafeBytes { Array($0.bindMemory(to: Int16.self)) }
            let normals = normalsRaw.map { max(Float($0) / 32767.0, -1.0) }

            let indices: [UInt32] = buffer
                .subdata(in: part.indices..<(part.indices + indicesByteCount))
                .withUnsafeBytes { Array($0.bindMemory(to: UInt32.self)) }

            continuation.yield(PartMeshData(part: part, positions: positions, normals: normals, indices: indices))
        }
    }
}

/// Hands out chunk indices to concurrent workers one at a time.
private actor ChunkCounter {
    private var nextIndex = 0
    private let total: Int

    init(total: Int) {
        self.total = total
    }

    func next() -> Int? {
        guard nextIndex < total else { return nil }
        defer { nextIndex += 1 }
        return nextIndex
    }
}
