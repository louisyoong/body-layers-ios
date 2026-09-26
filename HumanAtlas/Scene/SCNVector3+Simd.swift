import SceneKit

extension SCNVector3 {
    init(_ v: SIMD3<Float>) {
        self.init(v.x, v.y, v.z)
    }

    var simd: SIMD3<Float> {
        SIMD3<Float>(x, y, z)
    }
}
