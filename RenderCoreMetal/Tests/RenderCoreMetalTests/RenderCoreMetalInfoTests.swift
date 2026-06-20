import XCTest
@testable import RenderCoreMetal

final class RenderCoreMetalInfoTests: XCTestCase {
    func testPhase0PlaceholderExists() {
        XCTAssertEqual(RenderCoreMetalInfo.moduleName, "RenderCoreMetal")
        XCTAssertEqual(RenderCoreMetalInfo.phase0Status, "placeholder")
        XCTAssertEqual(RenderCoreMetalInfo.phase6Status, "metal-debug-terrain-renderer")
        XCTAssertEqual(RenderCoreMetalInfo.phase7Status, "runtime-camera-debug-controls")
        XCTAssertEqual(RenderCoreMetalInfo.phase8Status, "terrain-debug-picking-refinement")
        XCTAssertEqual(RenderCoreMetalInfo.phase9Status, "terrain-query-player-probe-debug-marker")
        XCTAssertEqual(RenderCoreMetalInfo.phase9_5Status, "debug-runtime-usability-fix")
        XCTAssertEqual(RenderCoreMetalInfo.phase9_6Status, "playable-runtime-slice-debug-separation")
        XCTAssertEqual(RenderCoreMetalInfo.phaseR1Status, "runtime-slice-recovery")
    }
}
