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
          
           // Scrollable content area
           ScrollView {
               VStack(spacing: 16) {
                   // Toggle for default colors - styled to match property rows
                   Toggle("Toggle Default Colors", isOn: Binding(
                       get: { ColorPresetManager.shared.useDefaultRainbowColors },
                       set: { newValue in
                           ColorPresetManager.shared.useDefaultRainbowColors = newValue
                           // Always set to dynamic style (index 0) when toggled
                           if newValue {
                               ColorPresetManager.shared.rainbowStyle = 0
                           }
                       }
                   ))
                   .padding()
                   .background(Color(uiColor: .systemGray6))
                   .cornerRadius(8)
                   .padding(.horizontal, 16)
                   .padding(.top, 16)
                  
                   // Content area - displays either ShapesSection or ColorSelectionPanel based on selected tab
                   if selectedTab == 0 {
                       // Shapes tab content - without outer ScrollView since we're already in one
                       ShapesSectionContent()
                           .padding(.horizontal, 16)
                   } else {
                       // Colors tab content
                       ColorSelectionPanel(selectedColor: $selectedColor)
                           .padding(.horizontal, 16)
                           .onAppear {
                               // Initialize selected color with the first preset if available
                               let presetManager = ColorPresetManager.shared
                               if !presetManager.colorPresets.isEmpty {
                                   selectedColor = presetManager.colorPresets[0]
                               }
                           }
                   }
               }
               .padding(.bottom, 16)
           }
          
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
           Text("Properties").tag(0)
           Text("Custom Colors").tag(1)
       }
       .pickerStyle(SegmentedPickerStyle())
       .padding(.horizontal, 20)
       .padding(.vertical, 10)
       .frame(maxWidth: .infinity)
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


/// A view that displays shape selection options without its own ScrollView
/// This is used as part of a larger ScrollView in ColorShapesPanel
struct ShapesSectionContent: View {
   // MARK: - Properties
  
   /// Reference to the shared color preset manager
   @ObservedObject private var colorManager = ColorPresetManager.shared
  
   // MARK: - State Properties for UI Only
   @State private var hueText: String = "50"
   @State private var saturationText: String = "80"
   @State private var alphaText: String = "100"
   @State private var strokeWidthText: String = "2.0"
  
   init() {
       // Initialize the stroke width text field from the manager
       _strokeWidthText = State(initialValue: String(format: "%.1f", ColorPresetManager.shared.strokeWidth))
      
       // Initialize the alpha text field from the manager
       _alphaText = State(initialValue: "\(Int(ColorPresetManager.shared.shapeAlpha * 100))")
      
       // Initialize the hue text field from the manager
       _hueText = State(initialValue: "\(Int(ColorPresetManager.shared.hueAdjustment * 100))")
      
       // Initialize the saturation text field from the manager
       _saturationText = State(initialValue: "\(Int(ColorPresetManager.shared.saturationAdjustment * 100))")
   }
  
   // MARK: - Body
  
