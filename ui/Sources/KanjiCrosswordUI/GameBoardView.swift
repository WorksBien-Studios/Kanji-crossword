import SwiftUI
import KanjiGameCore

struct GameBoardView: View {
    @ObservedObject var model: GameSessionViewModel
    /// Numbers the player asked to have checked and that are still wrong.
    var flagged: Set<Int> = []

    @ScaledMetric(relativeTo: .body) private var baseScale: CGFloat = 1
    @GestureState private var gestureMagnification = 1.0
    @State private var scrollPosition = ScrollPosition(idType: String.self)
    @State private var didRestoreViewport = false
    @State private var fitCellSize: CGFloat = 46

    private let spacing: CGFloat = 2
    private let boardPadding: CGFloat = 10

    var body: some View {
        let insights = BoardInsights(puzzle: model.puzzle)
        let related = insights.relatedNumbers(of: model.state.selectedNumber)

        ScrollView([.horizontal, .vertical]) {
            Grid(horizontalSpacing: spacing, verticalSpacing: spacing) {
                ForEach(0..<model.puzzle.rows, id: \.self) { row in
                    GridRow {
                        ForEach(0..<model.puzzle.columns, id: \.self) { column in
                            cell(row: row, column: column, related: related)
                        }
                    }
                }
            }
            .padding(boardPadding)
        }
        .scrollPosition($scrollPosition)
        .defaultScrollAnchor(.center, for: .alignment)
        .onScrollGeometryChange(for: CGSize.self) { geometry in
            geometry.containerSize
        } action: { _, containerSize in
            let fitted = fittedCellSize(for: containerSize)
            if abs(fitted - fitCellSize) > 0.5 { fitCellSize = fitted }
            restoreViewportIfNeeded(containerSize: containerSize, fitted: fitted)
        }
        .onScrollPhaseChange { _, newPhase, context in
            guard newPhase == .idle, didRestoreViewport else { return }
            persistViewport(visibleRect: context.geometry.visibleRect)
        }
        .simultaneousGesture(
            MagnifyGesture()
                .updating($gestureMagnification) { value, state, _ in
                    state = Double(value.magnification)
                }
                .onEnded { value in
                    let zoom = clampedZoom(
                        model.state.viewport.zoomScale * Double(value.magnification)
                    )
                    var viewport = model.state.viewport
                    viewport.zoomScale = zoom
                    model.send(.updateViewport(viewport))
                }
        )
    }

    @ViewBuilder
    private func cell(row: Int, column: Int, related: Set<Int>) -> some View {
        let coordinate = CellCoordinate(row: row, column: column)
        if model.puzzle.cellLayout[row][column] == "#",
           model.puzzle.number(at: coordinate) == nil {
            // Empty space stays paper; only playable squares are drawn.
            Color.clear
                .frame(width: cellDimension, height: cellDimension)
                .accessibilityHidden(true)
        } else if let number = model.puzzle.number(at: coordinate) {
            PuzzleCellButton(
                number: number,
                entry: model.state.entries[number],
                visual: visual(for: number, related: related),
                highContrast: model.preferences.highContrast,
                size: cellDimension
            ) {
                model.send(.selectNumber(number))
            }
        } else {
            Color.clear
                .frame(width: cellDimension, height: cellDimension)
                .accessibilityHidden(true)
        }
    }

    private func visual(for number: Int, related: Set<Int>) -> CellVisual {
        if model.state.status == .completed { return .solved }
        if flagged.contains(number) {
            return model.state.selectedNumber == number ? .flaggedSelected : .flagged
        }
        if model.state.selectedNumber == number { return .selected }
        if related.contains(number) { return .related }
        if model.puzzle.startersByNumber[number] != nil { return .starter }
        return .plain
    }

    /// The board fits the container at zoom 1; pinch or the text-size setting
    /// makes the squares larger and the board scrolls.
    private var cellDimension: CGFloat {
        fitCellSize
            * baseScale
            * CGFloat(model.preferences.textScale)
            * CGFloat(model.state.viewport.zoomScale)
            * CGFloat(gestureMagnification)
    }

    private var cellStride: CGFloat {
        cellDimension + spacing
    }

    private func clampedZoom(_ zoom: Double) -> Double {
        min(max(zoom, 1), 4)
    }

