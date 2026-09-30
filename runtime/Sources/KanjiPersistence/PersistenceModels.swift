#if canImport(SwiftData)
import Foundation
import SwiftData

@Model
public final class ActiveGameRecord {
    @Attribute(.unique) public var puzzleID: String
    public var sessionID: UUID
    public var updatedAt: Date
    @Attribute(.externalStorage) public var stateData: Data
    @Attribute(.externalStorage) public var puzzleSnapshotData: Data

    public init(puzzleID: String, sessionID: UUID, updatedAt: Date, stateData: Data, puzzleSnapshotData: Data) {
        self.puzzleID = puzzleID
        self.sessionID = sessionID
        self.updatedAt = updatedAt
        self.stateData = stateData
        self.puzzleSnapshotData = puzzleSnapshotData
    }
}

@Model
public final class CompletedGameRecord {
    @Attribute(.unique) public var sessionID: UUID
    public var puzzleID: String
    public var completedAt: Date
    public var elapsedSeconds: Double
    public var hintsUsed: Int
    public var checksUsed: Int
    @Attribute(.externalStorage) public var finalStateData: Data
    @Attribute(.externalStorage) public var puzzleSnapshotData: Data

    public init(
        sessionID: UUID,
        puzzleID: String,
        completedAt: Date,
        elapsedSeconds: Double,
        hintsUsed: Int,
        checksUsed: Int,
        finalStateData: Data,
        puzzleSnapshotData: Data
    ) {
        self.sessionID = sessionID
        self.puzzleID = puzzleID
        self.completedAt = completedAt
        self.elapsedSeconds = elapsedSeconds
        self.hintsUsed = hintsUsed
        self.checksUsed = checksUsed
        self.finalStateData = finalStateData
        self.puzzleSnapshotData = puzzleSnapshotData
    }
}

@Model
public final class AppPreferencesRecord {
    @Attribute(.unique) public var singletonKey: String
    public var textScale: Double
    public var highContrast: Bool
    public var hapticsEnabled: Bool
    public var timerEnabledByDefault: Bool
    public var updatedAt: Date

    public init(
        singletonKey: String = "preferences",
        textScale: Double = 1,
        highContrast: Bool = false,
        hapticsEnabled: Bool = true,
        timerEnabledByDefault: Bool = false,
        updatedAt: Date = Date()
    ) {
        self.singletonKey = singletonKey
        self.textScale = textScale
        self.highContrast = highContrast
        self.hapticsEnabled = hapticsEnabled
        self.timerEnabledByDefault = timerEnabledByDefault
        self.updatedAt = updatedAt
    }
}
#endif
