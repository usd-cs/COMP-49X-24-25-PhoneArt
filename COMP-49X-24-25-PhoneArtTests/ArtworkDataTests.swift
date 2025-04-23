import XCTest
import SwiftUI
@testable import COMP_49X_24_25_PhoneArt

final class ArtworkDataTests: XCTestCase {
    
    // MARK: - Test Data
    let sampleArtworkString = "shape:circle;rotation:45.0;scale:1.5;layer:1.0;skewX:10.0;skewY:20.0;spread:30.0;horizontal:100.0;vertical:150.0;primitive:2.0;colors:#FF5733,#33FF57;background:#FFFFFF"
    
    // MARK: - CreateArtworkString Tests
    
    func testCreateArtworkString() {
        // Test creating an artwork string with valid parameters
        let shapeType: ShapesPanel.ShapeType = .circle
        let rotation: Double = 45.0
        let scale: Double = 1.5
        let layer: Double = 1.0
        let skewX: Double = 10.0
        let skewY: Double = 20.0
        let spread: Double = 30.0
        let horizontal: Double = 100.0
        let vertical: Double = 150.0
        let primitive: Double = 2.0
        let colorPresets: [Color] = [Color(.sRGB, red: 1, green: 0.34, blue: 0.2, opacity: 1),
                                     Color(.sRGB, red: 0.2, green: 1, blue: 0.34, opacity: 1)]
        let backgroundColor: Color = .white
        
        let artworkString = ArtworkData.createArtworkString(
            shapeType: shapeType,
            rotation: rotation,
            scale: scale,
            layer: layer,
            skewX: skewX,
            skewY: skewY,
            spread: spread,
            horizontal: horizontal,
            vertical: vertical,
            primitive: primitive,
            colorPresets: colorPresets,
            backgroundColor: backgroundColor,
            useDefaultRainbowColors: false,
            rainbowStyle: 0,
            hueAdjustment: 0.0,
            saturationAdjustment: 0.0,
            numberOfVisiblePresets: 5,
            strokeColor: .black,
            strokeWidth: 1.0,
            shapeAlpha: 1.0
        )
        
        // Parse the artwork string to verify the values
        let decoded = ArtworkData.decode(from: artworkString)
        
        // Verify all parameters are encoded correctly
        XCTAssertEqual(decoded["shape"], shapeType.rawValue)
        XCTAssertEqual(decoded["rotation"], String(rotation))
        XCTAssertEqual(decoded["scale"], String(scale))
        XCTAssertEqual(decoded["layer"], String(layer))
        XCTAssertEqual(decoded["skewX"], String(skewX))
        XCTAssertEqual(decoded["skewY"], String(skewY))
        XCTAssertEqual(decoded["spread"], String(spread))
        XCTAssertEqual(decoded["horizontal"], String(horizontal))
        XCTAssertEqual(decoded["vertical"], String(vertical))
        XCTAssertEqual(decoded["primitive"], String(primitive))
        XCTAssertNotNil(decoded["colors"])
        XCTAssertNotNil(decoded["background"])
    }
    
    func testCreateArtworkStringWithInvalidValues() {
        // Test with out-of-range values
        let artworkString = ArtworkData.createArtworkString(
            shapeType: .circle,
            rotation: 400,       // Beyond max
            scale: 3.0,          // Beyond max
            layer: 500,          // Beyond max
            skewX: 150,          // Beyond max
            skewY: 150,          // Beyond max
            spread: 150,         // Beyond max
            horizontal: 400,     // Beyond max
            vertical: 400,       // Beyond max
            primitive: 10,       // Beyond max
            colorPresets: [.red, .blue],
            backgroundColor: .black,
            useDefaultRainbowColors: false,
            rainbowStyle: 0,
            hueAdjustment: 0.0,
            saturationAdjustment: 0.0,
            numberOfVisiblePresets: 2,
            strokeColor: .clear,
            strokeWidth: 0.0,
            shapeAlpha: 1.0
        )
        
        // Decode and verify values are clamped
        let decoded = ArtworkData.decode(from: artworkString)
        
        // Verify all values are clamped to their valid ranges
        XCTAssertEqual(decoded["rotation"], "360.0") // Max rotation
        XCTAssertEqual(decoded["scale"], "2.0") // Max scale
        XCTAssertEqual(decoded["layer"], "72.0") // Max layer
        XCTAssertEqual(decoded["skewX"], "100.0") // Max skew
        XCTAssertEqual(decoded["skewY"], "100.0") // Max skew
        XCTAssertEqual(decoded["spread"], "100.0") // Max spread
        XCTAssertEqual(decoded["horizontal"], "300.0") // Max horizontal
        XCTAssertEqual(decoded["vertical"], "300.0") // Max vertical
        XCTAssertEqual(decoded["primitive"], "6.0") // Max primitive
    }
    
