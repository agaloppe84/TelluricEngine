import XCTest
@testable import RenderCoreMetal

final class RenderCoreMetalInfoTests: XCTestCase {
    func testPhase0PlaceholderExists() {
        XCTAssertEqual(RenderCoreMetalInfo.moduleName, "RenderCoreMetal")
        XCTAssertEqual(RenderCoreMetalInfo.phase0Status, "placeholder")
    }
}

