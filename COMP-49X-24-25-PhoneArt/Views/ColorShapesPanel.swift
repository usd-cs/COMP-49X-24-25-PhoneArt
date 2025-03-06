//
//  ColorShapesPanel.swift
//  COMP-49X-24-25-PhoneArt
//
//  Created by Emmett DeBruin on 02/27/25.
//


import SwiftUI


/// A panel that provides controls for modifying colors and shapes on the canvas.
/// This panel serves as a container for two distinct functionalities:
/// 1. Shape selection tools for choosing and customizing shape templates
/// 2. Color management tools for selecting, modifying, and applying colors to artwork
///
/// Features:
/// - Tab-based interface for switching between shapes and colors
/// - Integration with ColorSelectionPanel for comprehensive color management
/// - Custom UI controls for intuitive user interaction
/// - Ability to switch to PropertiesPanel for other shape properties
struct ColorShapesPanel: View {
    // MARK: - Properties
    
    /// Currently selected tab index
    /// - 0: Shapes tab
    /// - 1: Colors tab
    @State private var selectedTab = 0
    
    /// Controls visibility of the panel
    /// When false, the panel is hidden from view
    @Binding var isShowing: Bool
    
    /// The currently selected color to apply to shapes
    /// This binding is shared with parent views to maintain color state
    @Binding var selectedColor: Color
    
    /// Callback function to switch to the Properties panel
    /// Executed when the user taps the Properties button
    var onSwitchToProperties: () -> Void
    
    // MARK: - Initialization
    
    /// Initializes the panel with bindings and callback
    /// - Parameters:
    ///   - isShowing: Controls panel visibility state
    ///   - selectedColor: Binding to the currently selected color that will be applied to shapes
    ///   - onSwitchToProperties: Callback function executed when switching to the Properties panel
    init(isShowing: Binding<Bool>, selectedColor: Binding<Color>, onSwitchToProperties: @escaping () -> Void) {
        self._isShowing = isShowing
        self._selectedColor = selectedColor
        self.onSwitchToProperties = onSwitchToProperties
    }
   
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Header section with navigation buttons and close control
            panelHeader()
            
            // Tab selector for switching between Shapes and Colors
            tabSelector()
            
            // Content area - displays either ShapesSection or ColorSelectionPanel based on selected tab
            contentArea()
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: UIScreen.main.bounds.height / 3) // Panel takes up one-third of screen height
        .background(Color(.systemBackground))
        .cornerRadius(15, corners: [.topLeft, .topRight])
        .shadow(radius: 10)
    }
   
    // MARK: - UI Components
    
    /// Creates the header section of the panel containing navigation buttons and close control
    /// - Returns: A view containing the header elements
    private func panelHeader() -> some View {
        HStack {
            // Navigation button group (Properties and ColorShapes)
            HStack(spacing: 10) {
                makePropertiesButton()
                makeColorShapesButton()
            }
            
            Spacer()
            
            // Close button
            Image(systemName: "xmark")
                .font(.system(size: 20))
                .foregroundColor(Color(uiColor: .label))
                .accessibilityLabel("Close")
                .accessibilityIdentifier("CloseButton")
                .onTapGesture {
                    withAnimation(.spring()) {
                        isShowing = false
                    }
                }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(Color(.systemGray5))
        .cornerRadius(8, corners: [.topLeft, .topRight])
    }
    
    /// Creates the tab selector for switching between Shapes and Colors
    /// - Returns: A segmented control view for tab selection
    private func tabSelector() -> some View {
        Picker("", selection: $selectedTab) {
            Text("Shapes").tag(0)
            Text("Colors").tag(1)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
    }
    
    /// Creates the content area that displays either ShapesSection or ColorSelectionPanel
    /// - Returns: A view containing the content for the selected tab
    private func contentArea() -> some View {
        Group {
            if selectedTab == 0 {
                // Shapes tab content
                ShapesSection()
            } else {
                // Colors tab content
                ColorSelectionPanel(selectedColor: $selectedColor)
                    .padding(.horizontal)
                    .onAppear {
                        // Initialize selected color with the first preset if available
                        let presetManager = ColorPresetManager.shared
                        if !presetManager.colorPresets.isEmpty {
                            selectedColor = presetManager.colorPresets[0]
                        }
                    }
            }
        }
    }
   
    /// Placeholder for future implementation of the color/shapes section
    /// - Returns: A view containing placeholder content
    private func colorShapesSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Colors/Shapes")
                .font(.headline)
                .foregroundColor(Color(uiColor: .label))
                .padding(.bottom, 8)
           
            Text("Color and shape controls coming soon...")
                .foregroundColor(Color(uiColor: .secondaryLabel))
        }
        .padding()
        .background(Color(uiColor: .systemGray6))
        .cornerRadius(8)
    }
   
    /// Creates a button that switches to the Properties panel when tapped
    /// - Returns: A styled button view with the slider icon
    private func makePropertiesButton() -> some View {
        Button(action: {
            withAnimation(.spring()) {
                onSwitchToProperties()  // Execute the switch callback
            }
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
                .shadow(radius: 2)
        }
        .accessibilityIdentifier("Properties Button")
        .accessibilityLabel("Properties")
        .accessibilityHint("Switch to the properties panel")
    }
   
    /// Creates a button representing the current (ColorShapes) panel
    /// - Returns: A styled button view with the layers icon
    private func makeColorShapesButton() -> some View {
        Button(action: {
            // No action needed - we're already in this panel
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
        .accessibilityIdentifier("Color Shapes Button")
        .accessibilityLabel("Color and Shapes")
        .accessibilityHint("Currently in the color and shapes panel")
    }
}

/// A view that displays shape selection options
/// Currently a placeholder for future implementation
struct ShapesSection: View {
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Shape Selection Coming Soon...")
                    .foregroundColor(.secondary)
                    .padding()
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
}

// MARK: - Previews

/// Preview provider for ColorShapesPanel
struct ColorShapesPanel_Previews: PreviewProvider {
    static var previews: some View {
        ColorShapesPanel(
            isShowing: .constant(true),
            selectedColor: .constant(.purple),
            onSwitchToProperties: {}
        )
    }
}

// MARK: - Notes
// Corner Radius Extension has been moved to UIExtensions.swift
