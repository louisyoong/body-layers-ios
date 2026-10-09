import Foundation
import simd

/// Geometry for one selectable whale part (all of its pieces merged), ready to upload.
/// Colors are baked per vertex (linear RGB) so species skin patterns — the orca's
/// black-and-white markings, pale bellies — survive without a custom shader.
struct AnimalPartMesh: Sendable {
    let id: String
    let positions: [Float]
    let normals: [Float]
    let colors: [Float]
    let indices: [UInt32]

    var vertexCount: Int { positions.count / 3 }
}

/// Swift port of the procedural whale from the Whale Atlas web app
/// (`whale-surfaces.js`, `organ-geometry.js` and the body builder in `anatomy3d.js`).
/// Coordinates match the web app's whale frame (head toward −x, ~7.4 units long)
/// and are scaled down at the end to roughly the human atlas's size.
enum WhaleGeometry {
    static let scale: Double = 0.25

    static func build(slug: String) -> [AnimalPartMesh] {
        let c = MeshCollector()
        let sperm = slug == "sperm-whale"
        let orca = slug == "killer-whale"
        let beluga = slug == "beluga-whale"

        // Longitudinal body rings, with a broad head and a tapering tail peduncle.
        let keySections: [V3] = [
            V3(-3.67, 0, 0), V3(-3.54, sperm ? 0.55 : 0.10, sperm ? 0.51 : 0.30),
            V3(-3.15, sperm ? 0.72 : 0.27, sperm ? 0.69 : 0.57), V3(-2.4, 0.67, 0.70),
            V3(-1.5, 0.83, 0.75), V3(-0.5, 0.8, 0.70), V3(0.6, 0.61, 0.52), V3(1.6, 0.38, 0.33),
            V3(2.5, 0.18, 0.17), V3(3.35, 0.075, 0.17), V3(3.56, 0, 0),
        ]
        var sections: [V3] = []
        for j in 0..<(keySections.count - 1) {
            let a = keySections[max(0, j - 1)], b = keySections[j], cc = keySections[j + 1]
            let d = keySections[min(keySections.count - 1, j + 2)]
            for k in 0..<14 {
                let p = catmull(a, b, cc, d, Double(k) / 14)
                sections.append(V3(max(-10, p.x), max(0, p.y), max(0, p.z)))
            }
        }
        sections.append(keySections[keySections.count - 1])

        let skinHex = beluga ? "#dce7e5" : orca ? "#304758" : sperm ? "#657c86" : "#799daa"
        let skinKind = orca ? 2 : beluga ? 3 : 1
        let skinColor = { (p: V3) in bodyColor(at: p, baseHex: skinHex, kind: skinKind) }

        let around = 96
        var vs: [V3] = [], refs: [V3] = [], fs: [Int] = []
        for s in sections {
            let off = headDrop(s.x)
            for i in 0..<around {
                let a = Double(i) / Double(around) * 2 * .pi
                vs.append(V3(s.x, cos(a) * s.y + off, sin(a) * s.z))
                refs.append(V3(s.x, off, 0))
            }
        }
        for j in 0..<(sections.count - 1) {
            for i in 0..<around {
                let a = j * around + i, b = j * around + (i + 1) % around
                fs += [a, a + around, b, b, a + around, b + around]
            }
        }
        c.add("Skin", vs, refs, fs, color: skinColor)

        appendages(c, slug: slug)

        // Eyes and a curved mouth line sit on both sides of the head.
        func surfaceAt(_ x: Double, _ y: Double, _ side: Double, lift: Double = 0.008) -> V3 {
            var i = sections.firstIndex { $0.x >= x } ?? sections.count - 1
            i = max(1, i)
            let a = sections[i - 1], b = sections[i]
            let span = b.x - a.x
            let t = (x - a.x) / (span == 0 ? 1 : span)
            let ry = a.y + (b.y - a.y) * t, rz = a.z + (b.z - a.z) * t
            let yy = y - headDrop(x)
            let k = ry > 0 ? max(0, 1 - yy * yy / (ry * ry)) : 0
            return V3(x, y, side * (rz * k.squareRoot() + lift))
        }
        let jaw = mouthProfile(slug)
        for side in [-1.0, 1.0] {
            let eyeX = jaw[1] - 0.055
            let eyeY = mouthY(eyeX, jaw) + 0.115
            let eye = surfaceAt(eyeX, eyeY, side)
            c.ellipsoid("Skin", eye, V3(0.040, 0.029, 0.015), color: "#15252c")
            c.ellipsoid("Skin", V3(eye.x - 0.008, eye.y + 0.006, eye.z + side * 0.013), V3(0.007, 0.007, 0.003), color: "#c0d9df")

            // The web app paints the mouth seam in its fragment shader; a thin dark
            // tube hugging the surface reads the same at phone scale.
            var line: [V3] = []
            for k in 0...40 {
                let x = jaw[0] + (jaw[1] - jaw[0]) * (0.02 + 0.95 * Double(k) / 40)
                line.append(surfaceAt(x, mouthY(x, jaw), side, lift: 0.004))
            }
            c.tube("Skin", line, radius: { _ in 0.011 }, segments: 80, sides: 8) { p in skinColor(p) * 0.57 }
        }
        let blowX = sperm ? -3.17 : -2.47
        let ring = sections.min { abs($0.x - blowX) < abs($1.x - blowX) } ?? sections[0]
        c.ellipsoid("Skin", V3(blowX, ring.y + 0.002, sperm ? -0.12 : 0), V3(0.074, 0.010, 0.022), color: "#263d46")

        organs(c)
        return c.finish(scale: scale)
    }

