//
//  IntegrationTests.swift
//  COMP-49X-24-25-PhoneArtTests
//
//  Created by Aditya Prakash on 11/21/24
//


import XCTest
import SwiftUI
@testable import COMP_49X_24_25_PhoneArt


// Protocol that defines common properties for canvas elements
protocol CanvasElement {
   var position: CGPoint { get set }
   var size: CGSize { get set }
   var strokeColor: Color { get set }
   var fillColor: Color { get set }
   var strokeWidth: CGFloat { get set }
}


// Implementation of circle element
class CircleElement: CanvasElement {
   var position: CGPoint
   var size: CGSize
   var strokeColor: Color
   var fillColor: Color
   var strokeWidth: CGFloat
  
   init(position: CGPoint, size: CGSize, strokeColor: Color, fillColor: Color, strokeWidth: CGFloat) {
       self.position = position
       self.size = size
       self.strokeColor = strokeColor
       self.fillColor = fillColor
       self.strokeWidth = strokeWidth
   }
}


// Implementation of rectangle element
class RectangleElement: CanvasElement {
   var position: CGPoint
   var size: CGSize
   var strokeColor: Color
   var fillColor: Color
   var strokeWidth: CGFloat
  
   init(position: CGPoint, size: CGSize, strokeColor: Color, fillColor: Color, strokeWidth: CGFloat) {
       self.position = position
       self.size = size
       self.strokeColor = strokeColor
       self.fillColor = fillColor
       self.strokeWidth = strokeWidth
   }
}


/// Test suite for integration between ShapesPanel and other UI components:
/// - ContentView: Tests state management between ShapesPanel and parent view
/// - PropertiesPanel: Tests panel switching behavior
/// - ColorPropertiesPanel: Tests color properties panel switching
final class ShapesPanelIntegrationTests: XCTestCase {
   // Properties for testing
   var selectedShape: ShapesPanel.ShapeType!
   var isShowing: Bool!
   var switchedToProperties: Bool!
   var switchedToColorProperties: Bool!
  
   // Additional properties for extended integration testing
   var canvasElements: [CanvasElement]!
   var selectedElement: CanvasElement?
   var selectedElementIndex: Int?
   var strokeColor: Color!
   var fillColor: Color!
   var strokeWidth: CGFloat!
  
   /// Sets up the test environment before each test method is called
   override func setUp() {
       super.setUp()
       // Initialize properties with default values
       selectedShape = .circle
       isShowing = true
       switchedToProperties = false
       switchedToColorProperties = false
      
       // Initialize additional properties
       canvasElements = []
       selectedElement = nil
       selectedElementIndex = nil
       strokeColor = .black
       fillColor = .white
       strokeWidth = 2.0
   }
  
   /// Cleans up after each test method is executed
   override func tearDown() {
       selectedShape = nil
       isShowing = nil
       switchedToProperties = nil
       switchedToColorProperties = nil
      
       // Clean up additional properties
       canvasElements = nil
       selectedElement = nil
       selectedElementIndex = nil
       strokeColor = nil
       fillColor = nil
       strokeWidth = nil
      
       super.tearDown()
   }
  
   // MARK: - Integration Tests
  
   /// Tests the ShapesPanel's state management integration with ContentView:
   /// - Panel visibility state syncs with parent view
   /// - Selected shape state syncs with parent view
   /// - Panel switching callbacks update parent state correctly
   func testPanelStateManagement() {
       // Create bindings that track changes
       let selectedShapeBinding = Binding<ShapesPanel.ShapeType>(
           get: { self.selectedShape },
           set: { self.selectedShape = $0 }
       )
      
       let isShowingBinding = Binding<Bool>(
           get: { self.isShowing },
           set: { self.isShowing = $0 }
       )
      
       // Create the panel
       let panel = ShapesPanel(
           selectedShape: selectedShapeBinding,
           isShowing: isShowingBinding,
           onSwitchToProperties: { self.switchedToProperties = true },
           onSwitchToColorProperties: { self.switchedToColorProperties = true },
           onSwitchToGallery: {}
       )
      
       // Test that hiding the panel updates the parent state
       isShowingBinding.wrappedValue = false
       XCTAssertFalse(self.isShowing)
      
       // Test that showing the panel updates the parent state
       isShowingBinding.wrappedValue = true
       XCTAssertTrue(self.isShowing)
      
       // Test that changing the selected shape updates the parent state
       selectedShapeBinding.wrappedValue = .square
       XCTAssertEqual(self.selectedShape, .square)
      
       // Test that switching to properties updates the parent state
       panel.onSwitchToProperties()
       XCTAssertTrue(self.switchedToProperties)
      
       // Test that switching to color properties updates the parent state
       panel.onSwitchToColorProperties()
       XCTAssertTrue(self.switchedToColorProperties)
   }
  
