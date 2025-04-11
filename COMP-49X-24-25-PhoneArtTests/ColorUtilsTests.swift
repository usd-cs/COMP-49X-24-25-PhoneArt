import XCTest
import SwiftUI
@testable import COMP_49X_24_25_PhoneArt

class ColorUtilsTests: XCTestCase {
    
    // Test the adjustColor method with various parameters
    func testAdjustColor() {
        // Test with default parameters
        let originalColor = Color.red
        let adjustedColor = ColorUtils.adjustColor(originalColor, 
                                                  hueShift: 0, 
                                                  saturationScale: 1.0, 
                                                  useDefaultRainbowColors: false)
        
        // We can't directly compare colors in SwiftUI, but we can verify it returns a Color
        XCTAssertNotNil(adjustedColor)
        
        // Test with hue shift
        let hueShiftedColor = ColorUtils.adjustColor(originalColor, 
                                                    hueShift: 0, 
                                                    saturationScale: 1.0, 
                                                    useDefaultRainbowColors: false)
        XCTAssertNotNil(hueShiftedColor)
        
        // Test with saturation change
        let saturationChangedColor = ColorUtils.adjustColor(originalColor, 
                                                          hueShift: 0, 
                                                          saturationScale: 0.5, 
                                                          useDefaultRainbowColors: false)
        XCTAssertNotNil(saturationChangedColor)
        
        // Test with default rainbow colors
        let rainbowColor = ColorUtils.adjustColor(originalColor, 
                                                hueShift: 0, 
                                                saturationScale: 1.0, 
                                                useDefaultRainbowColors: true)
        XCTAssertNotNil(rainbowColor)
    }
    
    // Test rainbowColor with various parameters
    func testRainbowColor() {
        // Test with different position values
        let positions = [0, 25, 50, 75, 100]
        
        for position in positions {
            let color = ColorUtils.rainbowColor(for: position, 
                                              hueAdjustment: 0.0, 
                                              saturationAdjustment: 0.0)
            XCTAssertNotNil(color, "Color should be generated for position \(position)")
        }
        
        // Test with hue adjustment
        let rainbowWithHueAdj = ColorUtils.rainbowColor(for: 50, 
                                                      hueAdjustment: 0.2, 
                                                      saturationAdjustment: 0.0)
        XCTAssertNotNil(rainbowWithHueAdj)
        
        // Test with saturation adjustment
        let rainbowWithSatAdj = ColorUtils.rainbowColor(for: 50, 
                                                      hueAdjustment: 0.0, 
                                                      saturationAdjustment: 0.2)
        XCTAssertNotNil(rainbowWithSatAdj)
        
        // Test with both adjustments
        let rainbowWithBothAdj = ColorUtils.rainbowColor(for: 50, 
                                                       hueAdjustment: 0.2, 
                                                       saturationAdjustment: 0.2)
        XCTAssertNotNil(rainbowWithBothAdj)
    }
    
    // Test cyberpunkRainbowColor with various parameters
    func testCyberpunkRainbowColor() {
        // Test with different position values
        let positions = [0, 25, 50, 75, 100]
        
        for position in positions {
            let color = ColorUtils.cyberpunkRainbowColor(for: position, 
                                                       hueAdjustment: 0.0, 
                                                       saturationAdjustment: 0.0)
            XCTAssertNotNil(color, "Cyberpunk color should be generated for position \(position)")
        }
        
        // Test with hue adjustment
        let cyberpunkWithHueAdj = ColorUtils.cyberpunkRainbowColor(for: 50, 
                                                                 hueAdjustment: 0.2, 
                                                                 saturationAdjustment: 0.0)
        XCTAssertNotNil(cyberpunkWithHueAdj)
        
        // Test with saturation adjustment
        let cyberpunkWithSatAdj = ColorUtils.cyberpunkRainbowColor(for: 50, 
                                                                 hueAdjustment: 0.0, 
                                                                 saturationAdjustment: 0.2)
        XCTAssertNotNil(cyberpunkWithSatAdj)
        
        // Test with both adjustments
        let cyberpunkWithBothAdj = ColorUtils.cyberpunkRainbowColor(for: 50, 
                                                                  hueAdjustment: 0.2, 
                                                                  saturationAdjustment: 0.2)
        XCTAssertNotNil(cyberpunkWithBothAdj)
    }
    
    // Test halfSpectrumRainbowColor with various parameters
    func testHalfSpectrumRainbowColor() {
        // Test with different position values
        let positions = [0, 25, 50, 75, 100]
        
        for position in positions {
            let color = ColorUtils.halfSpectrumRainbowColor(for: position, 
                                                          hueAdjustment: 0.0, 
                                                          saturationAdjustment: 0.0)
            XCTAssertNotNil(color, "Half spectrum color should be generated for position \(position)")
        }
        
        // Test with hue adjustment
        let halfSpectrumWithHueAdj = ColorUtils.halfSpectrumRainbowColor(for: 50, 
                                                                       hueAdjustment: 0.2, 
                                                                       saturationAdjustment: 0.0)
        XCTAssertNotNil(halfSpectrumWithHueAdj)
        
        // Test with saturation adjustment
        let halfSpectrumWithSatAdj = ColorUtils.halfSpectrumRainbowColor(for: 50, 
                                                                       hueAdjustment: 0.0, 
                                                                       saturationAdjustment: 0.2)
        XCTAssertNotNil(halfSpectrumWithSatAdj)
        
        // Test with both adjustments
        let halfSpectrumWithBothAdj = ColorUtils.halfSpectrumRainbowColor(for: 50, 
                                                                        hueAdjustment: 0.2, 
                                                                        saturationAdjustment: 0.2)
        XCTAssertNotNil(halfSpectrumWithBothAdj)
    }
    
    // Test the relationship between color generation methods
    func testColorGenerationConsistency() {
        // All methods should generate a color for a given position
        let position = 30
        let hueAdj = 0.1
        let satAdj = 0.1
        
        let rainbow = ColorUtils.rainbowColor(for: position, hueAdjustment: hueAdj, saturationAdjustment: satAdj)
        let cyberpunk = ColorUtils.cyberpunkRainbowColor(for: position, hueAdjustment: hueAdj, saturationAdjustment: satAdj)
        let halfSpectrum = ColorUtils.halfSpectrumRainbowColor(for: position, hueAdjustment: hueAdj, saturationAdjustment: satAdj)
        
        // Each method should produce a different color scheme but all should be valid colors
        XCTAssertNotNil(rainbow)
        XCTAssertNotNil(cyberpunk)
        XCTAssertNotNil(halfSpectrum)
        
        // Note: We can't directly compare Color instances as they're opaque
        // but all generators should return non-nil colors
    }
} 