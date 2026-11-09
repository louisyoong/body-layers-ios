import XCTest

/// Walks the main screens in every orientation and saves a screenshot of each, so
/// layout overlap after rotation can be reviewed on any simulator (iPhone Duo included).
/// Screenshots go to `$SCREENSHOT_DIR` when set (pass `TEST_RUNNER_SCREENSHOT_DIR` to
/// xcodebuild), and are always attached to the test result.
final class RotationScreenshotTests: XCTestCase {
    private let orientations: [(String, UIDeviceOrientation)] = [
        ("portrait", .portrait),
        ("landscapeLeft", .landscapeLeft),
        ("upsideDown", .portraitUpsideDown),
        ("landscapeRight", .landscapeRight),
    ]

    @MainActor
    func testScreensInAllOrientations() throws {
        let app = XCUIApplication()
        app.launch()
        let device = XCUIDevice.shared

        let human = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Human'")).firstMatch
        XCTAssertTrue(human.waitForExistence(timeout: 10))
        capture(app, page: "picker", device: device)

        // Human atlas: wait for the loading overlay to finish, select a structure so the
        // detail card is showing (the tallest panel state), then rotate.
        device.orientation = .portrait
        human.tap()
        let loading = app.staticTexts["Preparing your atlas"]
        let finished = NSPredicate(format: "exists == false")
        expectation(for: finished, evaluatedWith: loading)
        waitForExpectations(timeout: 180)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45)).tap()
        capture(app, page: "human", device: device)
        goBack(app, device: device)

        // Animal atlas.
        let animal = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Animal'")).firstMatch
        XCTAssertTrue(animal.waitForExistence(timeout: 10))
        animal.tap()
        _ = app.buttons["Species field notes"].waitForExistence(timeout: 30)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        capture(app, page: "animal", device: device)
        goBack(app, device: device)
    }

    @MainActor
    private func capture(_ app: XCUIApplication, page: String, device: XCUIDevice) {
        for (name, orientation) in orientations {
            device.orientation = orientation
            sleep(2)
            let label = "\(page)-\(name)"
            let shot = XCUIScreen.main.screenshot()
            let attachment = XCTAttachment(screenshot: shot)
            attachment.name = label
            attachment.lifetime = .keepAlways
            add(attachment)
            if let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] {
                let mainDir = URL(fileURLWithPath: dir).appendingPathComponent("main")
                try? FileManager.default.createDirectory(at: mainDir, withIntermediateDirectories: true)
                try? shot.pngRepresentation.write(to: mainDir.appendingPathComponent("\(label).png"))
            }
            requestHostScreenshot(label)
        }
        device.orientation = .portrait
    }

    /// `XCUIScreen` can't reliably capture iPhone Duo's outer display, so when
    /// `$SCREENSHOT_DIR` is set, a script on the Mac watches for `<label>.ready`, takes the
    /// screenshot with `simctl io --display`, and answers with `<label>.done`.
    private func requestHostScreenshot(_ label: String) {
        guard let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] else { return }
        let base = URL(fileURLWithPath: dir)
        let done = base.appendingPathComponent("\(label).done")
        FileManager.default.createFile(atPath: base.appendingPathComponent("\(label).ready").path, contents: nil)
        let deadline = Date().addingTimeInterval(20)
        while !FileManager.default.fileExists(atPath: done.path), Date() < deadline {
            usleep(200_000)
        }
    }

    @MainActor
    private func goBack(_ app: XCUIApplication, device: XCUIDevice) {
        device.orientation = .portrait
        let back = app.buttons["Back to study categories"].firstMatch
        XCTAssertTrue(back.waitForExistence(timeout: 5))
        back.tap()
    }
}