   /// Tests shape selection functionality in ShapesPanel:
   /// - Verifies all shape types from ShapeType enum are available
   /// - Confirms each shape can be selected and updates parent state
   func testAllShapesAreSelectable() {
       // Create a binding that tracks changes
       let selectedShapeBinding = Binding<ShapesPanel.ShapeType>(
           get: { self.selectedShape },
           set: { self.selectedShape = $0 }
       )
      
       // Create the panel
       let panel = ShapesPanel(
           selectedShape: selectedShapeBinding,
           isShowing: .constant(true),
           onSwitchToProperties: { },
           onSwitchToColorProperties: { },
           onSwitchToGallery: {}
       )
      
       // Test setting each shape type
       for shape in ShapesPanel.ShapeType.allCases {
           selectedShapeBinding.wrappedValue = shape
           XCTAssertEqual(self.selectedShape, shape)
       }
   }
  
   /// Tests interactions between ShapesPanel and other panels:
   /// - PropertiesPanel: Verifies proper switching and state updates
   /// - ColorPropertiesPanel: Ensures correct panel visibility transitions
   /// - Confirms mutual exclusivity of panel visibility
   func testMultiplePanelInteraction() {
       // Create bindings that track changes
       let isShapesShowing = Binding<Bool>(
           get: { self.isShowing },
           set: { self.isShowing = $0 }
       )
      
       // Note: These variables aren't used in the test, but kept for reference
       // since they represent how you might track other panel visibility states
       let _ = Binding<Bool>(
           get: { false },
           set: { _ in self.switchedToProperties = true }
       )
      
       let _ = Binding<Bool>(
           get: { false },
           set: { _ in self.switchedToColorProperties = true }
       )
      
       // Create a simulation of panel switching logic
       let onSwitchToProperties = {
           self.isShowing = false
           self.switchedToProperties = true
       }
      
       let onSwitchToColorProperties = {
           self.isShowing = false
           self.switchedToColorProperties = true
       }
      
       // Create the panel
       let panel = ShapesPanel(
           selectedShape: .constant(.circle),
           isShowing: isShapesShowing,
           onSwitchToProperties: onSwitchToProperties,
           onSwitchToColorProperties: onSwitchToColorProperties,
           onSwitchToGallery: {}
       )
      
       // Test switching to properties panel
       panel.onSwitchToProperties()
       XCTAssertFalse(self.isShowing) // ShapesPanel should be hidden
       XCTAssertTrue(self.switchedToProperties) // Properties panel should be shown
      
       // Reset and test switching to color properties panel
       self.isShowing = true
       self.switchedToProperties = false
       self.switchedToColorProperties = false
      
       panel.onSwitchToColorProperties()
       XCTAssertFalse(self.isShowing) // ShapesPanel should be hidden
       XCTAssertTrue(self.switchedToColorProperties) // Color properties panel should be shown
   }
  
   // MARK: - Extended Integration Tests
  
