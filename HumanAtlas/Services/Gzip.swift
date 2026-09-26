import Foundation
import Compression

enum GzipError: Error {
    case notGzip
    case truncated
    case decodeFailed
}

enum Gzip {
    /// Decompresses a standard gzip (RFC 1952) byte buffer using Apple's
    /// Compression framework, which implements raw DEFLATE (RFC 1951).
    static func decompress(_ data: Data) throws -> Data {
        guard data.count > 18, data[0] == 0x1f, data[1] == 0x8b, data[2] == 0x08 else {
            throw GzipError.notGzip
        }

        let flags = data[3]
        var offset = 10

        if flags & 0x04 != 0 { // FEXTRA
            guard offset + 2 <= data.count else { throw GzipError.truncated }
            let xlen = Int(data[offset]) | (Int(data[offset + 1]) << 8)
            offset += 2 + xlen
        }
        if flags & 0x08 != 0 { // FNAME
            while offset < data.count, data[offset] != 0 { offset += 1 }
            offset += 1
        }
        if flags & 0x10 != 0 { // FCOMMENT
            while offset < data.count, data[offset] != 0 { offset += 1 }
            offset += 1
        }
        if flags & 0x02 != 0 { // FHCRC
            offset += 2
        }
        guard offset < data.count - 8 else { throw GzipError.truncated }

        let trailerBytes = [UInt8](data.suffix(4))
        let isize = UInt32(trailerBytes[0])
            | (UInt32(trailerBytes[1]) << 8)
            | (UInt32(trailerBytes[2]) << 16)
            | (UInt32(trailerBytes[3]) << 24)
        let expectedSize = Int(isize)

        let deflateData = data.subdata(in: offset..<(data.count - 8))

        var destBuffer = [UInt8](repeating: 0, count: max(expectedSize, 1))
        let destCapacity = destBuffer.count
        let decodedCount = destBuffer.withUnsafeMutableBytes { destPtr -> Int in
            deflateData.withUnsafeBytes { srcPtr -> Int in
                compression_decode_buffer(
                    destPtr.bindMemory(to: UInt8.self).baseAddress!,
                    destCapacity,
                    srcPtr.bindMemory(to: UInt8.self).baseAddress!,
                    deflateData.count,
                    nil,
                    COMPRESSION_ZLIB
                )
            }
        }
        guard decodedCount > 0 else { throw GzipError.decodeFailed }
        return Data(bytes: destBuffer, count: decodedCount)
    }
}
