//
//  ColorPropertiesPanel.swift
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
struct ColorPropertiesPanel: View {
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
   
   /// Callback function to switch to the Shapes panel
   /// Executed when the user taps the Shapes button
   var onSwitchToShapes: () -> Void

   /// Callback function to switch to the Gallery panel
  var onSwitchToGallery: () -> Void
  
   // MARK: - Initialization
  
   /// Initializes the panel with bindings and callback
   /// - Parameters:
   ///   - isShowing: Controls panel visibility state
   ///   - selectedColor: Binding to the currently selected color that will be applied to shapes
   ///   - onSwitchToProperties: Callback function executed when switching to the Properties panel
   ///   - onSwitchToShapes: Callback function executed when switching to the Shapes panel
   ///   - onSwitchToGallery: Callback function executed when switching to the Gallery panel
    init(isShowing: Binding<Bool>, selectedColor: Binding<Color>, onSwitchToProperties: @escaping () -> Void, onSwitchToShapes: @escaping () -> Void, onSwitchToGallery: @escaping () -> Void) {
      self._isShowing = isShowing
      self._selectedColor = selectedColor
      self.onSwitchToProperties = onSwitchToProperties
      self.onSwitchToShapes = onSwitchToShapes
      self.onSwitchToGallery = onSwitchToGallery
    }


 
   // MARK: - Body
  