   /// Tests the integration between ShapesPanel, Canvas, and element selection:
   /// - Verifies adding shapes to canvas works correctly
   /// - Tests element selection updates UI state appropriately
   /// - Ensures properties panel reflects selected element attributes
   func testShapesCanvasIntegration() {
       // Create bindings for canvas elements and selection
       let canvasElementsBinding = Binding<[CanvasElement]>(
           get: { self.canvasElements },
           set: { (newElements: [CanvasElement]) in self.canvasElements = newElements }
       )
      
       let selectedElementIndexBinding = Binding<Int?>(
           get: { self.selectedElementIndex },
           set: { self.selectedElementIndex = $0 }
       )
      
       // Create shape panel binding
       let selectedShapeBinding = Binding<ShapesPanel.ShapeType>(
           get: { self.selectedShape },
           set: { self.selectedShape = $0 }
       )
      
       // Simulate adding a circle to canvas
       selectedShapeBinding.wrappedValue = .circle
      
       // Simulate canvas action that adds a shape
       let circleElement = CircleElement(
           position: CGPoint(x: 100, y: 100),
           size: CGSize(width: 50, height: 50),
           strokeColor: strokeColor,
           fillColor: fillColor,
           strokeWidth: strokeWidth
       )
       canvasElementsBinding.wrappedValue.append(circleElement)
      
       // Verify element was added to canvas
       XCTAssertEqual(canvasElementsBinding.wrappedValue.count, 1)
       XCTAssertTrue(canvasElementsBinding.wrappedValue.first is CircleElement)
      
       // Simulate selection of the element
       selectedElementIndexBinding.wrappedValue = 0
      
       // Verify correct element is selected
       XCTAssertEqual(selectedElementIndexBinding.wrappedValue, 0)
      
       // Add a square element
       selectedShapeBinding.wrappedValue = .square
      
       let squareElement = RectangleElement(
           position: CGPoint(x: 200, y: 200),
           size: CGSize(width: 75, height: 75),
           strokeColor: strokeColor,
           fillColor: fillColor,
           strokeWidth: strokeWidth
       )
       canvasElementsBinding.wrappedValue.append(squareElement)
      
       // Verify second element was added
       XCTAssertEqual(canvasElementsBinding.wrappedValue.count, 2)
       XCTAssertTrue(canvasElementsBinding.wrappedValue[1] is RectangleElement)
      
       // Test selection changes
       selectedElementIndexBinding.wrappedValue = 1
       XCTAssertEqual(selectedElementIndexBinding.wrappedValue, 1)
   }
  
   /// Tests color property panel integration with canvas elements:
   /// - Tests color changes reflect in selected elements
   /// - Verifies state is correctly maintained between panel switches
   /// - Ensures color panel values are updated when selecting different elements
   func testColorPropertiesIntegration() {
       // Create bindings for canvas elements and selection
       let canvasElementsBinding = Binding<[CanvasElement]>(
           get: { self.canvasElements },
           set: { self.canvasElements = $0 }
       )
      
       let selectedElementIndexBinding = Binding<Int?>(
           get: { self.selectedElementIndex },
           set: { self.selectedElementIndex = $0 }
       )
      
       // Create color bindings
       let strokeColorBinding = Binding<Color>(
           get: { self.strokeColor },
           set: { self.strokeColor = $0 }
       )
      
       let fillColorBinding = Binding<Color>(
           get: { self.fillColor },
           set: { self.fillColor = $0 }
       )
      
       // Add a test element to canvas
       let testElement = CircleElement(
           position: CGPoint(x: 150, y: 150),
           size: CGSize(width: 60, height: 60),
           strokeColor: strokeColor,
           fillColor: fillColor,
           strokeWidth: strokeWidth
       )
       canvasElementsBinding.wrappedValue.append(testElement)
      
       // Select the element
       selectedElementIndexBinding.wrappedValue = 0
       XCTAssertEqual(selectedElementIndexBinding.wrappedValue, 0)
      
       // Simulate color changes from color panel
       let newStrokeColor = Color.red
       let newFillColor = Color.blue
      
       strokeColorBinding.wrappedValue = newStrokeColor
       fillColorBinding.wrappedValue = newFillColor
      
       // Update the element with new colors
       if let index = selectedElementIndexBinding.wrappedValue {
           var updatedElement = canvasElementsBinding.wrappedValue[index]
           updatedElement.strokeColor = strokeColorBinding.wrappedValue
           updatedElement.fillColor = fillColorBinding.wrappedValue
           canvasElementsBinding.wrappedValue[index] = updatedElement
       }
      
       // Verify colors were updated on the element
       let updatedElement = canvasElementsBinding.wrappedValue[0]
       XCTAssertEqual(updatedElement.strokeColor, newStrokeColor)
       XCTAssertEqual(updatedElement.fillColor, newFillColor)
   }
  
