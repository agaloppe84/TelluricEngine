//
//  TelluricRuntimeAppTests.swift
//  TelluricRuntimeAppTests
//
//  Created by Work on 19/06/2026.
//

import EngineCore
import Testing
@testable import TelluricRuntimeApp

@MainActor
struct TelluricRuntimeAppTests {

    @Test func initialRebuildProducesNonEmptySnapshot() {
        let model = TelluricDebugRuntimeModel()

        #expect(model.snapshot != nil)
        #expect(model.totalRecords > 0)
        #expect(model.activeRecords == 1)
        #expect(model.gridRows.isEmpty == false)
    }

    @Test func moveEastChangesCenterChunk() {
        let model = TelluricDebugRuntimeModel()

        model.moveEast()

        #expect(model.centerLabel == "(1, 0)")
        #expect(model.snapshot != nil)
    }

    @Test func resetReturnsToOrigin() {
        let model = TelluricDebugRuntimeModel()

        model.moveNorth()
        model.moveEast()
        model.reset()

        #expect(model.centerLabel == "(0, 0)")
        #expect(model.activeRecords == 1)
    }

    @Test func repeatedRebuildIsDeterministic() {
        let model = TelluricDebugRuntimeModel()
        let firstHash = model.snapshot?.stableHash

        model.rebuild()
        let secondHash = model.snapshot?.stableHash

        #expect(firstHash != nil)
        #expect(firstHash == secondHash)
    }

    @Test func statsMatchSnapshot() {
        let model = TelluricDebugRuntimeModel()
        let stats = model.snapshot?.stats

        #expect(model.totalRecords == stats?.totalRecords)
        #expect(model.meshedRecords == stats?.meshPayloadRecords)
        #expect(model.residentRecords == stats?.residentRecords)
        #expect(model.activeRecords == stats?.activeRecords)
    }

}
