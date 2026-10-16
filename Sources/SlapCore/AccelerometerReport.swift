public enum AccelerometerReport {
    static let axisOffsets = [6, 10, 14]
    static let countsPerG = 65536.0

    public static func decode(_ bytes: UnsafeRawBufferPointer) -> SIMD3<Double>? {
        guard axisOffsets.allSatisfy({ $0 + MemoryLayout<Int32>.size <= bytes.count }) else { return nil }
        return SIMD3(axisOffsets.map {
            Double(Int32(littleEndian: bytes.loadUnaligned(fromByteOffset: $0, as: Int32.self))) / countsPerG
        })
    }
}
