import XCTest
@testable import EngineCore

final class TerrainWalkabilityTests: XCTestCase {
    func testLowSlopeSoilIsWalkable() {
        let walkability = TerrainWalkability.evaluate(
            surface: makeSurface(material: .soil),
            slopeDegrees: 4,
            isInsideKnownTerrain: true
        )

        XCTAssertTrue(walkability.isWalkable)
        XCTAssertEqual(walkability.reason, .walkable)
    }

    func testSteepSlopeIsTooSteep() {
        let walkability = TerrainWalkability.evaluate(
            surface: makeSurface(material: .grass),
            slopeDegrees: 48,
            isInsideKnownTerrain: true
        )

        XCTAssertFalse(walkability.isWalkable)
        XCTAssertEqual(walkability.reason, .tooSteep)
    }

    func testShallowWaterUsesConfig() {
        let defaultWater = TerrainWalkability.evaluate(
            surface: makeSurface(material: .shallowWater),
            slopeDegrees: 2,
            isInsideKnownTerrain: true
        )
        let allowedWater = TerrainWalkability.evaluate(
            surface: makeSurface(material: .shallowWater),
            slopeDegrees: 2,
            isInsideKnownTerrain: true,
            config: TerrainWalkabilityConfig(shallowWaterIsWalkable: true)
        )

        XCTAssertFalse(defaultWater.isWalkable)
        XCTAssertEqual(defaultWater.reason, .water)
        XCTAssertTrue(allowedWater.isWalkable)
    }

    func testMudUsesConfig() {
        let defaultMud = TerrainWalkability.evaluate(
            surface: makeSurface(material: .mud),
            slopeDegrees: 2,
            isInsideKnownTerrain: true
        )
        let blockedMud = TerrainWalkability.evaluate(
            surface: makeSurface(material: .mud),
            slopeDegrees: 2,
            isInsideKnownTerrain: true,
            config: TerrainWalkabilityConfig(mudIsWalkable: false)
        )

        XCTAssertTrue(defaultMud.isWalkable)
        XCTAssertEqual(defaultMud.reason, .mud)
        XCTAssertFalse(blockedMud.isWalkable)
        XCTAssertEqual(blockedMud.reason, .mud)
    }

    func testOutsideTerrainIsNotWalkable() {
        let walkability = TerrainWalkability.evaluate(
            surface: nil,
            slopeDegrees: 0,
            isInsideKnownTerrain: false
        )

        XCTAssertFalse(walkability.isWalkable)
        XCTAssertEqual(walkability.reason, .outsideKnownTerrain)
    }

    func testSlopeClassificationIsStable() {
        XCTAssertEqual(TerrainSlopeClassification.classify(slopeDegrees: 2), .flat)
        XCTAssertEqual(TerrainSlopeClassification.classify(slopeDegrees: 10), .gentle)
        XCTAssertEqual(TerrainSlopeClassification.classify(slopeDegrees: 24), .moderate)
        XCTAssertEqual(TerrainSlopeClassification.classify(slopeDegrees: 42), .steep)
        XCTAssertEqual(TerrainSlopeClassification.classify(slopeDegrees: 80), .extreme)
        XCTAssertEqual(TerrainSlopeClassification.classify(slopeDegrees: 0, isInsideKnownTerrain: false), .unknown)
    }

    private func makeSurface(material: TerrainSurfaceMaterial) -> TerrainQuerySurfaceResult {
        let tags: (PhysicalSurfaceTag, AudioSurfaceTag)
        switch material {
        case .rock:
            tags = (.hardRock, .stone)
        case .soil:
            tags = (.looseSoil, .dirt)
        case .grass:
            tags = (.softGrass, .grass)
        case .sand:
            tags = (.looseSand, .sand)
        case .gravel:
            tags = (.looseGravel, .gravel)
        case .mud:
            tags = (.stickyMud, .mud)
        case .snow:
            tags = (.compactSnow, .snow)
        case .shallowWater:
            tags = (.shallowWater, .water)
        }

        return TerrainQuerySurfaceResult(
            material: material,
            physicalTag: tags.0,
            audioTag: tags.1,
            slope01: 0,
            moisture01: 0.5,
            heightMeters: 0
        )
    }
}

