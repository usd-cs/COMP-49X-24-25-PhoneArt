//
//  ShapesPanel.swift
//  COMP-49X-24-25-PhoneArt
//
//  Created by Assistant on current_date
//

import SwiftUI

/// A panel that provides shape selection options for the canvas.
/// Allows users to select different shapes to draw on the canvas.
/// The panel includes:
/// - A grid of shape options that users can select from
/// - Navigation buttons to switch between different property panels
/// - A close button to dismiss the panel
struct ShapesPanel: View {
    // MARK: - Properties
    
    /// Available shape options that can be selected.
    /// Each case represents a different shape with associated icon.
    enum ShapeType: String, CaseIterable, Identifiable {
        case circle, square, triangle, hexagon, star
        case rectangle, oval, diamond, pentagon, octagon
        case arrow, rhombus, parallelogram, trapezoid
        
        /// Unique identifier for each shape type
        var id: String { self.rawValue }
        
        /// SF Symbol icon name associated with each shape type
        var icon: String {
            switch self {
            case .circle: return "circle.fill"
            case .square: return "square.fill"
            case .triangle: return "triangle.fill"
            case .hexagon: return "hexagon.fill"
            case .star: return "star.fill"
            case .rectangle: return "rectangle.fill"
            case .oval: return "oval.fill"
            case .diamond: return "diamond.fill"
            case .pentagon: return "pentagon.fill"
            case .octagon: return "octagon.fill"
            case .arrow: return "arrow.up.circle.fill"
            case .rhombus: return "rhombus.fill"
            case .parallelogram: return "rectangle.portrait.fill"
            case .trapezoid: return "trapezoid.and.line.vertical.fill"
            }
        }
    }
    
    /// Currently selected shape type, bound to parent view
    @Binding var selectedShape: ShapeType
    
    /// Controls visibility of the panel, bound to parent view
    @Binding var isShowing: Bool
    
    /// Callback function to switch to the Properties panel
    var onSwitchToProperties: () -> Void
    
    /// Callback function to switch to the Color Properties panel
    var onSwitchToColorProperties: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Header section with navigation buttons and close control
            panelHeader()
            
            // Main content area
            VStack(spacing: 16) {
                Text("Choose a Shape")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 16)
                
                // Shape selection grid in scrollable area
                ScrollView {
                    // Create a 4-column grid layout for shape buttons
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 12) {
                        ForEach(ShapeType.allCases) { shape in
                            shapeButton(shape)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: UIScreen.main.bounds.height / 3) // Panel takes up one-third of screen height
        .background(Color(.systemBackground))
        .cornerRadius(15, corners: [.topLeft, .topRight])
        .shadow(radius: 10)
    }
    
    // MARK: - UI Components
    
    /// Creates the header section of the panel containing navigation buttons and close control.
    /// The header includes:
    /// - Properties panel button
    /// - Color properties panel button  
    /// - Shapes panel button (current panel)
    /// - Close button
    internal func panelHeader() -> some View {
        HStack {
            // Navigation button group
            HStack(spacing: 10) {
                makePropertiesButton()
                makeColorPropertiesButton()
                makeShapesButton()
            }
            
            Spacer()
            
            // Close button
            Image(systemName: "xmark")
                .font(.system(size: 20))
                .foregroundColor(Color(uiColor: .label))
                .accessibilityLabel("Close")
                .accessibilityIdentifier("CloseButton")
                .onTapGesture {
                    isShowing = false
                }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(Color(.systemGray5))
        .cornerRadius(8, corners: [.topLeft, .topRight])
    }
    
    /// Creates a button for an individual shape option.
    /// The button displays:
    /// - An SF Symbol icon representing the shape
    /// - The shape name below the icon
    /// - Visual feedback for selection state
    /// - Parameters:
    ///   - shape: The ShapeType to create a button for
    internal func shapeButton(_ shape: ShapeType) -> some View {
        Button(action: {
            selectedShape = shape
        }) {
            VStack {
                Image(systemName: shape.icon)
                    .font(.system(size: 32))
                    .foregroundColor(selectedShape == shape ? Color.blue : Color(uiColor: .label))
                    .frame(height: 40)
                
                Text(shape.rawValue.capitalized)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .foregroundColor(Color(uiColor: .label))
            }
            .padding(8)
            .frame(minWidth: 0, maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedShape == shape ? Color.blue.opacity(0.1) : Color(uiColor: .systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedShape == shape ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .accessibilityIdentifier("Shape_\(shape.rawValue)")
    }
    
    /// Creates a button that switches to the Properties panel.
    /// Uses a slider icon to represent properties configuration.
    internal func makePropertiesButton() -> some View {
        Button(action: {
            onSwitchToProperties()
        }) {
            Rectangle()
                .foregroundColor(Color(uiColor: .systemBackground))
                .frame(width: 60, height: 60)
                .cornerRadius(8)
                .overlay(
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 24))
                        .foregroundColor(Color(uiColor: .systemBlue))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(uiColor: .systemGray3), lineWidth: 0.5)
                )
        }
        .accessibilityIdentifier("Properties Button")
    }
    
    /// Creates a button that switches to the Color Properties panel.
    /// Uses a stacked squares icon to represent color properties.
    internal func makeColorPropertiesButton() -> some View {
        Button(action: {
            onSwitchToColorProperties()
        }) {
            Rectangle()
                .foregroundColor(Color(uiColor: .systemBackground))
                .frame(width: 60, height: 60)
                .cornerRadius(8)
                .overlay(
                    Image(systemName: "square.3.stack.3d")
                        .font(.system(size: 24))
                        .foregroundColor(Color(uiColor: .systemBlue))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(uiColor: .systemGray3), lineWidth: 0.5)
                )
        }
        .accessibilityIdentifier("Color Properties Button")
    }
    
    /// Creates a button representing the current (Shapes) panel.
    /// Uses overlapping squares icon to represent shapes selection.
    /// This button is disabled since we're already in the Shapes panel.
    internal func makeShapesButton() -> some View {
        Button(action: {
            // No action needed - we're already in this panel
        }) {
            Rectangle()
                .foregroundColor(Color(uiColor: .systemBackground))
                .frame(width: 60, height: 60)
                .cornerRadius(8)
                .overlay(
                    Image(systemName: "square.on.square")
                        .font(.system(size: 24))
                        .foregroundColor(Color(uiColor: .systemBlue))
                )
                .shadow(radius: 2)
        }
        .accessibilityIdentifier("Shapes Button")
    }
}

// MARK: - Previews

/// Provides a preview of the ShapesPanel with sample data
struct ShapesPanel_Previews: PreviewProvider {
    static var previews: some View {
        ShapesPanel(
            selectedShape: .constant(.circle),
            isShowing: .constant(true),
            onSwitchToProperties: {},
            onSwitchToColorProperties: {}
        )
    }
}

// The corner radius extensions have been moved to a common location and are already defined in PropertiesPanel.swift 