    // MARK: - Exterior

    private static func headDrop(_ x: Double) -> Double {
        -0.055 * exp(-pow((x + 3.67) / 0.48, 2))
    }

    private static func smoothstep(_ e0: Double, _ e1: Double, _ x: Double) -> Double {
        let t = min(max((x - e0) / (e1 - e0), 0), 1)
        return t * t * (3 - 2 * t)
    }

    /// Mirrors the skin branch of the web app's fragment shader.
    private static func bodyColor(at p: V3, baseHex: String, kind: Int) -> V3 {
        var coat = rgb(baseHex)
        let mottling = sin(p.x * 3.7 + sin(p.z * 5.2)) * sin(p.y * 6.1 + p.x * 1.3)
        coat *= 1 + 0.012 * mottling
        if kind == 2 {
            let belly = 1 - smoothstep(-0.35, -0.10, p.y)
            let patch = SIMD2<Double>((p.x + 2.63) / 0.27, (p.y - 0.25) / 0.13)
            let eyePatch = (1 - smoothstep(0.80, 1.0, simd_length(patch))) * smoothstep(0.25, 0.45, abs(p.z))
            coat = simd_mix(V3(0.065, 0.095, 0.115), V3(0.88, 0.92, 0.90), V3(repeating: max(belly, eyePatch)))
        } else if kind == 1 {
            coat = simd_mix(coat, V3(0.57, 0.67, 0.70), V3(repeating: 1 - smoothstep(-0.62, -0.25, p.y)))
        }
        return coat
    }

    /// Species-specific closed-mouth proportions: start, corner, height and curvature.
    private static func mouthProfile(_ slug: String) -> [Double] {
        switch slug {
        case "sperm-whale": return [-3.59, -2.13, -0.35, -0.025]
        case "beluga-whale": return [-3.66, -2.61, -0.055, -0.025]
        case "killer-whale": return [-3.67, -2.31, -0.055, -0.025]
        case "gray-whale": return [-3.67, -2.15, -0.055, -0.045]
        default: return [-3.67, -2.12, -0.055, -0.035]
        }
    }

    private static func mouthY(_ x: Double, _ p: [Double]) -> Double {
        let t = min(max((x - p[0]) / (p[1] - p[0]), 0), 1)
        return p[2] + p[3] * sin(.pi * t)
    }

