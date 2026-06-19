import Foundation
import XCTest
@testable import EngineCore

final class DeterminismProbeTests: XCTestCase {
    func testSameSeedProducesSameProbeResult() {
        let seed = WorldSeed(42)
        let chunk = ChunkCoord(x: -3, y: 1, z: 9)

        let first = DeterminismProbe.sample(worldSeed: seed, chunkCoord: chunk)
        let second = DeterminismProbe.sample(worldSeed: seed, chunkCoord: chunk)

        XCTAssertEqual(first, second)
        XCTAssertEqual(first.outputHash, second.outputHash)
    }

    func testDifferentSeedsProduceDifferentProbeResults() {
        let chunk = ChunkCoord(x: -3, y: 1, z: 9)

        let first = DeterminismProbe.sample(worldSeed: WorldSeed(42), chunkCoord: chunk)
        let second = DeterminismProbe.sample(worldSeed: WorldSeed(43), chunkCoord: chunk)

        XCTAssertNotEqual(first.sampleValue, second.sampleValue)
        XCTAssertNotEqual(first.outputHash, second.outputHash)
    }

    func testChunkCoordIsHashableAndHasStableHash() {
        let chunk = ChunkCoord(x: -12, y: 4, z: 99)
        let sameChunk = ChunkCoord(x: -12, y: 4, z: 99)
        let otherChunk = ChunkCoord(x: -12, y: 5, z: 99)
        let set: Set<ChunkCoord> = [chunk]

        XCTAssertTrue(set.contains(sameChunk))
        XCTAssertEqual(chunk.stableHash, sameChunk.stableHash)
        XCTAssertNotEqual(chunk.stableHash, otherChunk.stableHash)
    }

    func testEngineCoreDoesNotImportPlatformOrRuntimeFrameworks() throws {
        let packageRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let sourcesRoot = packageRoot.appendingPathComponent("Sources/EngineCore")
        let forbiddenImports = [
            "import SwiftUI",
            "import AppKit",
            "import UIKit",
            "import Metal",
            "import MetalKit",
            "import RealityKit",
            "import SceneKit",
            "import SpriteKit",
            "import GameController",
            "import GameplayKit",
            "import simd",
            "import AVFoundation"
        ]

        guard let enumerator = FileManager.default.enumerator(
            at: sourcesRoot,
            includingPropertiesForKeys: nil
        ) else {
            XCTFail("Could not enumerate EngineCore sources")
            return
        }

        let sourceFiles = enumerator
            .compactMap { $0 as? URL }
            .filter { $0.pathExtension == "swift" }
            .sorted { $0.path < $1.path }

        XCTAssertFalse(sourceFiles.isEmpty)

        for file in sourceFiles {
            let contents = try String(contentsOf: file, encoding: .utf8)
            for forbiddenImport in forbiddenImports {
                XCTAssertFalse(
                    contents.contains(forbiddenImport),
                    "\(file.path) contains forbidden EngineCore import: \(forbiddenImport)"
                )
            }
        }
    }
}
