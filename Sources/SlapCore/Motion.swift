import Foundation
import simd

struct Motion: Sendable {
    static let gravityTimeConstant = 0.5

    private var gravity: SIMD3<Double>?
    private var shaking = SIMD3<Double>.zero

    mutating func update(_ acceleration: SIMD3<Double>, period: Double) -> (force: Double, jerk: Double) {
        let alpha = exp(-period / Self.gravityTimeConstant)
        let settled = alpha * (gravity ?? acceleration) + (1 - alpha) * acceleration
        let next = acceleration - settled
        defer {
            gravity = settled
            shaking = next
        }
        return (simd_length(next), simd_reduce_add(simd_abs(next - shaking)) / period)
    }
}
