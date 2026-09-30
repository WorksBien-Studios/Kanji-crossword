import SwiftUI
import KanjiGameCore
import KanjiPersistence

public struct HistoryRootView: View {
    let persistence: GamePersistenceStore

    @State private var history: [CompletedGame] = []
    @State private var selectedSessionID: UUID?
    @State private var compactColumn: NavigationSplitViewColumn = .sidebar
    @State private var monthAnchor = Date()
    @State private var selectedDay: Date = Calendar.current.startOfDay(for: Date())
    @State private var loadError: String?

    private var calendar: Calendar { .current }

    public init(persistence: GamePersistenceStore) {
        self.persistence = persistence
    }

    public var body: some View {
        NavigationSplitView(preferredCompactColumn: $compactColumn) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    calendarCard
                    dayHeader
                    dayList
                }
                .padding(16)
            }
            .background(KanjiTheme.canvas)
            .navigationTitle("記録")
        } detail: {
            if let game = selectedGame {
                ResultsView(
                    state: game.state,
                    puzzle: game.puzzle,
                    personalBest: ResultMetrics.personalBest(
                        puzzleID: game.puzzle.id,
                        states: history.map(\.state)
                    )
                )
                    .id(game.id)
            } else if let loadError {
                ContentUnavailableView {
                    Label("記録を読み込めません", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(loadError)
                }
            } else {
                ContentUnavailableView(
                    "記録を選んでください",
                    systemImage: "checkmark.circle"
                )
            }
        }
        .task {
            await reload()
        }
    }

    // MARK: Calendar

    private var completionDates: [Date] {
        history.compactMap { $0.state.completedAt }
    }

    private var calendarCard: some View {
        let grid = MonthGrid.make(for: monthAnchor, calendar: calendar)
        let played = PlayStats.playedDays(
            completionDates,
            inMonthOf: monthAnchor,
            calendar: calendar
        )
        return KanjiCard {
            VStack(spacing: 8) {
                HStack {
                    Button {
                        shiftMonth(-1)
                    } label: {
                        Label("前の月", systemImage: "chevron.left")
                            .labelStyle(.iconOnly)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    Spacer()
                    VStack(spacing: 0) {
                        Text(JapaneseDateText.eraMonth(monthAnchor))
                            .font(.system(size: 21, weight: .bold, design: .serif))
                            .foregroundStyle(KanjiTheme.ink)
                        Text("この月は\(played.count)日遊びました")
                            .font(.footnote)
                            .foregroundStyle(KanjiTheme.inkSecondary)
                    }
                    Spacer()
                    Button {
                        shiftMonth(1)
                    } label: {
                        Label("次の月", systemImage: "chevron.right")
                            .labelStyle(.iconOnly)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                }
                .foregroundStyle(KanjiTheme.accentText)

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7),
                    spacing: 2
                ) {
                    ForEach(Array(grid.weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                        Text(symbol)
                            .font(.footnote.bold())
                            .foregroundStyle(KanjiTheme.inkSecondary)
                    }
                    ForEach(0..<grid.leadingBlanks, id: \.self) { _ in
                        Color.clear.frame(height: 46)
                    }
                    ForEach(1...max(grid.dayCount, 1), id: \.self) { day in
                        dayCell(day, played: played.contains(day))
                    }
                }

                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        StampMark(kind: .complete, size: 16)
                        Text("完成")
                    }
                    HStack(spacing: 6) {
                        Circle().fill(KanjiTheme.related).frame(width: 16, height: 16)
                        Text("今日")
                    }
                    Spacer()
                }
                .font(.footnote)
                .foregroundStyle(KanjiTheme.inkSecondary)
            }
        }
    }

    private func dayCell(_ day: Int, played: Bool) -> some View {
        let date = dateFor(day: day)
        let isToday = date.map { calendar.isDateInToday($0) } ?? false
        let isSelected = date.map { calendar.isDate($0, inSameDayAs: selectedDay) } ?? false
        return Button {
            if let date {
                selectedDay = calendar.startOfDay(for: date)
            }
        } label: {
            ZStack {
                if isToday {
                    Circle().fill(KanjiTheme.related).frame(width: 40, height: 40)
                }
                if played {
                    StampMark(kind: .complete, size: 38)
                }
                Text(String(day))
                    .font(.body.bold())
                    .foregroundStyle(KanjiTheme.ink)
            }
            .frame(maxWidth: .infinity, minHeight: 46)
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(KanjiTheme.accent, lineWidth: 3)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(day)日\(played ? "、完成あり" : "")")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: Day list

    private var dayHeader: some View {
        Text(selectedDay, format: .dateTime.month().day())
            .font(.subheadline.bold())
            .foregroundStyle(KanjiTheme.inkSecondary)
    }

    private var gamesOnSelectedDay: [CompletedGame] {
        history.filter { game in
            guard let completedAt = game.state.completedAt else { return false }
            return calendar.isDate(completedAt, inSameDayAs: selectedDay)
        }
    }

    @ViewBuilder
    private var dayList: some View {
        let games = gamesOnSelectedDay
        if games.isEmpty {
            KanjiCard {
                Text(history.isEmpty ? "まだ記録がありません。" : "この日は、まだ遊んでいません。")
                    .foregroundStyle(KanjiTheme.inkSecondary)
            }
        } else {
            VStack(spacing: 10) {
                ForEach(games) { game in
                    Button {
                        selectedSessionID = game.id
                        compactColumn = .detail
                    } label: {
                        KanjiCard {
                            HStack(spacing: 14) {
                                MiniBoardView(
                                    puzzle: game.puzzle,
                                    cellSize: game.puzzle.columns > 10 ? 6 : 9,
                                    style: .solved
                                )
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(game.puzzle.difficulty.japaneseTitle) ・ \(game.puzzle.mode.japaneseTitle)")
                                        .font(.headline)
                                        .foregroundStyle(KanjiTheme.ink)
                                    Text("ヒント \(game.state.hintsUsed)回 ・ 確認 \(game.state.checksUsed)回")
                                        .font(.subheadline)
                                        .foregroundStyle(KanjiTheme.inkSecondary)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(KanjiTheme.inkSecondary)
                                    .accessibilityHidden(true)
                            }
                        }
                        .overlay {
                            if selectedSessionID == game.id {
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .strokeBorder(KanjiTheme.accent, lineWidth: 3)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Helpers

    private var selectedGame: CompletedGame? {
        guard let selectedSessionID else { return nil }
        return history.first { $0.id == selectedSessionID }
    }

    private func dateFor(day: Int) -> Date? {
        var components = calendar.dateComponents([.year, .month], from: monthAnchor)
        components.day = day
        return calendar.date(from: components)
    }

    private func shiftMonth(_ delta: Int) {
        if let next = calendar.date(byAdding: .month, value: delta, to: monthAnchor) {
            monthAnchor = next
        }
    }

    @MainActor
    private func reload() async {
        do {
            history = try await persistence.completionHistory()
            if let latest = history.first?.state.completedAt {
                selectedDay = calendar.startOfDay(for: latest)
                monthAnchor = latest
            }
            loadError = nil
        } catch {
            loadError = String(describing: error)
        }
    }
}
