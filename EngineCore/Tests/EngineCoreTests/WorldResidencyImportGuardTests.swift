import Foundation
import XCTest

final class WorldResidencyImportGuardTests: XCTestCase {
    func testEngineCoreKeepsResidencyLayerPlatformFree() throws {
        let packageRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let sourcesRoot = packageRoot.appendingPathComponent("Sources/EngineCore")
        let forbiddenImports = [
            "import Metal",
            "import MetalKit",
            "import SwiftUI",
            "import AppKit",
            "import UIKit",
            "import RealityKit",
            "import SceneKit",
            "import SpriteKit",
            "import GameController",
            "import GameplayKit",
            "import AVFoundation",
            "import simd"
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

