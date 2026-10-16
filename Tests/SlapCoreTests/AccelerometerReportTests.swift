import Testing
import SlapCore

@Suite("AccelerometerReport")
struct AccelerometerReportTests {
    let capturedAtRest: [UInt8] = [
        0x95, 0x61, 0x00, 0x00, 0x00, 0x00, 0xab, 0xfe, 0xff, 0xff, 0x95, 0x02,
        0x00, 0x00, 0x17, 0x01, 0xff, 0xff, 0x80, 0x5d, 0x22, 0x00,
    ]

    @Test("A report captured at rest decodes to one g, mostly on -Z")
    func decodesRest() throws {
        let acceleration = try #require(capturedAtRest.withUnsafeBytes(AccelerometerReport.decode))
        #expect(acceleration == SIMD3<Double>(-341, 661, -65257) / 65536)
        #expect(abs((acceleration * acceleration).sum().squareRoot() - 1) < 0.01)
    }

    @Test("Short reports are rejected")
    func rejectsShort() {
        #expect(capturedAtRest.prefix(17).withUnsafeBytes(AccelerometerReport.decode) == nil)
    }
}