   /// Tests the integration between PropertiesPanel, Canvas, and element manipulation:
   /// - Tests position and size changes from properties panel
   /// - Verifies stroke width changes are applied correctly
   /// - Ensures element transforms are reflected in properties panel
   func testPropertiesPanelCanvasIntegration() {
       // Create bindings for canvas elements and selection
       let canvasElementsBinding = Binding<[CanvasElement]>(
           get: { self.canvasElements },
           set: { self.canvasElements = $0 }
       )
      
       let selectedElementIndexBinding = Binding<Int?>(
           get: { self.selectedElementIndex },
           set: { self.selectedElementIndex = $0 }
       )
      
       // Create stroke width binding
       let strokeWidthBinding = Binding<CGFloat>(
           get: { self.strokeWidth },
           set: { self.strokeWidth = $0 }
       )
      
       // Add a test element to canvas
       let testElement = RectangleElement(
           position: CGPoint(x: 100, y: 100),
           size: CGSize(width: 80, height: 50),
           strokeColor: strokeColor,
           fillColor: fillColor,
           strokeWidth: strokeWidth
       )
       canvasElementsBinding.wrappedValue.append(testElement)
      
       // Select the element
       selectedElementIndexBinding.wrappedValue = 0
      
       // Simulate properties panel changes - increase stroke width
       let newStrokeWidth: CGFloat = 5.0
       strokeWidthBinding.wrappedValue = newStrokeWidth
      
       // Apply stroke width change to element
       if let index = selectedElementIndexBinding.wrappedValue {
           var updatedElement = canvasElementsBinding.wrappedValue[index]
           updatedElement.strokeWidth = strokeWidthBinding.wrappedValue
           canvasElementsBinding.wrappedValue[index] = updatedElement
       }
      
       // Verify stroke width was updated
       let updatedElement = canvasElementsBinding.wrappedValue[0]
       XCTAssertEqual(updatedElement.strokeWidth, newStrokeWidth)
      
       // Simulate position and size changes
       let newPosition = CGPoint(x: 150, y: 150)
       let newSize = CGSize(width: 100, height: 75)
      
       // Apply position and size changes
       if let index = selectedElementIndexBinding.wrappedValue {
           var updatedElement = canvasElementsBinding.wrappedValue[index]
           updatedElement.position = newPosition
           updatedElement.size = newSize
           canvasElementsBinding.wrappedValue[index] = updatedElement
       }
      
       // Verify position and size were updated
       let positionUpdatedElement = canvasElementsBinding.wrappedValue[0]
       XCTAssertEqual(positionUpdatedElement.position, newPosition)
       XCTAssertEqual(positionUpdatedElement.size, newSize)
   }
  
   /// Tests integration between color history, multiple element selection, and batch color operations:
   /// - Verifies recently used colors are tracked correctly
   /// - Tests applying colors to multiple selected elements simultaneously
   /// - Ensures color synchronization between panels and history
   func testColorHistoryAndMultipleElementIntegration() {
       // Create necessary bindings
       let canvasElementsBinding = Binding<[CanvasElement]>(
           get: { self.canvasElements },
           set: { self.canvasElements = $0 }
       )
      
       // Setup recent colors history
       var recentColors: [Color] = []
       let recentColorsBinding = Binding<[Color]>(
           get: { recentColors },
           set: { recentColors = $0 }
       )
      
       // Create multiple elements with default colors
       for i in 0..<3 {
           let element = CircleElement(
               position: CGPoint(x: 100 + CGFloat(i * 100), y: 100),
               size: CGSize(width: 50, height: 50),
               strokeColor: strokeColor,
               fillColor: fillColor,
               strokeWidth: strokeWidth
           )
           canvasElementsBinding.wrappedValue.append(element)
       }
      
       // Track multiple selected elements
       var selectedIndices: [Int] = []
      
       // Select multiple elements (indices 0 and 2)
       selectedIndices = [0, 2]
      
       // Apply a new color to all selected elements and add to history
       let newColor = Color.green
       recentColorsBinding.wrappedValue.append(newColor)
      
       // Verify color was added to history
       XCTAssertTrue(recentColorsBinding.wrappedValue.contains(newColor))
      
       // Apply the color to all selected elements
       for index in selectedIndices {
           var element = canvasElementsBinding.wrappedValue[index]
           element.fillColor = newColor
           canvasElementsBinding.wrappedValue[index] = element
       }
      
       // Verify color was applied only to selected elements
       XCTAssertEqual(canvasElementsBinding.wrappedValue[0].fillColor, newColor)
       XCTAssertNotEqual(canvasElementsBinding.wrappedValue[1].fillColor, newColor)
       XCTAssertEqual(canvasElementsBinding.wrappedValue[2].fillColor, newColor)
      
       // Use a color from history on a different element
       let selectedColor = recentColorsBinding.wrappedValue[0]
       let singleSelectedIndex = 1
      
       var element = canvasElementsBinding.wrappedValue[singleSelectedIndex]
       element.fillColor = selectedColor
       canvasElementsBinding.wrappedValue[singleSelectedIndex] = element
      
       // Verify history color was applied correctly
       XCTAssertEqual(canvasElementsBinding.wrappedValue[singleSelectedIndex].fillColor, selectedColor)
   }
  