   var body: some View {
       VStack(spacing: 0) {
           // Header section with navigation buttons and close control
           panelHeader()
          
           // Title for the panel
           Text("Color & Stroke")
               .font(.title2).bold()
               .padding(.top, 10)
          
           // Tab selector for switching between Shapes and Colors
           tabSelector()
          
           // Scrollable content area
           ScrollView {
               VStack(spacing: 16) {
                   // Content area - displays either ShapesSection or ColorSelectionPanel based on selected tab
                   if selectedTab == 0 {
                       // Shapes tab content - without outer ScrollView since we're already in one
                       ShapesSectionContent()
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
       .frame(height: UIScreen.main.bounds.height / 2) // Changed height to 1/2 screen
       .background(Color(.systemBackground))
       .cornerRadius(15, corners: [.topLeft, .topRight])
       .shadow(radius: 10)
   }
 
   // MARK: - UI Components
  
   /// Creates the header section of the panel containing navigation buttons and close control
   /// - Returns: A view containing the header elements
   private func panelHeader() -> some View {
       // Panel header with evenly distributed buttons
       HStack(alignment: .center, spacing: 0) {
           Spacer() // Left margin spacer for equal distribution
           
           makePropertiesButton()
           
           Spacer() // Spacer between buttons for equal distribution
           
           makeColorPropertiesButton()
           
           Spacer() // Spacer between buttons for equal distribution
           
           makeShapesButton()

           Spacer() // Spacer between buttons for equal distribution
         
           // Add the Gallery Button
           makeGalleryButton()
           
           Spacer() // Spacer between buttons for equal distribution
           
           // Close button
           Button(action: {
               withAnimation(.easeInOut(duration: 0.25)) {
                   isShowing = false
               }
           }) {
               Rectangle()
                   .foregroundColor(Color(uiColor: .systemBackground))
                   .frame(width: 50, height: 50)
                   .cornerRadius(8)
                   .overlay(
                       Image(systemName: "xmark")
                           .font(.system(size: 22))
                           .foregroundColor(Color(uiColor: .systemBlue))
                   )
                   .overlay(
                       RoundedRectangle(cornerRadius: 8)
                           .stroke(Color(uiColor: .systemGray3), lineWidth: 0.5)
                   )
           }
           .accessibilityLabel("Close")
           .accessibilityIdentifier("CloseButton")
           
           Spacer() // Right margin spacer for equal distribution
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
  
   /// Creates a button that switches to the Properties panel
   private func makePropertiesButton() -> some View {
       Button(action: {
           onSwitchToProperties()
       }) {
           Rectangle()
               .foregroundColor(Color(uiColor: .systemBackground))
               .frame(width: 50, height: 50)
               .cornerRadius(8)
               .overlay(
                   Image(systemName: "slider.horizontal.3")
                       .font(.system(size: 22))
                       .foregroundColor(Color(uiColor: .systemBlue))
               )
               .overlay(
                   RoundedRectangle(cornerRadius: 8)
                       .stroke(Color(uiColor: .systemGray3), lineWidth: 0.5)
               )
       }
       .accessibilityIdentifier("Properties Button")
   }
   
   /// Creates a button for the current (Color Properties) panel
   private func makeColorPropertiesButton() -> some View {
       Button(action: {
           // No action needed - we're already in this panel
       }) {
           Rectangle()
               .foregroundColor(Color(uiColor: .systemBackground))
               .frame(width: 50, height: 50)
               .cornerRadius(8)
               .overlay(
                   Image(systemName: "square.3.stack.3d")
                       .font(.system(size: 22))
                       .foregroundColor(Color(uiColor: .systemBlue))
               )
               .shadow(radius: 2)
       }
       .accessibilityIdentifier("Color Properties Button")
   }
   
   /// Creates a button that switches to the Shapes panel
   private func makeShapesButton() -> some View {
       Button(action: {
           onSwitchToShapes()
       }) {
           Rectangle()
               .foregroundColor(Color(uiColor: .systemBackground))
               .frame(width: 50, height: 50)
               .cornerRadius(8)
               .overlay(
                   Image(systemName: "square.on.square")
                       .font(.system(size: 22))
                       .foregroundColor(Color(uiColor: .systemBlue))
               )
               .overlay(
                   RoundedRectangle(cornerRadius: 8)
                       .stroke(Color(uiColor: .systemGray3), lineWidth: 0.5)
               )
       }
       .accessibilityIdentifier("Shapes Button")
   }

   /// Creates a button for the Gallery (placeholder).
   internal func makeGalleryButton() -> some View {
       Button(action: {
           onSwitchToGallery() // Call the gallery switch callback
       }) {
           Rectangle()
               .foregroundColor(Color(uiColor: .systemBackground))
               .frame(width: 50, height: 50) // Set size
               .cornerRadius(8)
               .overlay(
                   Image(systemName: "photo.on.rectangle.angled")
                       .font(.system(size: 22)) // Set size
                       .foregroundColor(Color(uiColor: .systemBlue))
               )
               .overlay(
                   RoundedRectangle(cornerRadius: 8)
                       .stroke(Color(uiColor: .systemGray3), lineWidth: 0.5)
               )
       }
       .accessibilityIdentifier("Gallery Button")
   }
}


/// A view that displays shape selection options without its own ScrollView
/// This is used as part of a larger ScrollView in ColorPropertiesPanel
struct ShapesSectionContent: View {
   // MARK: - Properties
  
   /// Reference to the shared color preset manager
   @ObservedObject private var colorManager = ColorPresetManager.shared
  
   // MARK: - State Properties for UI Only
   @State private var hueText: String = "50"
   @State private var saturationText: String = "80"
   @State private var alphaText: String = "100"
   @State private var strokeWidthText: String = "2.0"
   
   // MARK: - Tooltip State
   @State private var showingTooltip: Bool = false
   @State private var tooltipText: String = ""
   @State private var activeTooltipIdentifier: String? = nil // To identify which button triggered the tooltip
  
   // MARK: - Tooltip Descriptions
   // Dictionary mapping property title to its description for the tooltip
   private let tooltipDescriptions: [String: String] = [
       "Hue": "Adjusts the overall color tone of rainbow-generated patterns.",
       "Saturation": "Controls the intensity or vividness of colors in the artwork.",
       "Alpha": "Adjusts the transparency level of the shapes in your artwork.",
       "Stroke Color": "Sets the color of the outline drawn around shapes.",
       "Stroke Width": "Sets the thickness of the outline around shapes.",
       "Background Color": "Changes the background color of the entire canvas."
   ]
  
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
           // Toggle for default colors - moved from the Colors tab to the Properties tab
           VStack(alignment: .leading, spacing: 0) {
               // Combined row with icon, text and toggle
               HStack {
                   Image(systemName: "wand.and.stars")
                       .foregroundColor(.blue)
                       .font(.system(size: 18))
                       .frame(width: 24)
                   
                   Text("Toggle Default Colors")
                       .font(.headline)
                   
                   Spacer() // Push the toggle to the right
                   
                   Toggle("", isOn: Binding(
                       get: { ColorPresetManager.shared.useDefaultRainbowColors },
                       set: { newValue in
                           ColorPresetManager.shared.useDefaultRainbowColors = newValue
                           // Always set to dynamic style (index 0) when toggled
                           if newValue {
                               ColorPresetManager.shared.rainbowStyle = 0
                           }
                       }
                   ))
                   .labelsHidden()
                   .frame(width: 51) // Set a fixed width to match iOS standard toggle
               }
               .padding(.vertical, 10) // Add vertical padding to match the height of other controls
           }
           .padding(.vertical, 12)
           .padding(.horizontal, 16)
           .background(Color(uiColor: .systemGray6))
           .cornerRadius(8)
           
           // Color properties - Always visible regardless of toggle state
           VStack(spacing: 12) {
               // Hue slider - only visible when default rainbow colors are enabled
               if colorManager.useDefaultRainbowColors {
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
               }
              
               // Saturation slider - always visible
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
                       Spacer() // Moved Spacer before ColorPicker
                       ColorPicker("", selection: $colorManager.strokeColor)
                           .labelsHidden()
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
                       Spacer() // Moved Spacer before ColorPicker
                       ColorPicker("", selection: $colorManager.backgroundColor)
                           .labelsHidden()
                   }
               }
           }
       }
       .padding(16)
       .background(Color(.systemBackground))
       .cornerRadius(12)
       .animation(.easeInOut(duration: 0.25), value: colorManager.useDefaultRainbowColors)
       .simultaneousGesture(
           TapGesture()
               .onEnded { _ in
                   if showingTooltip {
                       withAnimation(.easeOut(duration: 0.2)) {
                           showingTooltip = false
                           activeTooltipIdentifier = nil
                       }
                   }
               }
       )
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
       let tooltipIdentifier = title // Use title as a unique identifier for the tooltip

       return ZStack(alignment: .topLeading) { // Use ZStack for tooltip overlay
           // Main Row Content - Changed to HStack
           HStack { // Changed from VStack
               Image(systemName: icon)
                   .font(.system(size: 20))
                   .foregroundColor(.secondary)
                   .frame(width: 20)
               
               Text(title)
                   .font(.headline)
               
               // Info Button for Tooltip
               Button {
                   // Set the text and identifier for the tooltip
                   tooltipText = tooltipDescriptions[title] ?? "No description available."
                   activeTooltipIdentifier = tooltipIdentifier
                   withAnimation { // Animate showing
                       showingTooltip = true // Show the overlay
                   }
               } label: {
                   Image(systemName: "info.circle")
                       .foregroundColor(.blue)
               }
               .accessibilityLabel("\(title) Info")
               .accessibilityIdentifier("\(title)InfoButton")
               
               // Content now directly in HStack
               content()
                   .frame(maxWidth: .infinity) // Allow content to expand
           }
           .padding()
           .background(Color(uiColor: .systemGray6))
           .cornerRadius(8)
           
           // Tooltip overlay - only shown when this specific tooltip is active
           if showingTooltip && activeTooltipIdentifier == tooltipIdentifier {
               // Use GeometryReader to get container width for centering
               GeometryReader { geometry in
                   // Combined tooltip with single background
                   ZStack(alignment: .topTrailing) {
                       SharedTooltipView(text: tooltipText)
                           .padding(.horizontal, 16)
                           .padding(.vertical, 12)
                           .padding(.trailing, 30) // More room for the X button with larger text
                       
                       // X button - now directly in ZStack for better positioning
                       Button {
                           withAnimation(.easeOut(duration: 0.2)) {
                               showingTooltip = false
                               activeTooltipIdentifier = nil
                           }
                       } label: {
                           Image(systemName: "xmark.circle.fill")
                               .font(.system(size: 20)) // Larger X button
                               .foregroundColor(.white)
                               .padding(4)
                       }
                       .accessibility(label: Text("Close tooltip"))
                   }
                   .background(Color(UIColor.systemGray2))
                   .cornerRadius(8)
                   .shadow(radius: 2)
                   // Explicitly prevent tap-through with a high-priority gesture
                   .gesture(
                       TapGesture()
                           .onEnded { _ in
                               // Do nothing, but consume the event
                           }
                       , including: .all) // Higher priority than the ScrollView's gesture
                   // Center horizontally, position above the row
                   .position(
                       x: geometry.size.width / 2,
                       y: 10 // Position tooltip near top of the row
                   )
                   .transition(.opacity.combined(with: .scale))
                   .zIndex(1) // Ensure tooltip appears above other content
               }
           }
       }
   }
}


// MARK: - Testing Extensions

/// Extension providing test access to ShapesSectionContent properties
extension ShapesSectionContent {
    /// Test access to hue text field value
    var testHueText: String {
        get { hueText }
        set { hueText = newValue }
    }
    
    /// Test access to saturation text field value
    var testSaturationText: String {
        get { saturationText }
        set { saturationText = newValue }
    }
    
    /// Test access to alpha text field value
    var testAlphaText: String {
        get { alphaText }
        set { alphaText = newValue }
    }
    
    /// Test access to stroke width text field value
    var testStrokeWidthText: String {
        get { strokeWidthText }
        set { strokeWidthText = newValue }
    }
}

/// Extension providing test access to ColorPropertiesPanel properties
extension ColorPropertiesPanel {
    /// Test access to selected tab
    var testSelectedTab: Int {
        get { selectedTab }
        set { selectedTab = newValue }
    }
}


// MARK: - Previews


/// Preview provider for ColorPropertiesPanel
struct ColorPropertiesPanel_Previews: PreviewProvider {
   static var previews: some View {
       ColorPropertiesPanel(
           isShowing: .constant(true),
           selectedColor: .constant(.purple),
           onSwitchToProperties: {},
           onSwitchToShapes: {},
           onSwitchToGallery: {}
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