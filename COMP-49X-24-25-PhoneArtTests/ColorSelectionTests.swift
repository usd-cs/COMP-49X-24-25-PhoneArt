//
//  ColorSelectionTests.swift
//  COMP-49X-24-25-PhoneArtTests
//

import XCTest
import SwiftUI
@testable import COMP_49X_24_25_PhoneArt

final class ColorSelectionTests: XCTestCase {
    var selectedColor: Binding<Color>!
    
    override func setUp() {
        super.setUp()
        selectedColor = Binding.constant(.red)
    }
    
    override func tearDown() {
        selectedColor = nil
        super.tearDown()
    }
    
    func testColorInitialization() {
        // Given
        let color = selectedColor.wrappedValue
        
        // Then
        XCTAssertEqual(color, .red)
    }
    
    func testHexColorConversion() {
        // Given
        let redHex = "#FF0000"
        let greenHex = "#00FF00"
        let blueHex = "#0000FF"
        
        // When & Then
        XCTAssertNotNil(Color(hex: redHex))
        XCTAssertNotNil(Color(hex: greenHex))
        XCTAssertNotNil(Color(hex: blueHex))
        XCTAssertNil(Color(hex: "invalid"))
    }
}

// MARK: - Color Extensions for Testing
extension Color {
    var cgColor: CGColor? {
        return UIColor(self).cgColor
    }
}
