import EngineCore
import simd

public enum MetalDebugTerrainColorMode: String, CaseIterable, Sendable, Hashable {
    case surface
    case lifecycle
    case altitude
    case mixed

    public var label: String {
        switch self {
        case .surface:
            return "Surface"
        case .lifecycle:
            return "Lifecycle"
        case .altitude:
            return "Altitude"
        case .mixed:
            return "Mixed"
        }
    }

    public var stableDebugID: UInt64 {
        switch self {
        case .surface:
            return 1
        case .lifecycle:
            return 2
        case .altitude:
            return 3
        case .mixed:
            return 4
        }
    }
}

public extension MetalTerrainMeshUploader {
    static func debugColor(
        heightMeters: Float,
        surface: TerrainSurfaceSample,
        lifecycleState: ChunkLifecycleState,
        colorMode: MetalDebugTerrainColorMode,
        renderMode: MetalTerrainRenderMode = .debug,
        isSelected: Bool = false
    ) -> SIMD4<Float> {
        if renderMode == .gamePreview {
            return gamePreviewColor(
                heightMeters: heightMeters,
                surface: surface,
                isSelected: isSelected
            )
        }

        let height01 = normalizedHeight(heightMeters)
        let baseColor: SIMD3<Float>

        switch colorMode {
        case .surface:
            baseColor = color(for: surface.material)
        case .lifecycle:
            baseColor = color(for: lifecycleState)
        case .altitude:
            baseColor = altitudeColor(height01)
        case .mixed:
            baseColor = mix(
                color(for: surface.material),
                color(for: lifecycleState),
                amount: 0.55
            )
        }

        let brightness = colorMode == .altitude ? 1 : 0.72 + height01 * 0.28
        let selectedColor = isSelected
            ? mix(baseColor, SIMD3<Float>(1.0, 0.94, 0.36), amount: 0.45)
            : baseColor

        return SIMD4<Float>(
            min(selectedColor.x * brightness, 1),
            min(selectedColor.y * brightness, 1),
            min(selectedColor.z * brightness, 1),
            1
        )
    }

    private static func gamePreviewColor(
        heightMeters: Float,
        surface: TerrainSurfaceSample,
        isSelected: Bool
    ) -> SIMD4<Float> {
        let height01 = max(0, min(1, (heightMeters + 12) / 24))
        let base = color(for: surface.material)
        let warmGrass = mix(base, SIMD3<Float>(0.30, 0.62, 0.28), amount: surface.material == .grass ? 0.45 : 0.18)
        let shaded = mix(
            warmGrass,
            SIMD3<Float>(0.82, 0.78, 0.62),
            amount: height01 * 0.20
        )
        let selected = isSelected
            ? mix(shaded, SIMD3<Float>(1.0, 0.92, 0.22), amount: 0.38)
            : shaded

        return SIMD4<Float>(
            min(max(selected.x, 0), 1),
            min(max(selected.y, 0), 1),
            min(max(selected.z, 0), 1),
            1
        )
    }

    private static func normalizedHeight(_ heightMeters: Float) -> Float {
        max(0, min(1, (heightMeters + 128) / 256))
    }

    private static func altitudeColor(_ height01: Float) -> SIMD3<Float> {
        if height01 < 0.33 {
            return mix(
                SIMD3<Float>(0.10, 0.34, 0.70),
                SIMD3<Float>(0.22, 0.56, 0.28),
                amount: height01 / 0.33
            )
        }

        if height01 < 0.68 {
            return mix(
                SIMD3<Float>(0.22, 0.56, 0.28),
                SIMD3<Float>(0.64, 0.54, 0.40),
                amount: (height01 - 0.33) / 0.35
            )
        }

        return mix(
            SIMD3<Float>(0.64, 0.54, 0.40),
            SIMD3<Float>(0.90, 0.92, 0.94),
            amount: (height01 - 0.68) / 0.32
        )
    }
}