   /// Tests integration between LayersPanel, Canvas, and element organization:
   /// - Verifies layer reordering affects rendering order
   /// - Tests layer visibility toggling
   /// - Ensures layer selection updates the correct element
   func testLayerManagementIntegration() {
       // Create necessary bindings
       let canvasElementsBinding = Binding<[CanvasElement]>(
           get: { self.canvasElements },
           set: { self.canvasElements = $0 }
       )
      
       // Setup layer visibility tracking
       var layerVisibility: [Bool] = []
       let layerVisibilityBinding = Binding<[Bool]>(
           get: { layerVisibility },
           set: { layerVisibility = $0 }
       )
      
       // Create multiple elements representing different layers
       for i in 0..<3 {
           let element: CanvasElement
          
           // Alternate between circles and rectangles
           if i % 2 == 0 {
               element = CircleElement(
                   position: CGPoint(x: 150, y: 150),
                   size: CGSize(width: 100, height: 100),
                   strokeColor: .black,
                   fillColor: i == 0 ? .red : (i == 2 ? .blue : .green),
                   strokeWidth: 2.0
               )
           } else {
               element = RectangleElement(
                   position: CGPoint(x: 200, y: 200),
                   size: CGSize(width: 120, height: 80),
                   strokeColor: .black,
                   fillColor: .yellow,
                   strokeWidth: 2.0
               )
           }
          
           canvasElementsBinding.wrappedValue.append(element)
           // Initialize all layers as visible
           layerVisibilityBinding.wrappedValue.append(true)
       }
      
       // Verify all elements were added
       XCTAssertEqual(canvasElementsBinding.wrappedValue.count, 3)
       XCTAssertEqual(layerVisibilityBinding.wrappedValue.count, 3)
      
       // Test layer reordering - move bottom layer to top
       let bottomElement = canvasElementsBinding.wrappedValue.removeFirst()
       canvasElementsBinding.wrappedValue.append(bottomElement)
      
       // Verify layer order changed
       XCTAssertEqual(canvasElementsBinding.wrappedValue[2].fillColor,
                     (bottomElement as? CircleElement)?.fillColor ?? (bottomElement as? RectangleElement)?.fillColor ?? .clear)
      
       // Test toggling layer visibility
       layerVisibilityBinding.wrappedValue[1] = false
      
       // Simulate rendering visible layers only
       let visibleLayers = canvasElementsBinding.wrappedValue.enumerated().filter { index, _ in
           return layerVisibilityBinding.wrappedValue[index]
       }.map { _, element in
           return element
       }
      
       // Verify correct number of visible layers
       XCTAssertEqual(visibleLayers.count, 2)
      
       // Test toggling visibility back on
       layerVisibilityBinding.wrappedValue[1] = true
      
       // Simulate rendering visible layers again
       let allVisibleLayers = canvasElementsBinding.wrappedValue.enumerated().filter { index, _ in
           return layerVisibilityBinding.wrappedValue[index]
       }.map { _, element in
           return element
       }
      
       // Verify all layers are visible again
       XCTAssertEqual(allVisibleLayers.count, 3)
      
       // Test layer selection and property modification
       let selectedLayerIndex = 1
       var selectedElement = canvasElementsBinding.wrappedValue[selectedLayerIndex]
       let newStrokeWidth: CGFloat = 4.0
       selectedElement.strokeWidth = newStrokeWidth
       canvasElementsBinding.wrappedValue[selectedLayerIndex] = selectedElement
      
       // Verify property was updated only on the selected layer
       XCTAssertEqual(canvasElementsBinding.wrappedValue[selectedLayerIndex].strokeWidth, newStrokeWidth)
       XCTAssertNotEqual(canvasElementsBinding.wrappedValue[0].strokeWidth, newStrokeWidth)
       XCTAssertNotEqual(canvasElementsBinding.wrappedValue[2].strokeWidth, newStrokeWidth)
   }
}

