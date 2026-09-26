import Foundation

struct Atlas: Decodable {
    let parts: [AtlasPart]
    let chunks: [AtlasChunk]
}

struct AtlasPart: Decodable {
    let id: String
    let name: String
    let conceptId: String
    let system: String
    let chunk: Int
    let positions: Int
    let normals: Int
    let indices: Int
    let vertexCount: Int
    let indexCount: Int
    let bounds: [[Double]]

    var center: SIMD3<Float> {
        guard bounds.count == 2 else { return .zero }
        let lo = bounds[0], hi = bounds[1]
        return SIMD3<Float>(
            Float((lo[0] + hi[0]) * 0.5),
            Float((lo[1] + hi[1]) * 0.5),
            Float((lo[2] + hi[2]) * 0.5)
        )
    }
}

struct AtlasChunk: Decodable {
    let url: String
    let bytes: Int
    let gzip: String
    let gzipBytes: Int
}

struct CategoryCatalog: Decodable {
    let categories: [AnatomyCategory]
    let heartGroups: [String: String]
}

struct AnatomyCategory: Decodable {
    let id: String
    let name: String
    let note: String
    let parts: [String]
}

struct BodySystem {
    let id: String
    let name: String
    let colorHex: String
    let info: String
}

enum BodySystems {
    static let all: [BodySystem] = [
        BodySystem(id: "skeletal", name: "Skeleton", colorHex: "#d9cfaf", info: "Bones support the body, protect internal organs, and provide attachment points for muscles."),
        BodySystem(id: "muscular", name: "Muscles", colorHex: "#ae6458", info: "Skeletal muscles produce movement, stabilize joints, and maintain posture."),
        BodySystem(id: "cardiac", name: "Heart", colorHex: "#b45e58", info: "The heart pumps blood through the lungs and the rest of the body."),
        BodySystem(id: "arterial", name: "Arteries", colorHex: "#c65b4b", info: "Arteries carry blood away from the heart."),
        BodySystem(id: "venous", name: "Veins", colorHex: "#5d87a9", info: "Veins carry blood toward the heart."),
        BodySystem(id: "nervous", name: "Nervous system", colorHex: "#d6b564", info: "The brain, spinal cord, and peripheral nerves process and transmit signals."),
        BodySystem(id: "respiratory", name: "Respiratory", colorHex: "#c3929b", info: "The airways and lungs support breathing and gas exchange."),
        BodySystem(id: "digestive", name: "Digestive", colorHex: "#bb936e", info: "The digestive system processes food, absorbs nutrients, and eliminates waste."),
        BodySystem(id: "urinary", name: "Urinary", colorHex: "#ac785e", info: "The urinary system filters blood, regulates fluid balance, and removes waste in urine."),
        BodySystem(id: "lymphatic", name: "Lymphatic", colorHex: "#8caa7e", info: "Lymphatic structures return tissue fluid to the circulation and support immune function."),
        BodySystem(id: "endocrine", name: "Endocrine", colorHex: "#bc9f9f", info: "Endocrine structures release hormones that regulate body functions."),
        BodySystem(id: "sensory", name: "Sensory organs", colorHex: "#a4c4c9", info: "Specialized sensory structures support sight, hearing, and balance."),
        BodySystem(id: "reproductive", name: "Reproductive", colorHex: "#b99b90", info: "This reference includes male reproductive anatomy."),
        BodySystem(id: "connective", name: "Connective tissue", colorHex: "#aec5b5", info: "Connective tissues support and connect structures throughout the body."),
        BodySystem(id: "integumentary", name: "Body surface", colorHex: "#bda68c", info: "The outer body surface provides an anatomical reference."),
    ]

    static let heart: [BodySystem] = [
        BodySystem(id: "walls", name: "Heart walls", colorHex: "#ad5556", info: "The heart wall surrounds the chambers. Hide this layer to inspect internal structures."),
        BodySystem(id: "chambers", name: "Chamber cavities", colorHex: "#db8790", info: "These solid volumes represent the spaces inside the four chambers, not their muscular walls."),
        BodySystem(id: "valves", name: "Valve leaflets", colorHex: "#e5c6a3", info: "Valve cusps and leaflets help maintain forward blood flow."),
        BodySystem(id: "coronary", name: "Coronary vessels", colorHex: "#c55256", info: "Coronary arteries supply the heart muscle; cardiac veins return blood from it."),
        BodySystem(id: "vessels", name: "Great vessels", colorHex: "#bb657a", info: "Selected great vessels: ascending aorta, aortic arch and pulmonary trunk."),
    ]

    static func find(_ id: String, in list: [BodySystem]) -> BodySystem? {
        list.first { $0.id == id }
    }
}
