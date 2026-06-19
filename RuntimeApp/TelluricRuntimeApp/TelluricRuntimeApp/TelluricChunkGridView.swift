import SwiftUI
import EngineCore

struct TelluricChunkGridView: View {
    let rows: [TelluricDebugChunkGridRow]
    let onSelectChunk: (WorldChunkCoord) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(rows) { row in
                HStack(spacing: 5) {
                    ForEach(row.cells) { cell in
                        TelluricChunkCellView(cell: cell, onSelect: onSelectChunk)
                    }
                }
            }
        }
        .padding(2)
    }
}