    private static func appendages(_ c: MeshCollector, slug: String) {
        let hump = slug == "humpback-whale", orca = slug == "killer-whale", beluga = slug == "beluga-whale"
        let sperm = slug == "sperm-whale", gray = slug == "gray-whale"
        let coat = beluga ? "#dce7e5" : orca ? "#22333d" : hump ? "#475e68" : "#69838f"
        for s in [-1.0, 1.0] {
            let reach = hump ? 2.25 : beluga ? 1.2 : 1.55
            let flipper: [[Double]] = [
                [-1.65, -0.24, s * 0.36, 0.25, 0.105],
                [-1.53, -0.34, s * 0.64, 0.32, 0.09],
                [-1.34, -0.46, s * reach * 0.65, 0.26, 0.065],
                [-1.02, -0.55, s * reach * 0.88, 0.14, 0.04],
                [-0.78, -0.57, s * reach, 0, 0],
            ]
            c.foil("Flippers", flipper, vertical: false, color: hump ? "#b3c8ca" : coat)
            let fluke: [[Double]] = [
                [3.27, -0.025, 0, 0.28, 0.10],
                [3.35, 0.015, s * 0.32, 0.43, 0.085],
                [3.45, 0.055, s * 0.79, 0.43, 0.058],
                [3.57, 0.09, s * 1.15, 0.27, 0.038],
                [3.70, 0.12, s * 1.48, 0, 0],
            ]
            c.foil("Flukes", fluke, vertical: false, color: coat)
        }
        if beluga || sperm || gray {
            let ridge: [[Double]] = [[0.85, 0.45, 0, 0.44, 0.09], [0.94, 0.55, 0, 0.30, 0.07], [1.03, 0.62, 0, 0.10, 0.025], [1.07, 0.64, 0, 0, 0]]
            c.foil("Dorsal", ridge, vertical: true, color: coat)
            if gray || sperm {
                for i in 0..<6 {
                    let d = Double(i)
                    c.ellipsoid("Dorsal", V3(1.4 + d * 0.23, 0.39 - d * 0.047, 0), V3(0.13 - d * 0.01, 0.055, 0.055), color: "#87aabb")
                }
            }
        } else {
            let fin: [[Double]] = [
                [0.98, 0.47, 0, 0.43, 0.13],
                [1.05, 0.66, 0, 0.34, 0.1],
                [1.18, orca ? 1.17 : 0.85, 0, 0.20, 0.06],
                [1.36, orca ? 1.7 : 1.04, 0, 0.09, 0.025],
                [1.42, orca ? 1.93 : 1.10, 0, 0, 0],
            ]
            c.foil("Dorsal", fin, vertical: true, color: coat)
        }
    }

    // MARK: - Organs

