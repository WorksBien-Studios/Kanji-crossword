import SwiftUI
import KanjiGameCore

struct GameBoardView: View {
    @ObservedObject var model: GameSessionViewModel

    @ScaledMetric(relativeTo: .body) private var baseCellSize: CGFloat = 52
    @GestureState private var gestureMagnification = 1.0
    @State private var scrollPosition = ScrollPosition(idType: String.self)
    @State private var didRestoreViewport = false

    private let spacing: CGFloat = 1
    private let boardPadding: CGFloat = 16

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            Grid(horizontalSpacing: spacing, verticalSpacing: spacing) {
                ForEach(0..<model.puzzle.rows, id: \.self) { row in
                    GridRow {
                        ForEach(0..<model.puzzle.columns, id: \.self) { column in
                            cell(row: row, column: column)
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
            restoreViewportIfNeeded(containerSize: containerSize)
        }
        .onScrollPhaseChange { _, newPhase, context in
            guard newPhase == .idle, didRestoreViewport else { return }
            persistViewport(
                visibleRect: context.geometry.visibleRect
            )
        }
        .gesture(
            MagnifyGesture()
                .updating($gestureMagnification) { value, state, _ in
                    state = value.magnification
                }
                .onEnded { value in
                    let zoom = clampedZoom(
                        model.state.viewport.zoomScale * value.magnification
                    )
                    var viewport = model.state.viewport
                    viewport.zoomScale = zoom
                    model.send(.updateViewport(viewport))
                }
        )
    }

    @ViewBuilder
    private func cell(row: Int, column: Int) -> some View {
        let coordinate = CellCoordinate(row: row, column: column)
        if model.puzzle.cellLayout[row][column] == "#"
            || model.puzzle.number(at: coordinate) == nil {
            Rectangle()
                .fill(.primary)
                .frame(width: cellDimension, height: cellDimension)
                .accessibilityHidden(true)
        } else if let number = model.puzzle.number(at: coordinate) {
            PuzzleCellButton(
                number: number,
                entry: model.state.entries[number],
                isStarter: model.puzzle.startersByNumber[number] != nil,
                isSelected: model.state.selectedNumber == number,
                size: cellDimension
            ) {
                model.send(.selectNumber(number))
            }
        }
    }

    private var cellDimension: CGFloat {
        baseCellSize
            * model.state.viewport.zoomScale
            * gestureMagnification
    }

    private var cellStride: CGFloat {
        cellDimension + spacing
    }

    private func clampedZoom(_ zoom: Double) -> Double {
        min(max(zoom, 1), 4)
    }

    private func restoreViewportIfNeeded(containerSize: CGSize) {
        guard !didRestoreViewport, containerSize.width > 0, containerSize.height > 0 else {
            return
        }

        let stride = baseCellSize * model.state.viewport.zoomScale + spacing
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

private struct PuzzleCellButton: View {
    let number: Int
    let entry: String?
    let isStarter: Bool
    let isSelected: Bool
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Rectangle()
                    .fill(isSelected ? AnyShapeStyle(.tint.opacity(0.22)) : AnyShapeStyle(.background))
                Rectangle()
                    .strokeBorder(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.tertiary), lineWidth: isSelected ? 2 : 1)

                Text(String(number))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(4)

                if let entry {
                    Text(entry)
                        .font(.title2.weight(isStarter ? .bold : .regular))
                        .minimumScaleFactor(0.7)
                }
            }
            .frame(width: size, height: size)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var accessibilityText: String {
        if let entry {
            return "番号 \(number)、\(entry) が入力されています"
        }
        return "番号 \(number)、空欄"
    }
}
