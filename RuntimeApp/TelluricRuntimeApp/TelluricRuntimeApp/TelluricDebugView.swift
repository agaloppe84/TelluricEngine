import SwiftUI

struct TelluricDebugView: View {
    @ObservedObject var model: TelluricDebugRuntimeModel

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            HStack(alignment: .top, spacing: 18) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        TelluricRuntimeControlsView(model: model)
                        TelluricDebugStatusView(model: model)
                        TelluricSnapshotStatsView(model: model)
                        TelluricPlayerProbeControlsView(model: model)
                        TelluricPlayerProbeInspectorView(model: model)
                        TelluricChunkInspectorView(model: model)
                        TelluricTerrainInspectionView(model: model)
                    }
                    .padding(.trailing, 2)
                }
                .frame(width: 360, alignment: .topLeading)

                VStack(alignment: .leading, spacing: 14) {
                    TelluricMetalDebugView(model: model)
                        .frame(minHeight: 520)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Chunk grid")
                                .font(.headline)
                            Spacer()
                            Text("SwiftUI debug selection")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        ScrollView([.horizontal, .vertical]) {
                            TelluricChunkGridView(rows: model.gridRows, onSelectChunk: model.selectChunk)
                                .padding(.trailing, 12)
                                .padding(.bottom, 12)
                        }
                    }
                    .frame(maxHeight: 230)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .padding(18)
        }
        .frame(minWidth: 1280, minHeight: 860)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Telluric Runtime Debug")
                    .font(.title2.weight(.semibold))
                Text("EngineCore snapshot with RenderCoreMetal debug terrain")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Seed \(model.seed)")
                    .font(.callout.monospacedDigit())
                Text("Center \(model.centerLabel)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }
}

#Preview {
    TelluricDebugView(model: TelluricDebugRuntimeModel())
}