/// Test suite for integration between CanvasView state and its associated panels
final class CanvasViewInteractionTests: XCTestCase {


   // Properties for testing
   @MainActor var canvasView: CanvasView! // Needs MainActor as CanvasView uses @StateObject/@State
   var mockFirebaseService: MockFirebaseService!


   @MainActor override func setUp() {
       super.setUp()
       // Use the mock service for testing CanvasView interactions
       mockFirebaseService = MockFirebaseService()
       FirebaseService.shared = mockFirebaseService // Ensure shared instance is mocked
       canvasView = CanvasView(firebaseService: mockFirebaseService)
   }


   @MainActor override func tearDown() {
       canvasView = nil
       mockFirebaseService = nil
       super.tearDown()
   }


   // MARK: - Integration Tests


   /// Test 1: Interaction between CanvasView state and PropertiesPanel
   /// Verifies that changing a state variable bound to the PropertiesPanel
   /// correctly updates the CanvasView's internal state.
   @MainActor func testCanvasViewPropertiesPanelInteraction() {
       // Initial state verification (optional, but good practice)
       XCTAssertEqual(canvasView.shapeRotation, 0.0)


       // Simulate opening the PropertiesPanel and changing rotation
       // In a real test, we might instantiate the panel, but here we simulate the binding change
       let newRotation = 45.0
       canvasView.shapeRotation = newRotation // Directly manipulate the @State variable


       // Verify CanvasView's state reflects the change
       XCTAssertEqual(canvasView.shapeRotation, newRotation, "CanvasView's shapeRotation should update when the bound state changes.")
      
       // Simulate changing scale
       let newScale = 1.5
       canvasView.shapeScale = newScale
       XCTAssertEqual(canvasView.shapeScale, newScale, "CanvasView's shapeScale should update.")
   }


   /// Test 2: Interaction between CanvasView state and GalleryPanel (Load Artwork)
   /// Verifies that calling the `loadArtwork` function (simulating a gallery selection)
   /// correctly updates the CanvasView's state variables based on the loaded ArtworkData.
   @MainActor func testCanvasViewGalleryLoadInteraction() async {
       // Create mock artwork data to load
       let artworkID = "gallery-load-test-id"
       let artworkString = "shape:square;rotation:90.0;scale:1.2;layer:3;colors:#00FF00"
       let artworkToLoad = ArtworkData(
           deviceId: "test-dev",
           artworkString: artworkString,
           timestamp: Date(),
           title: "Loaded Artwork",
           pieceId: artworkID
       )


       // Initial state check (optional)
       XCTAssertNil(canvasView.loadedArtworkData)
       XCTAssertEqual(canvasView.selectedShape, .circle) // Default shape


       // Simulate the GalleryPanel calling the onLoadArtwork callback
       canvasView.loadArtwork(artwork: artworkToLoad)
      
       // Allow time for potential async operations within loadArtwork (though it seems mostly sync now)
       try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds


       // Verify CanvasView's state has been updated
       XCTAssertNotNil(canvasView.loadedArtworkData, "loadedArtworkData should be set.")
       XCTAssertEqual(canvasView.loadedArtworkData?.id, artworkToLoad.id, "The correct artwork ID should be loaded.")
       XCTAssertEqual(canvasView.selectedShape, .square, "Shape type should update based on loaded data.")
       XCTAssertEqual(canvasView.shapeRotation, 90.0, "Shape rotation should update.")
       XCTAssertEqual(canvasView.shapeScale, 1.2, "Shape scale should update.")
       XCTAssertEqual(canvasView.shapeLayer, 3.0, "Shape layer should update.")
      
       // Check if unsaved changes flag is correctly set to false after load
       XCTAssertFalse(canvasView.hasUnsavedChanges, "hasUnsavedChanges should be false immediately after loading.")
   }
}