    /// Sculpted educational organ meshes. All coordinates share the whale body frame.
    private static func organs(_ c: MeshCollector) {
        // A tapered ventricular mass, atria, aortic arch and coronary surface vessels.
        c.sculpt("Heart", V3(-1.52, -0.20, 0.04), V3(0.30, 0.40, 0.28), "#b84450") { v, _, _ in
            V3(v.x * (0.78 + 0.27 * v.y) - 0.17 * (1 - v.y), v.y, v.z * (0.90 + 0.17 * v.y))
        }
        c.sculpt("Heart", V3(-1.66, 0.07, 0.02), V3(0.17, 0.15, 0.18), "#9d3543")
        c.sculpt("Heart", V3(-1.36, 0.09, 0.04), V3(0.16, 0.13, 0.16), "#aa3b48")
        c.tube("Heart", [V3(-1.47, 0.02, 0.09), V3(-1.45, 0.28, 0.08), V3(-1.29, 0.37, 0.06), V3(-1.15, 0.29, 0.04), V3(-1.04, 0.16, 0.02)], radius: { _ in 0.054 }, color: "#c95860", segments: 56, sides: 16)
        c.tube("Heart", [V3(-1.64, 0.10, 0.12), V3(-1.72, 0.24, 0.19), V3(-1.80, 0.28, 0.17)], radius: { _ in 0.065 }, color: "#686c9e", segments: 36, sides: 16)
        c.tube("Heart", [V3(-1.45, 0.1, 0.25), V3(-1.48, -0.08, 0.30), V3(-1.59, -0.3, 0.24), V3(-1.70, -0.47, 0.10)], radius: { 0.014 * (1 - 0.55 * $0) }, color: "#812c40", segments: 44, sides: 10)
        c.tube("Heart", [V3(-1.48, -0.05, 0.31), V3(-1.32, -0.14, 0.23), V3(-1.27, -0.28, 0.12)], radius: { 0.011 * (1 - 0.6 * $0) }, color: "#d17a81", segments: 30, sides: 10)
        for i in 0..<3 {
            let d = Double(i)
            c.tube("Heart", [V3(-1.39 + d * 0.07, 0.33, 0.07), V3(-1.40 + d * 0.065, 0.47, 0.055)], radius: { _ in 0.023 }, color: "#c95860", segments: 16, sides: 12)
        }

        // Paired elongated lungs with tapered apices and an indented medial border.
        for side in [-1.0, 1.0] {
            c.sculpt("Lungs", V3(-1.0, 0.30, side * 0.39), V3(0.69, 0.31, 0.235), side == 1 ? "#ce9299" : "#bd7d88") { v, _, _ in
                V3(v.x, v.y * (0.94 - 0.18 * v.x), v.z * (0.90 + 0.12 * v.x) * (1 - 0.16 * exp(-v.x * v.x * 10)))
            }
            c.tube("Lungs", [V3(-1.89, 0.43, 0), V3(-1.57, 0.41, 0), V3(-1.23, 0.35, side * 0.23), V3(-0.77, 0.27, side * 0.36)], radius: { 0.044 * (1 - 0.55 * $0) }, color: "#e6c4bd", segments: 42, sides: 12)
            for i in 0..<3 {
                let d = Double(i)
                c.tube("Lungs", [V3(-1.25 + d * 0.2, 0.36, side * 0.22), V3(-1.05 + d * 0.2, 0.29, side * 0.36), V3(-0.9 + d * 0.2, 0.2, side * 0.43)], radius: { 0.022 * (1 - 0.75 * $0) }, color: "#e0afb0", segments: 24, sides: 10)
            }
            // Subtle surface fissure along each visible lung.
            c.tube("Lungs", [V3(-1.19, 0.54, side * 0.47), V3(-0.99, 0.40, side * 0.60), V3(-0.82, 0.19, side * 0.56)], radius: { _ in 0.008 }, color: "#aa727e", segments: 32, sides: 8)
        }

        // Two cerebral hemispheres, convoluted gyri and a cerebellum.
        for side in [-1.0, 1.0] {
            c.sculpt("Brain", V3(-2.85, 0.30, side * 0.13), V3(0.30, 0.25, 0.145), "#bc8f91") { v, p, t in
                v * (1 + 0.025 * sin(t * 12 + p * 7))
            }
            for row in 0..<10 {
                let r = Double(row)
                let th = 0.20 + r * 0.29
                var pts: [V3] = []
                for k in 0...26 {
                    let a = 0.12 + Double(k) / 26 * 2.8
                    let t = th + 0.075 * sin(a * 9 + r) + 0.025 * sin(a * 17 - r)
                    pts.append(V3(-2.85 + 0.302 * cos(a), 0.30 + 0.255 * sin(a) * cos(t), side * (0.13 + 0.15 * sin(a) * sin(t))))
                }
                c.tube("Brain", pts, radius: { _ in 0.019 }, color: "#ddb1ad", segments: 88, sides: 12)
            }
        }
        c.sculpt("Brain", V3(-2.57, 0.18, 0), V3(0.12, 0.13, 0.16), "#c89d99") { v, p, _ in
            let f = 1 + 0.035 * cos(p * 22)
            return V3(v.x * f, v.y, v.z * f)
        }
        c.tube("Brain", [V3(-2.58, 0.16, 0), V3(-2.47, 0.1, 0), V3(-2.35, 0.08, 0)], radius: { _ in 0.049 }, color: "#c5a097", segments: 24, sides: 12)

        // Flattened asymmetric hepatic lobes with a rounded free edge.
        c.sculpt("Liver", V3(-0.63, -0.24, -0.13), V3(0.44, 0.22, 0.31), "#803f3c") { v, _, _ in
            V3(v.x + 0.12 * v.y, v.y * (0.77 + 0.20 * v.x), v.z * (0.87 - 0.12 * v.x))
        }
        c.sculpt("Liver", V3(-0.47, -0.26, 0.19), V3(0.35, 0.19, 0.26), "#934a43") { v, _, _ in
            V3(v.x, v.y * (0.82 - 0.17 * v.x), v.z)
        }

        // Multi-compartment stomach connected by a curved gastric passage.
        c.sculpt("Stomach", V3(-0.09, -0.12, 0.19), V3(0.22, 0.27, 0.24), "#d7a296") { v, _, _ in
            V3(v.x + 0.12 * v.y, v.y, v.z * (0.9 + 0.1 * v.y))
        }
        c.sculpt("Stomach", V3(0.17, -0.18, 0.16), V3(0.25, 0.24, 0.23), "#d49789") { v, _, _ in
            V3(v.x, v.y - 0.14 * v.x, v.z)
        }
        c.sculpt("Stomach", V3(0.37, -0.18, 0.14), V3(0.13, 0.15, 0.14), "#c58c80")
        c.tube("Stomach", [V3(-0.32, 0.13, 0.10), V3(-0.26, 0.03, 0.16), V3(-0.19, -0.08, 0.2)], radius: { _ in 0.047 }, color: "#dfb5a8", segments: 32, sides: 14)
        c.tube("Stomach", [V3(0.32, -0.18, 0.18), V3(0.46, -0.22, 0.13), V3(0.52, -0.27, 0.10)], radius: { _ in 0.05 }, color: "#c78d80", segments: 26, sides: 12)

        // Reniculate kidneys: clustered lobules on two curved kidney-shaped masses.
        for side in [-1.0, 1.0] {
            let center = V3(0.67, 0.21, side * 0.23)
            c.sculpt("Kidneys", center, V3(0.26, 0.125, 0.135), "#98483f") { v, _, _ in
                V3(v.x, v.y * (0.82 + 0.15 * v.x), v.z - 0.18 * (1 - v.x * v.x))
            }
            for a in 0..<7 {
                for b in 0..<3 {
                    let x = -0.21 + Double(a) * 0.07, theta = 0.35 + Double(b) * 0.95
                    let lobule = V3(center.x + x, center.y + 0.085 * cos(theta), center.z + side * 0.11 * sin(theta))
                    c.sculpt("Kidneys", lobule, V3(0.047, 0.045, 0.048), (a + b) % 2 == 1 ? "#ad6258" : "#a5574f")
                }
            }
            c.tube("Kidneys", [V3(0.67, 0.16, side * 0.20), V3(0.86, 0.06, side * 0.15), V3(1.1, -0.01, side * 0.10)], radius: { _ in 0.014 }, color: "#dab2a0", segments: 30, sides: 9)
        }

        // A continuous serpentine small intestine with rounded returning loops.
        var bowel: [V3] = []
        for i in 0...100 {
            let t = Double(i) / 100
            bowel.append(V3(0.40 + t * 0.98, -0.20 + 0.027 * sin(t * .pi * 12), sin(t * .pi * 10) * (0.23 - 0.07 * t)))
        }
        c.tube("Intestines", bowel, radius: { _ in 0.044 }, color: "#dba693", segments: 260, sides: 12)
        c.tube("Intestines", [V3(0.41, -0.19, -0.24), V3(0.58, -0.31, -0.27), V3(1.30, -0.30, -0.22), V3(1.47, -0.22, 0), V3(1.27, -0.09, 0.27), V3(0.83, -0.07, 0.28)], radius: { 0.061 * (1 - 0.18 * $0) }, color: "#bf897d", segments: 92, sides: 14)
    }