    private func fittedCellSize(for containerSize: CGSize) -> CGFloat {
        guard containerSize.width > 0, containerSize.height > 0 else { return fitCellSize }
        let columns = CGFloat(max(model.puzzle.columns, 1))
        let rows = CGFloat(max(model.puzzle.rows, 1))
        let byWidth = (containerSize.width - 2 * boardPadding - spacing * (columns - 1)) / columns
        let byHeight = (containerSize.height - 2 * boardPadding - spacing * (rows - 1)) / rows
        return min(max(min(byWidth, byHeight), 40), 84)
    }

    private func restoreViewportIfNeeded(containerSize: CGSize, fitted: CGFloat) {
        guard !didRestoreViewport, containerSize.width > 0, containerSize.height > 0 else {
            return
        }

        let stride = fitted
            * baseScale
            * CGFloat(model.preferences.textScale)
            * CGFloat(model.state.viewport.zoomScale)
            + spacing
        let centerX = boardPadding
            + CGFloat(model.state.viewport.centerColumn) * stride
            + stride / 2
        let centerY = boardPadding
            + CGFloat(model.state.viewport.centerRow) * stride
            + stride / 2

        scrollPosition.scrollTo(
            x: max(0, centerX - containerSize.width / 2),
            y: max(0, centerY - containerSize.height / 2)
        )
        didRestoreViewport = true
    }

    private func persistViewport(visibleRect: CGRect) {
        let stride = max(cellStride, 1)
        var viewport = model.state.viewport
        viewport.centerColumn = Double(
            max(0, (visibleRect.midX - boardPadding) / stride)
        )
        viewport.centerRow = Double(
            max(0, (visibleRect.midY - boardPadding) / stride)
        )
        model.send(.updateViewport(viewport))
    }
}

enum CellVisual {
    case plain, starter, related, selected, flagged, flaggedSelected, solved
}

private struct PuzzleCellButton: View {
    let number: Int
    let entry: String?
    let visual: CellVisual
    let highContrast: Bool
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(fill)
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(
                        borderColor,
                        style: StrokeStyle(
                            lineWidth: borderWidth,
                            dash: isFlagged ? [6, 4] : []
                        )
                    )

                Text(String(number))
                    .font(.system(size: max(11, size * 0.26), weight: .bold))
                    .foregroundStyle(
                        highContrast ? KanjiTheme.ink : KanjiTheme.inkSecondary
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(EdgeInsets(top: 3, leading: 5, bottom: 0, trailing: 0))

                if let entry {
                    Text(entry)
                        .font(KanjiTheme.kanjiFont(size: size * 0.6))
                        .foregroundStyle(KanjiTheme.ink)
                        .minimumScaleFactor(0.6)
                        .padding(EdgeInsets(top: size * 0.14, leading: size * 0.08, bottom: 0, trailing: 0))
                }

                if isFlagged {
                    Text("?")
                        .font(.system(size: max(12, size * 0.28), weight: .bold))
                        .foregroundStyle(KanjiTheme.stamp)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 2, trailing: 5))
                }
            }
            .frame(width: size, height: size)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint("このマスを選択します")
        .accessibilityAddTraits(isSelectedVisual ? [.isSelected] : [])
    }

    private var isFlagged: Bool {
        visual == .flagged || visual == .flaggedSelected
    }

    private var isSelectedVisual: Bool {
        visual == .selected || visual == .flaggedSelected
    }

    private var fill: Color {
        switch visual {
        case .plain: KanjiTheme.card
        case .starter: KanjiTheme.starter
        case .related: KanjiTheme.related
        case .selected, .flaggedSelected: KanjiTheme.mark
        case .flagged: KanjiTheme.stampTint
        case .solved: KanjiTheme.successTint
        }
    }

    private var borderColor: Color {
        switch visual {
        case .selected: KanjiTheme.accent
        case .flagged, .flaggedSelected: KanjiTheme.stamp
        case .solved: KanjiTheme.success
        default: highContrast ? KanjiTheme.ink : KanjiTheme.line
        }
    }

    /// Selection is thick as well as coloured, so colour is never the only cue.
    private var borderWidth: CGFloat {
        let base: CGFloat = highContrast ? 3 : 1.5
        switch visual {
        case .selected, .flaggedSelected: return highContrast ? 5 : 4
        case .flagged: return 3
        default: return base
        }
    }

    private var accessibilityText: String {
        var text: String
        if let entry {
            text = "番号 \(number)、\(entry) が入力されています"
        } else {
            text = "番号 \(number)、空欄"
        }
        if isFlagged { text += "、見直してください" }
        return text
    }
}
