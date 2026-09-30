import CoreGraphics
import Testing
@testable import KanjiCrosswordUI

/// The scale numbers for every supported device, as executable spec. Each
/// case uses the pane a real screen leaves after its safe areas, top tab bar
/// (iPad, 50pt) and navigation bar, and checks that the board, strip, actions
/// and answer tray all fit at the stated cell size.
@Suite("Play layout scale")
struct PlayLayoutTests {
    private let columns = 9
    private let rows = 8
    private let tiles = 23

    private func cell(_ container: CGSize, _ layout: PlayLayout) -> CGFloat {
        BoardFit.cellSize(
            container: container,
            columns: columns,
            rows: rows,
            padding: layout.boardPadding
        ).rounded(.down)
    }

    @Test("iPhone 393 × 852: stacked, six 50pt tiles, 40pt cells")
    func iPhone() {
        let pane = CGSize(width: 393, height: 852 - 59 - 44 - 34)
        let layout = PlayLayout.make(paneSize: pane)
        #expect(layout.mode == .stacked)
        #expect(layout.trayColumns == 6)
        #expect(layout.tileHeight == 50)
        #expect(layout.trayHeight(tileCount: tiles) == 240)

        // Strip 56 + actions 64 + tray 240 leave 355pt for the board.
        let board = CGSize(width: pane.width, height: pane.height - 56 - 64 - 240)
        #expect(board.height == 355)
        #expect(cell(board, layout) == 40)
    }

    @Test("iPad mini 744 × 1133 upright: one column, eight 64pt tiles, 73pt cells")
    func iPadMini() {
        let pane = CGSize(width: 744, height: 1133 - 24 - 50 - 50 - 20)
        let layout = PlayLayout.make(paneSize: pane)
        #expect(layout.mode == .stacked)
        #expect(layout.trayColumns == 8)
        #expect(layout.tileHeight == 64)
        #expect(layout.trayHeight(tileCount: tiles) == 224)

        // Strip 64 + actions 76 + tray 224 leave 625pt for the board.
        let board = CGSize(width: pane.width, height: pane.height - 64 - 76 - 224)
        #expect(board.height == 625)
        #expect(cell(board, layout) == 73)
    }

    @Test("iPad 11-inch 1194 × 834 landscape: board beside a 320pt panel, 55pt cells")
    func iPad11Landscape() {
        let detail = CGSize(width: 1194 - 340 - 1, height: 834 - 24 - 50 - 50)
        let layout = PlayLayout.make(paneSize: detail)
        #expect(layout.mode == .sideBySide)
        #expect(layout.trayColumns == 4)

        let board = CGSize(
            width: detail.width - PlayLayout.sidePanelWidth - 1,
            height: detail.height - 20
        )
        #expect(board.width == 532)
        #expect(cell(board, layout) == 55)
    }

    @Test("iPad mini upright is too narrow for a side panel")
    func miniNeverSplitsUpright() {
        let layout = PlayLayout.make(paneSize: CGSize(width: 744, height: 1000))
        #expect(layout.mode == .stacked)
        #expect(PlayLayout.oneColumnMaxWidth > 744)
    }

    @Test("iPad 11-inch upright (834pt) is stacked, not side by side")
    func iPad11Upright() {
        let layout = PlayLayout.make(paneSize: CGSize(width: 834, height: 1000))
        #expect(layout.mode == .stacked)
        #expect(layout.trayColumns == 8)
    }

    @Test("iPhone landscape uses the side panel so the board keeps its height")
    func iPhoneLandscape() {
        let layout = PlayLayout.make(paneSize: CGSize(width: 852, height: 320))
        #expect(layout.mode == .sideBySide)
    }

    @Test("Cells never leave the 40–84pt range")
    func clamps() {
        let small = BoardFit.cellSize(
            container: CGSize(width: 200, height: 200),
            columns: 9,
            rows: 8,
            padding: 6
        )
        let large = BoardFit.cellSize(
            container: CGSize(width: 2000, height: 2000),
            columns: 9,
            rows: 8,
            padding: 10
        )
        #expect(small == BoardFit.minimumCell)
        #expect(large == BoardFit.maximumCell)
    }
}
