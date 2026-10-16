import Testing
import SlapCore

@Suite("Streak")
struct StreakTests {
    let start = ContinuousClock.now

    @Test("Hits within the gap count up one by one")
    func countsConsecutiveHits() {
        var streak = Streak()
        for second in 0..<9 {
            streak.hit(at: start + .seconds(second))
            #expect(streak.count == second + 1)
        }
    }

    @Test("A pause longer than the gap starts over")
    func pauseResets() {
        var streak = Streak()
        streak.hit(at: start)
        streak.hit(at: start + .seconds(1))
        streak.hit(at: start + .seconds(1) + Streak.gap + .milliseconds(1))
        #expect(streak.count == 1)
    }
}
