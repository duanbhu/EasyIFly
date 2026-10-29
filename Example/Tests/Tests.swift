import XCTest
import EasyIFly

final class Tests: XCTestCase {
    #if targetEnvironment(simulator)
    func testSimulatorIgnoresInputUntilStartedAndAfterStopped() {
        let recognizer = SpeechRecognizer()
        recognizer.resultFilter = { $0 }
        var results: [String] = []
        recognizer.onResult = { results.append($0) }
        recognizer.simulateResult("before")
        recognizer.startListening()
        recognizer.stopListening()
        recognizer.simulateResult("after")
        XCTAssertTrue(results.isEmpty)
    }

    func testSimulatorFiltersRetriesAndDeliversOncePerSession() {
        let recognizer = SpeechRecognizer()
        recognizer.resultFilter = { $0.count == 11 ? $0 : nil }
        var results: [String] = []
        recognizer.onResult = { results.append($0) }
        recognizer.startListening()
        recognizer.simulateResult("invalid")
        recognizer.simulateResult("13800138000")
        recognizer.simulateResult("13900139000")
        XCTAssertEqual(results, ["13800138000"])
        recognizer.startListening()
        recognizer.simulateResult("13900139000")
        XCTAssertEqual(results, ["13800138000", "13900139000"])
    }

    func testSheetResultRemovesOverlayAndDismissesOnce() {
        let completed = expectation(description: "UI lifecycle")
        DispatchQueue.main.async {
            var results: [String] = []
            var dismissals = 0
            let sheet = EasyIFly.showVirtualNumberInput(theme: .red, onResult: {
                results.append($0)
            }, onDismiss: { dismissals += 1 })
            XCTAssertNotNil(sheet)
            sheet?.simulateResult("invalid")
            XCTAssertNotNil(sheet?.superview)
            sheet?.simulateResult("138001380001234")
            XCTAssertEqual(results, ["13800138000-1234"])
            XCTAssertNil(sheet?.superview)
            XCTAssertEqual(dismissals, 1)
            sheet?.simulateResult("138001380001234")
            XCTAssertEqual(dismissals, 1)
            completed.fulfill()
        }
        wait(for: [completed], timeout: 5)
    }
    #endif
}