    // MARK: - Decode Tests
    
    func testDecodeValidArtworkString() {
        let decoded = ArtworkData.decode(from: sampleArtworkString)
        
        // Verify all expected keys are present
        XCTAssertEqual(decoded["shape"], "circle")
        XCTAssertEqual(decoded["rotation"], "45.0")
        XCTAssertEqual(decoded["scale"], "1.5")
        XCTAssertEqual(decoded["layer"], "1.0")
        XCTAssertEqual(decoded["skewX"], "10.0")
        XCTAssertEqual(decoded["skewY"], "20.0")
        XCTAssertEqual(decoded["spread"], "30.0")
        XCTAssertEqual(decoded["horizontal"], "100.0")
        XCTAssertEqual(decoded["vertical"], "150.0")
        XCTAssertEqual(decoded["primitive"], "2.0")
        XCTAssertEqual(decoded["colors"], "#FF5733,#33FF57")
        XCTAssertEqual(decoded["background"], "#FFFFFF")
    }
    
    func testDecodeWithInvalidFormat() {
        // Test with improperly formatted string
        let invalidFormatString = "rotation=400.0;scale=3.0" // Uses = instead of :
        let decoded = ArtworkData.decode(from: invalidFormatString)
        
        // Verify no values are decoded
        XCTAssertTrue(decoded.isEmpty, "Incorrectly formatted string should result in empty dictionary")
    }
    
    func testDecodeWithMissingValues() {
        // Test with missing values
        let incompleteString = "shape:circle;rotation:45.0" // Only two parameters
        let decoded = ArtworkData.decode(from: incompleteString)
        
        // Verify only the provided values are decoded
        XCTAssertEqual(decoded.count, 2, "Only two parameters should be decoded")
        XCTAssertEqual(decoded["shape"], "circle")
        XCTAssertEqual(decoded["rotation"], "45.0")
    }
    
    // MARK: - Color Reconstruction Tests
    
    func testReconstructColorsIndirectly() {
        // Create an artwork string with known colors
        let artworkString = ArtworkData.createArtworkString(
            shapeType: .circle,
            rotation: 0,
            scale: 1,
            layer: 1,
            skewX: 0,
            skewY: 0,
            spread: 0,
            horizontal: 0,
            vertical: 0,
            primitive: 1,
            colorPresets: [.red, .blue, .green],
            backgroundColor: .black,
            useDefaultRainbowColors: false,
            rainbowStyle: 0,
            hueAdjustment: 0.0,
            saturationAdjustment: 0.0,
            numberOfVisiblePresets: 3,
            strokeColor: .black,
            strokeWidth: 1.0,
            shapeAlpha: 1.0
        )
        
        // Extract the colors string
        let decoded = ArtworkData.decode(from: artworkString)
        let colorsString = decoded["colors"] ?? ""
        
        // Reconstruct the colors
        let reconstructedColors = ArtworkData.reconstructColors(from: colorsString)
        
        // Verify we get the correct number of colors back
        XCTAssertEqual(reconstructedColors.count, 3, "Should reconstruct three colors")
    }
    
    func testReconstructColorsWithEmptyString() {
        // Test with empty string
        let colors = ArtworkData.reconstructColors(from: "")
        
        XCTAssertEqual(colors.count, 0, "Empty string should result in no colors")
    }
    
    // MARK: - ArtworkData Init Tests
    
    func testArtworkDataInitialization() {
        let deviceId = "test-device"
        let timestamp = Date()
        let title = "Test Artwork"
        
        let artworkData = ArtworkData(
            deviceId: deviceId,
            artworkString: sampleArtworkString,
            timestamp: timestamp,
            title: title
        )
        
        XCTAssertEqual(artworkData.deviceId, deviceId)
        XCTAssertEqual(artworkData.artworkString, sampleArtworkString)
        XCTAssertEqual(artworkData.timestamp, timestamp)
        XCTAssertEqual(artworkData.title, title)
    }
} 
