import SwiftUI

struct TelluricChunkGridView: View {
    let rows: [TelluricDebugChunkGridRow]

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(rows) { row in
                HStack(spacing: 5) {
                    ForEach(row.cells) { cell in
                        TelluricChunkCellView(cell: cell)
                    }
                }
            }
        }
        .padding(2)
    }
}
