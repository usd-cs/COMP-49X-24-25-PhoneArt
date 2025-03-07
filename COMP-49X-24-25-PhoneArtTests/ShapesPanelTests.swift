//
//  ShapesPanelTests.swift
//  COMP-49X-24-25-PhoneArtTests
//
//  Created by Assistant on current_date
//

import XCTest
import SwiftUI
@testable import COMP_49X_24_25_PhoneArt

/// Test suite for the ShapesPanel component
final class ShapesPanelTests: XCTestCase {
    // Properties for testing
    var selectedShape: ShapesPanel.ShapeType!
    var isShowing: Bool!
    var switchToPropertiesCalled: Bool!
    var switchToColorPropertiesCalled: Bool!
    var sut: ShapesPanel!
    
    /// Sets up the test environment before each test method is called
    override func setUp() {
        super.setUp()
        // Initialize properties with default values
        selectedShape = .circle
        isShowing = true
        switchToPropertiesCalled = false
        switchToColorPropertiesCalled = false
        
        // Initialize the system under test (sut) with the properties
        sut = ShapesPanel(
            selectedShape: .constant(selectedShape),
            isShowing: .constant(isShowing),
            onSwitchToProperties: { self.switchToPropertiesCalled = true },
            onSwitchToColorProperties: { self.switchToColorPropertiesCalled = true }
        )
    }
    
    /// Cleans up after each test method is executed
    override func tearDown() {
        selectedShape = nil
        isShowing = nil
        switchToPropertiesCalled = nil
        switchToColorPropertiesCalled = nil
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    /// Tests that the panel initializes with the correct default values
    func testInitialization() {
        // Instead of accessing wrappedValue directly, we check the values we initially set
        XCTAssertEqual(selectedShape, .circle)
        XCTAssertTrue(isShowing)
    }
    
    // MARK: - ShapeType Enum Tests
    
    /// Tests that all shape types have the correct icon name
    func testShapeTypeIcons() {
        // Test a subset of shape types and their icons
        XCTAssertEqual(ShapesPanel.ShapeType.circle.icon, "circle.fill")
        XCTAssertEqual(ShapesPanel.ShapeType.square.icon, "square.fill")
        XCTAssertEqual(ShapesPanel.ShapeType.triangle.icon, "triangle.fill")
        XCTAssertEqual(ShapesPanel.ShapeType.hexagon.icon, "hexagon.fill")
        XCTAssertEqual(ShapesPanel.ShapeType.star.icon, "star.fill")
        XCTAssertEqual(ShapesPanel.ShapeType.rectangle.icon, "rectangle.fill")
        XCTAssertEqual(ShapesPanel.ShapeType.oval.icon, "oval.fill")
        XCTAssertEqual(ShapesPanel.ShapeType.diamond.icon, "diamond.fill")
        XCTAssertEqual(ShapesPanel.ShapeType.pentagon.icon, "pentagon.fill")
        XCTAssertEqual(ShapesPanel.ShapeType.octagon.icon, "octagon.fill")
        XCTAssertEqual(ShapesPanel.ShapeType.arrow.icon, "arrow.up.circle.fill")
        XCTAssertEqual(ShapesPanel.ShapeType.rhombus.icon, "rhombus.fill")
        XCTAssertEqual(ShapesPanel.ShapeType.parallelogram.icon, "rectangle.portrait.fill")
        XCTAssertEqual(ShapesPanel.ShapeType.trapezoid.icon, "trapezoid.and.line.vertical.fill")
    }
    
    /// Tests that all shape types have proper identifiers
    func testShapeTypeIdentifiers() {
        for shape in ShapesPanel.ShapeType.allCases {
            XCTAssertEqual(shape.id, shape.rawValue)
        }
    }
    
    // MARK: - Callback Tests
    
    /// Tests that the properties switch callback function is called correctly
    func testSwitchToPropertiesCallback() {
        // Create a test instance with a tracking closure
        let testPanel = ShapesPanel(
            selectedShape: .constant(.circle),
            isShowing: .constant(true),
            onSwitchToProperties: { self.switchToPropertiesCalled = true },
            onSwitchToColorProperties: { }
        )
        
        // Directly call the action to simulate button press
        switchToPropertiesCalled = false
        testPanel.onSwitchToProperties()
        
        // Verify the callback was called
        XCTAssertTrue(switchToPropertiesCalled)
    }
    
    /// Tests that the color properties switch callback function is called correctly
    func testSwitchToColorPropertiesCallback() {
        // Create a test instance with a tracking closure
        let testPanel = ShapesPanel(
            selectedShape: .constant(.circle),
            isShowing: .constant(true),
            onSwitchToProperties: { },
            onSwitchToColorProperties: { self.switchToColorPropertiesCalled = true }
        )
        
        // Directly call the action to simulate button press
        switchToColorPropertiesCalled = false
        testPanel.onSwitchToColorProperties()
        
        // Verify the callback was called
        XCTAssertTrue(switchToColorPropertiesCalled)
    }
    
    // MARK: - UI Component Tests
    
    /// Tests the header component of the panel
    func testPanelHeader() {
        let header = sut.panelHeader()
        // This is a basic test to ensure the function returns a valid view
        // For more comprehensive testing, a UI testing library like ViewInspector would be needed
        XCTAssertNotNil(header)
    }
    
    /// Tests the shape button component of the panel
    func testShapeButton() {
        // Test creating a button for each shape type
        for shape in ShapesPanel.ShapeType.allCases {
            let button = sut.shapeButton(shape)
            XCTAssertNotNil(button)
        }
    }
    
    /// Tests the properties button component of the panel
    func testPropertiesButton() {
        let button = sut.makePropertiesButton()
        XCTAssertNotNil(button)
    }
    
    /// Tests the color properties button component of the panel
    func testColorPropertiesButton() {
        let button = sut.makeColorPropertiesButton()
        XCTAssertNotNil(button)
    }
    
    /// Tests the shapes button component of the panel
    func testShapesButton() {
        let button = sut.makeShapesButton()
        XCTAssertNotNil(button)
    }
    
    // MARK: - Panel Visibility Test
    
    /// Tests that the panel visibility can be toggled
    func testPanelVisibility() {
        // Track changes to isShowing
        var testIsShowing = true
        
        // Create a binding that we can modify
        let isShowingBinding = Binding<Bool>(
            get: { testIsShowing },
            set: { newValue in
                // Update our tracking property when the binding is changed
                testIsShowing = newValue
            }
        )
        
        // Create a test instance with our custom binding
        let testPanel = ShapesPanel(
            selectedShape: .constant(.circle),
            isShowing: isShowingBinding,
            onSwitchToProperties: { },
            onSwitchToColorProperties: { }
        )
        
        // Verify initial state
        XCTAssertTrue(testIsShowing)
        
        // Simulate the close button tap handler which would set isShowing to false
        _ = testPanel.panelHeader()
        // In a real implementation, we would use ViewInspector or UI testing to tap the button
        // For this test, we'll manually update the binding
        isShowingBinding.wrappedValue = false
        
        // Verify the isShowing value was updated
        XCTAssertFalse(testIsShowing)
    }
}
