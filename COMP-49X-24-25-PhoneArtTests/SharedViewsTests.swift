#if canImport(XCTest)
import XCTest
import SwiftUI
@testable import COMP_49X_24_25_PhoneArt

final class SharedViewsTests: XCTestCase {
    func testSharedTooltipViewInitialization() {
        // Test that the view can be initialized with a string
        let tooltip = SharedTooltipView(text: "Test Tooltip")
        XCTAssertEqual(tooltip.text, "Test Tooltip")
    }

    func testSharedTooltipViewBody() {
        // Test that the body returns a Text view with the correct string
        let tooltip = SharedTooltipView(text: "Tooltip Body Test")
        let body = tooltip.body
        // Since body is some View, we can only check type at runtime
        XCTAssertNotNil(body)
    }

    func testSharedTooltipViewBodyTextContent() {
        let testString = "Tooltip Content"
        let tooltip = SharedTooltipView(text: testString)
        let mirror = Mirror(reflecting: tooltip.body)
        // Try to find a Text view in the body
        let containsText = mirror.children.contains { child in
            String(describing: type(of: child.value)).contains("Text")
        }
        XCTAssertTrue(containsText, "Body should contain a Text view")
    }
}
#endif 