import Foundation
@testable import SlapCore

struct SplitMix64: RandomNumberGenerator {
    var state: UInt64

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

struct Impulse {
    var start: Double
    var amplitude: Double
    var frequency: Double
    var decay: Double
    var axis = 2

    func value(at time: Double) -> Double {
        let elapsed = time - start
        guard elapsed >= 0, elapsed < decay * 12 else { return 0 }
        return amplitude * exp(-elapsed / decay) * sin(2 * .pi * frequency * elapsed)
    }
}

func typing(from start: Double, until end: Double) -> [Impulse] {
    stride(from: start, to: end, by: 0.11).enumerated().map { index, time in
        index.isMultiple(of: 2)
            ? Impulse(start: time, amplitude: 0.12, frequency: 18, decay: 0.03, axis: index % 3)
            : Impulse(start: time, amplitude: 0.03, frequency: 300, decay: 0.004)
    }
}

func slaps(
    _ sensitivity: Sensitivity,
    rate: Double = 805,
    seconds: Double,
    impulses: [Impulse] = [],
    resting gravity: SIMD3<Double> = [0, 0, -1]
) -> [(time: Double, slap: Slap)] {
    var detector = SlapDetector(sensitivity: sensitivity)
    var random = SplitMix64(state: 42)
    func noise() -> Double {
        let u1 = max(Double.random(in: 0..<1, using: &random), 1e-12)
        let u2 = Double.random(in: 0..<1, using: &random)
        return 0.003 * (-2 * log(u1)).squareRoot() * cos(2 * .pi * u2)
    }

    return (0..<Int(seconds * rate)).compactMap { sample in
        let time = Double(sample) / rate
        var acceleration = gravity
        for impulse in impulses { acceleration[impulse.axis] += impulse.value(at: time) }
        acceleration += SIMD3(noise(), noise(), noise())
        return detector.process(acceleration, period: 1 / rate).map { (time, $0) }
    }
}
