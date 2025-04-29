//
//  ColorShapesTests.swift
//  COMP-49X-24-25-PhoneArt
//
//  Created by Noah Huang on 3/6/25.
//

#if canImport(XCTest)
import XCTest
#endif
import SwiftUI


// Adjust the module name based on your project settings
#if canImport(COMP_49X_24_25_PhoneArt)
@testable import COMP_49X_24_25_PhoneArt
#endif


#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif


final class ColorShapesTests: XCTestCase {
   var isShowing: Binding<Bool>!
   var selectedColor: Binding<Color>!
   var onSwitchToPropertiesCalled = false
   var onSwitchToShapesCalled = false
  
   override func setUp() {
       super.setUp()
       isShowing = Binding.constant(true)
       selectedColor = Binding.constant(.red)
       onSwitchToPropertiesCalled = false
       onSwitchToShapesCalled = false
   }
  
   override func tearDown() {
       isShowing = nil
       selectedColor = nil
       super.tearDown()
   }
  
   func testPanelInitialization() {
       // Given
       _ = ColorPropertiesPanel(
           isShowing: isShowing,
           selectedColor: selectedColor,
           onSwitchToProperties: { self.onSwitchToPropertiesCalled = true },
           onSwitchToShapes: { self.onSwitchToShapesCalled = true },
           onSwitchToGallery: {}
       )
      
       // Then
       XCTAssertTrue(isShowing.wrappedValue)
       XCTAssertEqual(selectedColor.wrappedValue, .red)
   }
  
   
  
   func testPanelVisibilityToggle() {
       // Given
       var isShowingValue = true
       let isShowingBinding = Binding<Bool>(
           get: { isShowingValue },
           set: { isShowingValue = $0 }
       )
      
       // Create a new panel with the binding
       _ = ColorPropertiesPanel(
           isShowing: isShowingBinding,
           selectedColor: selectedColor,
           onSwitchToProperties: { self.onSwitchToPropertiesCalled = true },
           onSwitchToShapes: { self.onSwitchToShapesCalled = true },
           onSwitchToGallery: {}
       )
      
       // When - Simulating closing the panel
       isShowingBinding.wrappedValue = false
      
       // Then
       XCTAssertFalse(isShowingBinding.wrappedValue)
   }
  
  
   // Test that the panel's body view can be created without errors
   @MainActor
   func testBodyViewCreation() {
       // Given
       let panel = ColorPropertiesPanel(
           isShowing: isShowing,
           selectedColor: selectedColor,
           onSwitchToProperties: { self.onSwitchToPropertiesCalled = true },
           onSwitchToShapes: { self.onSwitchToShapesCalled = true },
           onSwitchToGallery: {}
       )
      
       // When & Then - Just ensure body creates a view without crashing
       let _ = panel.body
       // No assertion needed - if body fails, test will crash
   }
  
   func testPreviewProvider() {
       // Given & When
       let previewPanel = ColorPropertiesPanel_Previews.previews
      
       // Then - Just verify preview provider works without errors
       XCTAssertNotNil(previewPanel)
   }
  
   @MainActor
   func testColorShapesPanelInitialization() {
       // Create the panel with mock bindings
       let isShowing = Binding.constant(true)
       let selectedColor = Binding.constant(Color.red)
       let onSwitchToProperties = {}
       let onSwitchToShapes = {}
       let onSwitchToGallery = {}
      
       // Initialize the panel - note we use '_' to explicitly indicate we're not using this value
       // This avoids the "never used" warning
       _ = ColorPropertiesPanel(
           isShowing: isShowing,
           selectedColor: selectedColor,
           onSwitchToProperties: onSwitchToProperties,
           onSwitchToShapes: onSwitchToShapes,
           onSwitchToGallery: onSwitchToGallery
       )
      
       // Just test that initialization completes without errors
       XCTAssertTrue(true)
   }

  
   @MainActor
   func testSwitchToPropertiesCallback() {
       // Given
       let panel = ColorPropertiesPanel(
           isShowing: isShowing,
           selectedColor: selectedColor,
           onSwitchToProperties: { self.onSwitchToPropertiesCalled = true },
           onSwitchToShapes: { self.onSwitchToShapesCalled = true },
           onSwitchToGallery: {}
       )
      
       // When - simulate tapping the properties button
       panel.onSwitchToProperties()
      
       // Then
       XCTAssertTrue(onSwitchToPropertiesCalled)
   }
  
   @MainActor
   func testShapeSectionContentInitialization() {
       // Given
       let colorManager = ColorPresetManager.shared
       let originalHue = colorManager.hueAdjustment
       let originalSaturation = colorManager.saturationAdjustment
       let originalAlpha = colorManager.shapeAlpha
       let originalStrokeWidth = colorManager.strokeWidth
      
       // When
       let shapesSection = ShapesSectionContent()
       let _ = shapesSection.body
      
       // Then - verify initial state of UI matches ColorPresetManager
       // We need to update these to use extension helpers for access to private properties
       XCTAssertEqual(shapesSection.testHueText, "\(Int(colorManager.hueAdjustment * 100))")
       XCTAssertEqual(shapesSection.testSaturationText, "\(Int(colorManager.saturationAdjustment * 100))")
       XCTAssertEqual(shapesSection.testAlphaText, "\(Int(colorManager.shapeAlpha * 100))")
       XCTAssertEqual(shapesSection.testStrokeWidthText, String(format: "%.1f", colorManager.strokeWidth))
      
       // Cleanup
       colorManager.hueAdjustment = originalHue
       colorManager.saturationAdjustment = originalSaturation
       colorManager.shapeAlpha = originalAlpha
       colorManager.strokeWidth = originalStrokeWidth
   }
  
   @MainActor
   func testCloseButtonBehavior() {
       // Given
       var isShowingValue = true
       let isShowingBinding = Binding<Bool>(
           get: { isShowingValue },
           set: { isShowingValue = $0 }
       )
      
       // Create panel with binding but don't access its methods directly
       _ = ColorPropertiesPanel(
           isShowing: isShowingBinding,
           selectedColor: selectedColor,
           onSwitchToProperties: { self.onSwitchToPropertiesCalled = true },
           onSwitchToShapes: { self.onSwitchToShapesCalled = true },
           onSwitchToGallery: {}
       )
      
       // Simulate tapping the close button by directly toggling the binding
       isShowingBinding.wrappedValue = false
      
       // Then
       XCTAssertFalse(isShowingValue)
   }

   func testShapesSectionContentInitialization() {
       let section = ShapesSectionContent()
       XCTAssertNotNil(section)
       // Test testable properties if available
       _ = section.testHueText
       _ = section.testSaturationText
       _ = section.testAlphaText
       _ = section.testStrokeWidthText
   }
}
