import Foundation

public enum MetalDebugRenderError: Error, Equatable, LocalizedError {
    case emptyMeshList
    case emptyMeshPayload(UInt64)
    case bufferAllocationFailed(String)
    case shaderResourceMissing(String)
    case shaderCompilationFailed(String)
    case pipelineCreationFailed(String)
    case commandQueueCreationFailed
    case missingDevice

    public var errorDescription: String? {
        switch self {
        case .emptyMeshList:
            return "No terrain meshes were provided for Metal debug rendering."
        case .emptyMeshPayload(let stableHash):
            return "Terrain mesh payload is empty: \(stableHash)."
        case .bufferAllocationFailed(let label):
            return "Metal buffer allocation failed: \(label)."
        case .shaderResourceMissing(let name):
            return "Metal shader resource is missing: \(name)."
        case .shaderCompilationFailed(let message):
            return "Metal shader compilation failed: \(message)."
        case .pipelineCreationFailed(let message):
            return "Metal render pipeline creation failed: \(message)."
        case .commandQueueCreationFailed:
            return "Metal command queue creation failed."
        case .missingDevice:
            return "No Metal device is available."
        }
    }
}
