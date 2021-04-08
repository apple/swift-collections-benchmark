import XCTest
@testable import Kalimba

final class KalimbaTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Kalimba().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
