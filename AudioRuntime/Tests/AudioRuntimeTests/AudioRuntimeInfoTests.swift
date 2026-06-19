import XCTest
@testable import AudioRuntime

final class AudioRuntimeInfoTests: XCTestCase {
    func testPhase0PlaceholderExists() {
        XCTAssertEqual(AudioRuntimeInfo.moduleName, "AudioRuntime")
        XCTAssertEqual(AudioRuntimeInfo.phase0Status, "placeholder")
    }
}

