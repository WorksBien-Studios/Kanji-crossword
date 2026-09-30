#if DEBUG && canImport(UIKit)
import SwiftUI
import UIKit
import Testing
@testable import KanjiCrosswordUI

/// Renders the real screens on the simulator it runs on and writes PNGs to
/// /tmp/kanji-shots. Off by default; the "UI screenshots" workflow switches it
/// on with TEST_RUNNER_KANJI_SCREENSHOTS=1.
@MainActor
@Suite(
    "Device screenshots",
    .enabled(if: ProcessInfo.processInfo.environment["KANJI_SCREENSHOTS"] == "1")
)
struct ScreenshotTests {
    private let device = ProcessInfo.processInfo.environment["KANJI_SHOT_DEVICE"] ?? "device"
    private let landscape = ProcessInfo.processInfo.environment["KANJI_LANDSCAPE"] == "1"

    private var size: CGSize {
        let bounds = UIScreen.main.bounds.size
        let short = min(bounds.width, bounds.height)
        let long = max(bounds.width, bounds.height)
        return landscape
            ? CGSize(width: long, height: short)
            : CGSize(width: short, height: long)
    }

    /// The system chrome the play screen sits inside on a real device: safe
    /// areas, plus the 50pt floating tab bar on iPad.
    private var chromeInsets: UIEdgeInsets {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return UIEdgeInsets(top: 24 + 50, left: 0, bottom: 20, right: 0)
        }
        return UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0)
    }

    @Test("Full app and play screen")
    func captureScreens() async throws {
        let seed = try #require(await PreviewSeed.make())

        try await capture(
            KanjiCrosswordRootView(catalog: seed.catalog, persistence: seed.persistence),
            name: "app",
            insets: .zero,
            wait: 5
        )
        try await capture(
            PlayScreenPreview(persistence: seed.persistence),
            name: "play",
            insets: chromeInsets,
            wait: 4
        )
    }

    private func capture<V: View>(
        _ view: V,
        name: String,
        insets: UIEdgeInsets,
        wait seconds: Double
    ) async throws {
        let frame = CGRect(origin: .zero, size: size)
        let host = UIHostingController(rootView: view)
        host.additionalSafeAreaInsets = insets
        let window = UIWindow(frame: frame)
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.frame = frame
        host.view.layoutIfNeeded()

        try await Task.sleep(for: .seconds(seconds))

        let image = UIGraphicsImageRenderer(bounds: frame).image { _ in
            window.drawHierarchy(in: frame, afterScreenUpdates: true)
        }
        let directory = URL(fileURLWithPath: "/tmp/kanji-shots", isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        let file = directory.appendingPathComponent("\(device)-\(name).png")
        try #require(image.pngData()).write(to: file)
        window.isHidden = true
    }
}
#endif