   var body: some View {
       VStack(alignment: .leading, spacing: 16) {
           // Color properties - Always visible regardless of toggle state
           VStack(spacing: 12) {
               // Hue slider
               propertyRow(title: "Hue", icon: "paintpalette") {
                   HStack {
                       Slider(value: $colorManager.hueAdjustment, in: 0...1)
                           .accessibilityIdentifier("Hue Slider")
                           .onChange(of: colorManager.hueAdjustment) { _, newValue in
                               hueText = "\(Int(newValue * 100))"
                           }
                      
                       TextField("", text: $hueText)
                           .frame(width: 50)
                           .textFieldStyle(RoundedBorderTextFieldStyle())
                           .keyboardType(.numberPad)
                           .multilineTextAlignment(.center)
                           .onChange(of: hueText) { _, newValue in
                               if let value = Double(newValue), value >= 0, value <= 100 {
                                   colorManager.hueAdjustment = value / 100
                               }
                           }
                       Text("%")
                   }
               }
              
               // Saturation slider
               propertyRow(title: "Saturation", icon: "drop") {
                   HStack {
                       Slider(value: $colorManager.saturationAdjustment, in: 0...1)
                           .accessibilityIdentifier("Saturation Slider")
                           .onChange(of: colorManager.saturationAdjustment) { _, newValue in
                               saturationText = "\(Int(newValue * 100))"
                           }
                      
                       TextField("", text: $saturationText)
                           .frame(width: 50)
                           .textFieldStyle(RoundedBorderTextFieldStyle())
                           .keyboardType(.numberPad)
                           .multilineTextAlignment(.center)
                           .onChange(of: saturationText) { _, newValue in
                               if let value = Double(newValue), value >= 0, value <= 100 {
                                   colorManager.saturationAdjustment = value / 100
                               }
                           }
                       Text("%")
                   }
               }
              
               // Alpha slider
               propertyRow(title: "Alpha", icon: "slider.horizontal.below.rectangle") {
                   HStack {
                       Slider(value: $colorManager.shapeAlpha, in: 0...1)
                           .accessibilityIdentifier("Alpha Slider")
                           .onChange(of: colorManager.shapeAlpha) { _, newValue in
                               alphaText = "\(Int(newValue * 100))"
                           }
                      
                       TextField("", text: $alphaText)
                           .frame(width: 50)
                           .textFieldStyle(RoundedBorderTextFieldStyle())
                           .keyboardType(.numberPad)
                           .multilineTextAlignment(.center)
                           .onChange(of: alphaText) { _, newValue in
                               if let value = Double(newValue), value >= 0, value <= 100 {
                                   colorManager.shapeAlpha = value / 100
                               }
                           }
                       Text("%")
                   }
               }
              
               // Stroke Color (just UI with a ColorPicker)
               propertyRow(title: "Stroke Color", icon: "pencil.circle") {
                   HStack {
                       ColorPicker("", selection: $colorManager.strokeColor)
                           .labelsHidden()
                       Spacer()
                   }
               }
              
               // Stroke Width slider
               propertyRow(title: "Stroke Width", icon: "scribble") {
                   HStack {
                       Slider(value: $colorManager.strokeWidth, in: 0...10, step: 0.5)
                           .accessibilityIdentifier("Stroke Width Slider")
                           .onChange(of: colorManager.strokeWidth) { _, newValue in
                               strokeWidthText = String(format: "%.1f", newValue)
                           }
                      
                       TextField("", text: $strokeWidthText)
                           .frame(width: 50)
                           .textFieldStyle(RoundedBorderTextFieldStyle())
                           .keyboardType(.decimalPad)
                           .multilineTextAlignment(.center)
                           .onChange(of: strokeWidthText) { _, newValue in
                               if let value = Double(newValue), value >= 0, value <= 10 {
                                   colorManager.strokeWidth = value
                               }
                           }
                       Text("pt")
                   }
               }
              
               // Background Color (just UI with a ColorPicker)
               propertyRow(title: "Background Color", icon: "rectangle.fill") {
                   HStack {
                       ColorPicker("", selection: $colorManager.backgroundColor)
                           .labelsHidden()
                       Spacer()
                   }
               }
           }
       }
       .padding(16)
       .background(Color(.systemBackground))
       .cornerRadius(12)
       .animation(.spring(), value: colorManager.useDefaultRainbowColors)
   }
  
   // MARK: - UI Components
  
   /// Creates a custom property control row with consistent styling
   /// - Parameters:
   ///   - title: The name of the property
   ///   - icon: SF Symbol name for the property icon
   ///   - content: The control elements (slider and text field)
   private func propertyRow<Content: View>(
       title: String,
       icon: String,
       @ViewBuilder content: () -> Content
   ) -> some View {
       VStack(alignment: .leading, spacing: 8) {
           HStack {
               Image(systemName: icon)
                   .font(.system(size: 24))
                   .foregroundColor(Color(uiColor: .label))
                   .frame(width: 40, height: 40)
                   .background(Color(uiColor: .systemGray6))
                   .cornerRadius(8)
              
               Text(title)
                   .font(.headline)
                   .foregroundColor(Color(uiColor: .label))
               Spacer()
           }
           content()
       }
       .padding()
       .background(Color(uiColor: .systemGray6))
       .cornerRadius(8)
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


// MARK: - Placeholder for future implementation of color/shapes section
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
