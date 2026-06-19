import Combine
import EngineCore
import SwiftUI

struct TelluricDebugChunkCell: Identifiable, Hashable {
    let coord: WorldChunkCoord
    let lifecycleState: ChunkLifecycleState
    let payloadState: CachedChunkPayloadState?
    let priorityRank: Int?
    let isCached: Bool
    let isCenter: Bool

    var id: String {
        "\(coord.x):\(coord.z)"
    }

    var stateLabel: String {
        switch lifecycleState {
        case .active:
            return "active"
        case .resident:
            return "resident"
        case .meshed, .meshRequested:
            return "meshed"
        case .sampled, .sampleRequested:
            return "sampled"
        case .evictionCandidate:
            return "evict"
        case .unloaded:
            return "none"
        }
    }

    var payloadLabel: String {
        guard let payloadState else {
            return isCached ? "cached" : "absent"
        }

        switch payloadState {
        case .empty:
            return "empty"
        case .sampled:
            return "sample"
        case .meshed:
            return "mesh"
        case .resident:
            return "resident"
        case .active:
            return "active"
        case .evictionCandidate:
            return "evict"
        }
    }
}

struct TelluricDebugChunkGridRow: Identifiable, Hashable {
    let z: Int32
    let cells: [TelluricDebugChunkCell]

    var id: Int32 {
        z
    }
}

@MainActor
final class TelluricDebugRuntimeModel: ObservableObject {
    @Published private(set) var seed: UInt64
    @Published private(set) var centerChunkCoord: WorldChunkCoord
    @Published private(set) var lastPlan: WorldResidencyPlan?
    @Published private(set) var lastBuildResult: ChunkBuildResult?
    @Published private(set) var snapshot: ResidentWorldSnapshot?
    @Published private(set) var errorMessage: String?

    let generatorVersion: TerrainGeneratorVersion
    let layout: TerrainChunkLayout
    let config: WorldResidencyConfig

    private let planner: WorldResidencyPlanner
    private let pipeline: ChunkBuildPipeline
    private var cache: InMemoryWorldCache

    init(
        seed: UInt64 = 20_260_619,
        generatorVersion: TerrainGeneratorVersion = .phase1,
        layout: TerrainChunkLayout = TerrainChunkLayout(samplesPerAxis: 9),
        config: WorldResidencyConfig = WorldResidencyConfig(
            activeRadiusChunks: 0,
            residentRadiusChunks: 1,
            meshRadiusChunks: 2,
            sampleRadiusChunks: 3,
            evictionRadiusChunks: 4
        ),
        centerChunkCoord: WorldChunkCoord = WorldChunkCoord(x: 0, z: 0)
    ) {
        self.seed = seed
        self.generatorVersion = generatorVersion
        self.layout = layout
        self.config = config
        self.centerChunkCoord = centerChunkCoord
        self.planner = WorldResidencyPlanner()
        self.pipeline = ChunkBuildPipeline()
        self.cache = InMemoryWorldCache()

        rebuild()
    }

    var centerLabel: String {
        "(\(centerChunkCoord.x), \(centerChunkCoord.z))"
    }

    var generatorVersionLabel: String {
        "\(generatorVersion.major).\(generatorVersion.minor).\(generatorVersion.patch)"
    }

    var planHashLabel: String {
        Self.hashLabel(lastPlan?.stableHash)
    }

    var snapshotHashLabel: String {
        Self.hashLabel(snapshot?.stableHash)
    }

    var cacheHashLabel: String {
        Self.hashLabel(snapshot?.cacheHash)
    }

    var totalRecords: Int {
        snapshot?.stats.totalRecords ?? 0
    }

    var sampleOnlyRecords: Int {
        snapshot?.records.filter { $0.samplePayload != nil && $0.meshPayload == nil }.count ?? 0
    }

    var meshedRecords: Int {
        snapshot?.stats.meshPayloadRecords ?? 0
    }

    var residentRecords: Int {
        snapshot?.stats.residentRecords ?? 0
    }

    var activeRecords: Int {
        snapshot?.stats.activeRecords ?? 0
    }

    var gridRows: [TelluricDebugChunkGridRow] {
        let radius = config.evictionRadiusChunks
        let targetsByCoord = Dictionary(uniqueKeysWithValues: (lastPlan?.targets ?? []).map { ($0.chunkCoord, $0) })
        let recordsByCoord = Dictionary(uniqueKeysWithValues: (snapshot?.records ?? []).map { ($0.chunkCoord, $0) })
        let centerX = Int(centerChunkCoord.x)
        let centerZ = Int(centerChunkCoord.z)

        return stride(from: centerZ + radius, through: centerZ - radius, by: -1).map { z in
            let cells = ((centerX - radius)...(centerX + radius)).map { x in
                let coord = WorldChunkCoord(x: Int32(x), z: Int32(z))
                let target = targetsByCoord[coord]
                let record = recordsByCoord[coord]
                return TelluricDebugChunkCell(
                    coord: coord,
                    lifecycleState: record?.lifecycleState ?? target?.targetState ?? .unloaded,
                    payloadState: record?.payloadState,
                    priorityRank: record?.priority.rank ?? target?.priority.rank,
                    isCached: record != nil,
                    isCenter: coord == centerChunkCoord
                )
            }

            return TelluricDebugChunkGridRow(z: Int32(z), cells: cells)
        }
    }

    func rebuild() {
        do {
            let request = WorldResidencyRequest(
                worldSeed: WorldSeed(seed),
                generatorVersion: generatorVersion,
                centerWorldPosition: TEVec3f(
                    x: Float(Int(centerChunkCoord.x) * layout.chunkSampleSpan),
                    y: 0,
                    z: Float(Int(centerChunkCoord.z) * layout.chunkSampleSpan)
                ),
                centerChunkCoord: centerChunkCoord,
                layout: layout,
                config: config
            )
            let plan = try planner.makePlan(request)
            let result = try pipeline.apply(plan: plan, cache: &cache)

            lastPlan = plan
            lastBuildResult = result
            snapshot = result.snapshot
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    func moveNorth() {
        move(dx: 0, dz: 1)
    }

    func moveSouth() {
        move(dx: 0, dz: -1)
    }

    func moveEast() {
        move(dx: 1, dz: 0)
    }

    func moveWest() {
        move(dx: -1, dz: 0)
    }

    func reset() {
        centerChunkCoord = WorldChunkCoord(x: 0, z: 0)
        cache = InMemoryWorldCache()
        rebuild()
    }

    private func move(dx: Int, dz: Int) {
        let nextX = Int(centerChunkCoord.x) + dx
        let nextZ = Int(centerChunkCoord.z) + dz

        guard nextX >= Int(Int32.min), nextX <= Int(Int32.max),
              nextZ >= Int(Int32.min), nextZ <= Int(Int32.max)
        else {
            errorMessage = "Center chunk coordinate is outside Int32 range."
            return
        }

        centerChunkCoord = WorldChunkCoord(x: Int32(nextX), z: Int32(nextZ))
        rebuild()
    }

    private static func hashLabel(_ value: UInt64?) -> String {
        guard let value else {
            return "none"
        }
        return "0x" + String(value, radix: 16, uppercase: true)
    }
}
