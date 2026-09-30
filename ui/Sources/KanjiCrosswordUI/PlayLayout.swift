import CoreGraphics

/// How the play screen is arranged in the pane it is given. Kept free of
/// SwiftUI so every number is unit-tested (see `PlayLayoutTests`).
///
/// - iPhone portrait: one column. Six 50pt tiles per row keep all 23 answer
///   tiles under 240pt, so the board is not squeezed below its 40pt floor.
/// - iPad one column (mini portrait, 744pt): board on top, five actions and
///   eight 64pt tiles per row below.
/// - iPad two column, and any landscape pane of 760pt or more: board beside a
///   320pt panel holding the words, actions and tiles.
struct PlayLayout: Equatable {
    enum Mode: Equatable {
        case stacked
        case sideBySide
    }

    let mode: Mode
    let trayColumns: Int
    let tileHeight: CGFloat
    let actionHeight: CGFloat
    let boardPadding: CGFloat

    static let sidePanelWidth: CGFloat = 320
    static let sideBySideMinWidth: CGFloat = 760
    /// Below this width a regular-width iPad shows the puzzle list and the
    /// board as two full-width steps instead of a split view.
    static let oneColumnMaxWidth: CGFloat = 800
    /// Readable width of the puzzle list on a one-column iPad.
    static let readableListWidth: CGFloat = 640

    static func make(paneSize size: CGSize) -> PlayLayout {
        if size.width >= sideBySideMinWidth, size.width > size.height {
            return PlayLayout(
                mode: .sideBySide,
                trayColumns: 4,
                tileHeight: 54,
                actionHeight: 60,
                boardPadding: 10
            )
        }
        if size.width < 500 {
            return PlayLayout(
                mode: .stacked,
                trayColumns: 6,
                tileHeight: 50,
                actionHeight: 60,
                boardPadding: 6
            )
        }
        return PlayLayout(
            mode: .stacked,
            trayColumns: 8,
            tileHeight: 64,
            actionHeight: 72,
            boardPadding: 10
        )
    }

    /// Height of the answer tray for `tileCount` tiles, including its 8pt
    /// row spacing and 8pt vertical padding.
    func trayHeight(tileCount: Int) -> CGFloat {
        let rows = CGFloat((tileCount + trayColumns - 1) / trayColumns)
        return rows * tileHeight + max(rows - 1, 0) * 8 + 16
    }
}

/// The board fits its container at zoom 1: the largest square that fits both
/// ways, clamped so squares stay tappable and never grow absurdly large.
enum BoardFit {
    static let spacing: CGFloat = 2
    static let minimumCell: CGFloat = 40
    static let maximumCell: CGFloat = 84

    static func cellSize(
        container: CGSize,
        columns: Int,
        rows: Int,
        padding: CGFloat
    ) -> CGFloat {
        let columns = CGFloat(max(columns, 1))
        let rows = CGFloat(max(rows, 1))
        let byWidth = (container.width - 2 * padding - spacing * (columns - 1)) / columns
        let byHeight = (container.height - 2 * padding - spacing * (rows - 1)) / rows
        return min(max(min(byWidth, byHeight), minimumCell), maximumCell)
    }
}
