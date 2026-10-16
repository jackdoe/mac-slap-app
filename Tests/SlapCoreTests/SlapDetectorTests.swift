import Testing
@testable import SlapCore

@Suite("SlapDetector")
struct SlapDetectorTests {
    @Test("Rest is silent at every sensitivity", arguments: Sensitivity.allCases)
    func restIsSilent(_ sensitivity: Sensitivity) {
        #expect(slaps(sensitivity, seconds: 5).isEmpty)
    }

    @Test("Rest is silent in any orientation", arguments: [SIMD3<Double>(0, -0.7, -0.7), [1, 0, 0], [0, 0.6, 0.8]])
    func anyOrientationIsSilent(_ gravity: SIMD3<Double>) {
        #expect(slaps(.highest, seconds: 3, resting: gravity).isEmpty)
    }

    @Test("Hard typing is rejected at every sensitivity", arguments: Sensitivity.allCases)
    func typingIsRejected(_ sensitivity: Sensitivity) {
        #expect(slaps(sensitivity, seconds: 6.5, impulses: typing(from: 1, until: 6)).isEmpty)
    }

    @Test("A medium slap is detected once, promptly")
    func mediumSlap() throws {
        let hits = slaps(.medium, seconds: 2, impulses: [Impulse(start: 1, amplitude: 0.7, frequency: 150, decay: 0.01)])
        #expect(hits.count == 1)
        let time = try #require(hits.first?.time)
        #expect((1.0..<1.1).contains(time))
    }

    @Test("A hard slap reads as hard and loud")
    func hardSlap() throws {
        let hits = slaps(.lowest, seconds: 2, impulses: [Impulse(start: 1, amplitude: 4, frequency: 180, decay: 0.012)])
        #expect(hits.count == 1)
        let slap = try #require(hits.first?.slap)
        #expect(slap.force > 2.2)
        #expect(slap.intensity > 0.9)
    }

    @Test("Harder slaps are louder")
    func intensityRisesWithForce() throws {
        let intensities = try [0.5, 0.9, 1.4, 2.5].map { amplitude in
            let hits = slaps(.high, seconds: 2, impulses: [Impulse(start: 1, amplitude: amplitude, frequency: 160, decay: 0.01)])
            return try #require(hits.first?.slap.intensity)
        }
        #expect(zip(intensities, intensities.dropFirst()).allSatisfy { $0 < $1 })
    }

    @Test("Chassis ringing after one slap is one slap", arguments: Sensitivity.allCases)
    func ringingIsOneSlap(_ sensitivity: Sensitivity) {
        let ringing = Impulse(start: 1, amplitude: 2, frequency: 120, decay: 0.06)
        #expect(slaps(sensitivity, seconds: 3, impulses: [ringing]).count <= 1)
    }

    @Test("A slap during typing is detected")
    func slapDuringTyping() {
        let impulses = typing(from: 0.5, until: 4) + [Impulse(start: 2.03, amplitude: 1.2, frequency: 150, decay: 0.01)]
        #expect(slaps(.medium, seconds: 4.5, impulses: impulses).count == 1)
    }

    @Test("Detection works when the sensor idles at 100 Hz")
    func lowRate() {
        let slap = Impulse(start: 1, amplitude: 1.5, frequency: 30, decay: 0.03)
        #expect(slaps(.medium, rate: 100, seconds: 2, impulses: [slap]).count == 1)
    }

    @Test("Refractory time is measured in seconds, not samples")
    func refractoryIsInSeconds() {
        let pair = [
            Impulse(start: 1.0, amplitude: 1.5, frequency: 30, decay: 0.02),
            Impulse(start: 1.4, amplitude: 1.5, frequency: 30, decay: 0.02),
        ]
        #expect(slaps(.medium, rate: 100, seconds: 2.5, impulses: pair).count == 2)
    }

    @Test("Intensity spans silence to full across the force range")
    func intensityEndpoints() {
        #expect(Slap(force: Slap.forceRange.lowerBound).intensity == 0)
        #expect(Slap(force: Slap.forceRange.upperBound).intensity == 1)
        #expect(Slap(force: 0).intensity == 0)
        #expect(Slap(force: 10).intensity == 1)
    }
}
