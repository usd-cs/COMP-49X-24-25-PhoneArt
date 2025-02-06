import XCTest
@testable import PhoneArt

final class PhoneArtTests: XCTestCase {
    func testHello() {
        let sut = PhoneArt()
        XCTAssertEqual(sut.hello(), "Hello from PhoneArt!")
    }
} 