    // MARK: - Helpers

    fileprivate static func catmull(_ a: V3, _ b: V3, _ c: V3, _ d: V3, _ t: Double) -> V3 {
        let t2 = t * t, t3 = t2 * t
        return 0.5 * (2 * b + (c - a) * t + (2 * a - 5 * b + 4 * c - d) * t2 + (3 * b - a - 3 * c + d) * t3)
    }

    fileprivate static func rgb(_ hex: String) -> V3 {
        let s = hex.replacingOccurrences(of: "#", with: "")
        let n = UInt32(s, radix: 16) ?? 0
        return V3(Double((n >> 16) & 0xff), Double((n >> 8) & 0xff), Double(n & 0xff)) / 255
    }
}

fileprivate typealias V3 = SIMD3<Double>

/// Collects primitive pieces per part name and merges each part into one mesh.
/// Every triangle is rewound to face away from its piece's local "inside" reference
/// (a sphere center, a tube's spine, the body's axis), so lighting stays correct
/// regardless of the winding the original JavaScript happened to use.
fileprivate final class MeshCollector {
    private struct Accumulator {
        var positions: [Float] = []
        var normals: [Float] = []
        var colors: [Float] = []
        var indices: [UInt32] = []
    }

    private var order: [String] = []
    private var parts: [String: Accumulator] = [:]

    func add(_ name: String, _ vertices: [V3], _ refs: [V3], _ faces: [Int], color: (V3) -> V3) {
        var tris = faces
        var normals = [V3](repeating: .zero, count: vertices.count)
        for f in stride(from: 0, to: tris.count, by: 3) {
            let a = vertices[tris[f]], b = vertices[tris[f + 1]], c = vertices[tris[f + 2]]
            var n = simd_cross(b - a, c - a)
            let inside = (refs[tris[f]] + refs[tris[f + 1]] + refs[tris[f + 2]]) / 3
            if simd_dot(n, (a + b + c) / 3 - inside) < 0 {
                tris.swapAt(f + 1, f + 2)
                n = -n
            }
            for i in tris[f..<(f + 3)] { normals[i] += n }
        }

        // Weld normals along parameter seams for continuous, smooth surfaces.
        var welded: [SIMD3<Int64>: V3] = [:]
        let keys = vertices.map { SIMD3<Int64>(($0 * 1e5).rounded(.toNearestOrAwayFromZero)) }
        for (i, key) in keys.enumerated() { welded[key, default: .zero] += normals[i] }

        if parts[name] == nil {
            order.append(name)
            parts[name] = Accumulator()
        }
        var acc = parts[name]!
        let base = UInt32(acc.positions.count / 3)
        acc.positions.reserveCapacity(acc.positions.count + vertices.count * 3)
        for (i, v) in vertices.enumerated() {
            let n = welded[keys[i]] ?? .zero
            let len = simd_length(n)
            let unit = len > 1e-12 ? n / len : V3(0, 1, 0)
            // Vertex colors are interpolated in linear space; convert from sRGB hex.
            let col = simd_clamp(color(v), V3(repeating: 0), V3(repeating: 1))
            acc.positions += [Float(v.x), Float(v.y), Float(v.z)]
            acc.normals += [Float(unit.x), Float(unit.y), Float(unit.z)]
            acc.colors += [Float(pow(col.x, 2.2)), Float(pow(col.y, 2.2)), Float(pow(col.z, 2.2))]
        }
        acc.indices += tris.map { base + UInt32($0) }
        parts[name] = acc
    }

    func finish(scale: Double) -> [AnimalPartMesh] {
        let s = Float(scale)
        return order.compactMap { name in
            guard let acc = parts[name] else { return nil }
            return AnimalPartMesh(id: name, positions: acc.positions.map { $0 * s }, normals: acc.normals, colors: acc.colors, indices: acc.indices)
        }
    }

    // MARK: Primitives

    func ellipsoid(_ name: String, _ c: V3, _ r: V3, color: String) {
        let n = 40, m = 28
        var vs: [V3] = [], fs: [Int] = []
        for j in 0...m {
            let p = Double.pi * Double(j) / Double(m)
            for i in 0...n {
                let t = 2 * Double.pi * Double(i) / Double(n)
                vs.append(c + r * V3(sin(p) * cos(t), cos(p), sin(p) * sin(t)))
            }
        }
        for j in 0..<m {
            for i in 0..<n {
                let a = j * (n + 1) + i, b = a + n + 1
                fs += [a, b, a + 1, b, b + 1, a + 1]
            }
        }
        let rgb = WhaleGeometry.rgb(color)
        add(name, vs, Array(repeating: c, count: vs.count), fs) { _ in rgb }
    }

    func sculpt(_ name: String, _ center: V3, _ radii: V3, _ color: String, deform: ((V3, Double, Double) -> V3)? = nil) {
        let small = radii.max() < 0.07
        let cols = small ? 16 : 52, rows = small ? 12 : 36
        var vs: [V3] = [], fs: [Int] = []
        for j in 0...rows {
            let p = Double.pi * Double(j) / Double(rows)
            for i in 0...cols {
                let t = 2 * Double.pi * Double(i) / Double(cols)
                var v = V3(sin(p) * cos(t), cos(p), sin(p) * sin(t))
                if let deform { v = deform(v, p, t) }
                vs.append(center + v * radii)
            }
        }
        for j in 0..<rows {
            for i in 0..<cols {
                let a = j * (cols + 1) + i, b = a + cols + 1
                fs += [a, b, a + 1, b, b + 1, a + 1]
            }
        }
        let rgb = WhaleGeometry.rgb(color)
        add(name, vs, Array(repeating: center, count: vs.count), fs) { _ in rgb }
    }

    func tube(_ name: String, _ points: [V3], radius: (Double) -> Double, color: String, segments: Int = 100, sides: Int = 12) {
        let rgb = WhaleGeometry.rgb(color)
        tube(name, points, radius: radius, segments: segments, sides: sides) { _ in rgb }
    }

    func tube(_ name: String, _ points: [V3], radius: (Double) -> Double, segments: Int, sides: Int, color: (V3) -> V3) {
        let count = points.count
        func at(_ t: Double) -> V3 {
            let x = max(0, min(Double(count - 1) - 1e-7, t * Double(count - 1)))
            let i = Int(x.rounded(.down)), f = x - Double(i)
            return WhaleGeometry.catmull(points[max(0, i - 1)], points[i], points[min(count - 1, i + 1)], points[min(count - 1, i + 2)], f)
        }
        var vs: [V3] = [], refs: [V3] = [], fs: [Int] = []
        for j in 0...segments {
            let t = Double(j) / Double(segments)
            let p = at(t)
            var u = at(min(1, t + 0.001)) - at(max(0, t - 0.001))
            let ul = simd_length(u)
            u = ul > 0 ? u / ul : V3(1, 0, 0)
            let ref = abs(u.y) < 0.9 ? V3(0, 1, 0) : V3(1, 0, 0)
            var v = simd_cross(u, ref)
            let vl = simd_length(v)
            v = vl > 0 ? v / vl : V3(0, 0, 1)
            let w = simd_cross(u, v)
            let r = radius(t)
            for i in 0...sides {
                let th = 2 * Double.pi * Double(i) / Double(sides)
                vs.append(p + r * (v * cos(th) + w * sin(th)))
                refs.append(p)
            }
        }
        for j in 0..<segments {
            for i in 0..<sides {
                let a = j * (sides + 1) + i, b = a + sides + 1
                fs += [a, a + 1, b, b, a + 1, b + 1]
            }
        }
        add(name, vs, refs, fs, color: color)
    }

    /// Rounded hydrofoil surfaces: continuous spanwise curves and elliptical sections.
    /// Each control is [x, y, z, chord radius, thickness radius].
    func foil(_ name: String, _ controls: [[Double]], vertical: Bool, color: String) {
        let around = 40, steps = 72
        var vs: [V3] = [], refs: [V3] = [], fs: [Int] = []
        for j in 0...steps {
            let u = Double(j) / Double(steps) * Double(controls.count - 1)
            let i = min(controls.count - 2, Int(u.rounded(.down)))
            let t = u - Double(i)
            let a = controls[max(0, i - 1)], b = controls[i], c = controls[i + 1], d = controls[min(controls.count - 1, i + 2)]
            var p = [Double](repeating: 0, count: 5)
            for k in 0..<5 {
                p[k] = 0.5 * (2 * b[k] + (-a[k] + c[k]) * t + (2 * a[k] - 5 * b[k] + 4 * c[k] - d[k]) * t * t + (-a[k] + 3 * b[k] - 3 * c[k] + d[k]) * t * t * t)
            }
            let chord = max(0, p[3]), thick = max(0, p[4])
            let spine = V3(p[0], p[1], p[2])
            for k in 0..<around {
                let ang = Double(k) / Double(around) * 2 * .pi
                var v = spine
                v.x += cos(ang) * chord
                if vertical { v.z += sin(ang) * thick } else { v.y += sin(ang) * thick }
                vs.append(v)
                refs.append(spine)
            }
        }
        for j in 0..<steps {
            for k in 0..<around {
                let a = j * around + k, b = j * around + (k + 1) % around
                fs += [a, b, a + around, b, b + around, a + around]
            }
        }
        let rgb = WhaleGeometry.rgb(color)
        add(name, vs, refs, fs) { _ in rgb }
    }
}
