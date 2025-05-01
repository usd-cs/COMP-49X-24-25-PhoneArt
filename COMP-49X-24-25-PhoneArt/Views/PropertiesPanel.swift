//
//  PropertiesPanel.swift
//  COMP-49X-24-25-PhoneArt
//
//  Created by Zachary Letcher on 12/08/24.
//

import SwiftUI
import UIKit

/// A panel that provides controls for modifying shape properties on the canvas.
/// This panel includes sliders and text inputs for precise control over:
/// - Rotation (0-360 degrees)
/// - Scale (0.5x-2.0x)
/// - Layer count (0-72)
/// - SkewX and SkewY (0-100)
/// - Spread (0-100)
/// - Horizontal position (0-300)
/// - Vertical position (0-300)
/// - Primitive type (1-5)
struct PropertiesPanel: View {
 // MARK: - Properties
  @Binding var rotation: Double
 @Binding var scale: Double
 @Binding var layer: Double
 @Binding var skewX: Double
 @Binding var skewY: Double
 @Binding var spread: Double
 @Binding var horizontal: Double
 @Binding var vertical: Double
 @Binding var primitive: Double
 @Binding var isShowing: Bool

 // Panel description text
 let panelDescription = "Customize your artwork by adjusting the Layer slider first, then explore other transformations!"
 
 // MARK: - Tooltip State
 @State private var showingTooltip: Bool = false
 @State private var tooltipText: String = ""
 @State private var activeTooltipIdentifier: String? = nil // To identify which button triggered the tooltip
 @State private var tooltipAnchor: CGPoint? = nil // Stores the desired anchor point for the tooltip

 var onSwitchToColorShapes: () -> Void  // Callback for switching to Color panel
 var onSwitchToShapes: () -> Void       // Callback for switching to Shapes panel
 var onSwitchToGallery: () -> Void     // Callback for switching to Gallery panel
  // MARK: - Text Field States
  @State private var rotationText: String
 @State private var scaleText: String
 @State private var layerText: String
 @State private var skewXText: String
 @State private var skewYText: String
 @State private var spreadText: String
 @State private var horizontalText: String
 @State private var verticalText: String
 @State private var primitiveText: String
  /// Formatter for decimal number display
 private let numberFormatter: NumberFormatter = {
     let formatter = NumberFormatter()
     formatter.numberStyle = .decimal
     formatter.minimumFractionDigits = 0
     formatter.maximumFractionDigits = 1
     return formatter
 }()
 
 // Add FocusState for keyboard management
 @FocusState private var focusedField: Field?
 enum Field: Hashable {
     case rotation, scale, layer, skewX, skewY, spread, horizontal, vertical, primitive
 }
 
 // MARK: - Tooltip Descriptions
 // Dictionary mapping property title to its description for the tooltip
 private let tooltipDescriptions: [String: String] = [
     "Primitive": "Changes the base shape used for generating patterns.",
     "Rotation": "Adjusts the angular orientation of the artwork elements.",
     "Scale": "Changes the overall size of the artwork elements.",
     "Layer": "Controls the quantity of shapes generated, increasing complexity.",
     "Skew X": "Tilts or slants the artwork horizontally.",
     "Skew Y": "Tilts or slants the artwork vertically.",
     "Spread": "Adjusts the spacing or distribution of elements.",
     "Horizontal": "Moves the entire artwork horizontally across the canvas.",
     "Vertical": "Moves the entire artwork vertically across the canvas."
 ]
 
 var body: some View {
     // Wrap everything in a ZStack to layer the accessory view
     ZStack(alignment: .bottom) {
         // Main Panel Content
         VStack(spacing: 0) {
             // Panel header with evenly distributed buttons
             HStack(alignment: .center, spacing: 0) {
                 Spacer() // Left margin spacer for equal distribution
                
                 makePropertiesButton()
                
                 Spacer() // Spacer between buttons for equal distribution
                
                 makeAlternatePropertiesButton()
                
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
             .background(Color(uiColor: .systemGray5))
             .cornerRadius(8, corners: [.topLeft, .topRight])
          
             // Title for the panel
             Text("Properties")
                 .font(.title2).bold()
                 .padding(.top, 10)
                 
             // Display the description text
             Text(panelDescription)
                 .font(.caption)
                 .multilineTextAlignment(.center)
                 .foregroundColor(.secondary)
                 .padding(.horizontal, 20)
                 .padding(.bottom, 5)
          
             ScrollView {
                 VStack(spacing: 12) {
                     primitivePropertyRow()
                     rotationPropertyRow()
                     scalePropertyRow()
                     layerPropertyRow()
                     skewXPropertyRow()
                     skewYPropertyRow()
                     spreadPropertyRow()
                     horizontalPropertyRow()
                     verticalPropertyRow()
                 }
                 .padding()
             }
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
         .frame(maxWidth: .infinity)
         .frame(height: UIScreen.main.bounds.height / 2)
         .background(Color(uiColor: .systemBackground))
         .cornerRadius(15, corners: [.topLeft, .topRight])
         .shadow(radius: 10)

         // Conditionally display the custom keyboard accessory view
         if focusedField != nil {
             KeyboardAccessoryView(focusedField: $focusedField, textBinding: currentTextBinding)
                 .transition(.move(edge: .bottom).combined(with: .opacity))
         }
     }
     .animation(.easeInOut(duration: 0.2), value: focusedField) // Animate accessory appearance
     .ignoresSafeArea(.keyboard, edges: .bottom) // Allow content to go under keyboard, accessory floats
 }

 // Computed property to get the correct text binding based on the focused field
 private var currentTextBinding: Binding<String> {
     switch focusedField {
     case .rotation: return $rotationText
     case .scale: return $scaleText
     case .layer: return $layerText
     case .skewX: return $skewXText
     case .skewY: return $skewYText
     case .spread: return $spreadText
     case .horizontal: return $horizontalText
     case .vertical: return $verticalText
     case .primitive: return $primitiveText
     case .none: return .constant("") // Default/fallback
     }
 }

 // Determine keyboard type based on focused field
 private var currentKeyboardType: UIKeyboardType {
     switch focusedField {
     case .scale: return .decimalPad
     default: return .numberPad
     }
 }
  // MARK: - Property Row Views
  /// Creates a row for controlling primitive type
 private func primitivePropertyRow() -> some View {
     propertyRow(title: "Primitive", icon: "cube.fill") {
         HStack {
             Slider(value: $primitive, in: 1...6, step: 1)
                 .accessibilityIdentifier("Primitive Slider")
                 .onChange(of: primitive) { _, newValue in
                     primitiveText = "\(Int(newValue))"
                 }
             
             // Replace TextField with CustomNumericField for Primitive
             CustomNumericField(text: $primitiveText, 
                                commitAction: { value in
                 if let doubleValue = Double(value), doubleValue >= 1, doubleValue <= 6 {
                     primitive = doubleValue
                 }
             }, keyboardType: .numberPad,
                minValue: 1, maxValue: 6, propertyName: "Primitive")
                 .frame(width: 65, height: 35)
                 .accessibilityIdentifier("Primitive TextField")
         }
     }
 }
  /// Creates a row for controlling rotation
 private func rotationPropertyRow() -> some View {
     propertyRow(title: "Rotation", icon: "rotate.right") {
         HStack {
             Slider(value: $rotation, in: 0...360)
                 .accessibilityIdentifier("Rotation Slider")
                 .onChange(of: rotation) { _, newValue in
                     rotationText = "\(Int(newValue))"
                 }
             
             // Replace TextField with CustomNumericField for Rotation
             CustomNumericField(text: $rotationText, 
                              commitAction: { value in
                 if let doubleValue = Double(value), doubleValue >= 0, doubleValue <= 360 {
                     rotation = doubleValue
                 }
             }, keyboardType: .numberPad,
                minValue: 0, maxValue: 360, propertyName: "Rotation")
                 .frame(width: 65, height: 35)
                 .accessibilityIdentifier("Rotation TextField")
         }
     }
 }
  /// Creates a row for controlling scale
 private func scalePropertyRow() -> some View {
     propertyRow(title: "Scale", icon: "arrow.up.left.and.arrow.down.right") {
         HStack {
             Slider(value: $scale, in: 0.5...2.0)
                 .accessibilityIdentifier("Scale Slider")
                 .onChange(of: scale) { _, newValue in
                     scaleText = String(format: "%.1f", newValue)
                 }
             
             // Replace TextField with CustomNumericField for Scale
             CustomNumericField(text: $scaleText, 
                              commitAction: { value in
                 if let doubleValue = Double(value), doubleValue >= 0.5, doubleValue <= 2.0 {
                     scale = doubleValue
                 }
             }, keyboardType: .decimalPad,
                minValue: 0.5, maxValue: 2.0, propertyName: "Scale")
                 .frame(width: 65, height: 35)
                 .accessibilityIdentifier("Scale TextField")
         }
     }
 }
  /// Creates a row for controlling layer count
 private func layerPropertyRow() -> some View {
     propertyRow(title: "Layer", icon: "paintpalette") {
         HStack {
             Slider(value: $layer, in: 0...72)
                 .accessibilityIdentifier("Layer Slider")
                 .onChange(of: layer) { _, newValue in
                     layerText = "\(Int(newValue))"
                 }
             
             // Replace TextField with CustomNumericField for Layer
             CustomNumericField(text: $layerText, 
                              commitAction: { value in
                 if let doubleValue = Double(value), doubleValue >= 0, doubleValue <= 72 {
                     layer = doubleValue
                 }
             }, keyboardType: .numberPad,
                minValue: 0, maxValue: 72, propertyName: "Layer")
                 .frame(width: 65, height: 35)
                 .accessibilityIdentifier("Layer TextField")
         }
     }
 }
  /// Creates a row for controlling horizontal skew
 private func skewXPropertyRow() -> some View {
     propertyRow(title: "Skew X", icon: "arrow.left.and.right") {
         HStack {
             Slider(value: $skewX, in: 0...80)
                 .accessibilityIdentifier("Skew X Slider")
                 .onChange(of: skewX) { _, newValue in
                     skewXText = "\(Int(newValue))"
                 }
             
             // Replace TextField with CustomNumericField for Skew X
             CustomNumericField(text: $skewXText, 
                              commitAction: { value in
                 if let doubleValue = Double(value), doubleValue >= 0, doubleValue <= 80 {
                     skewX = doubleValue
                 }
             }, keyboardType: .numberPad,
                minValue: 0, maxValue: 80, propertyName: "Skew X")
                 .frame(width: 65, height: 35)
                 .accessibilityIdentifier("Skew X TextField")
         }
     }
 }
  /// Creates a row for controlling vertical skew
 private func skewYPropertyRow() -> some View {
     propertyRow(title: "Skew Y", icon: "arrow.up.and.down") {
         HStack {
             Slider(value: $skewY, in: 0...80)
                 .accessibilityIdentifier("Skew Y Slider")
                 .onChange(of: skewY) { _, newValue in
                     skewYText = "\(Int(newValue))"
                 }
             
             // Replace TextField with CustomNumericField for Skew Y
             CustomNumericField(text: $skewYText, 
                              commitAction: { value in
                 if let doubleValue = Double(value), doubleValue >= 0, doubleValue <= 80 {
                     skewY = doubleValue
                 }
             }, keyboardType: .numberPad,
                minValue: 0, maxValue: 80, propertyName: "Skew Y")
                 .frame(width: 65, height: 35)
                 .accessibilityIdentifier("Skew Y TextField")
         }
     }
 }
  /// Creates a row for controlling shape spread
 private func spreadPropertyRow() -> some View {
     propertyRow(title: "Spread", icon: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left") {
         HStack {
             Slider(value: $spread, in: 0...100)
                 .accessibilityIdentifier("Spread Slider")
                 .onChange(of: spread) { _, newValue in
                     spreadText = "\(Int(newValue))"
                 }
             
             // Replace TextField with CustomNumericField for Spread
             CustomNumericField(text: $spreadText, 
                              commitAction: { value in
                 if let doubleValue = Double(value), doubleValue >= 0, doubleValue <= 100 {
                     spread = doubleValue
                 }
             }, keyboardType: .numberPad,
                minValue: 0, maxValue: 100, propertyName: "Spread")
                 .frame(width: 65, height: 35)
                 .accessibilityIdentifier("Spread TextField")
         }
     }
 }
  /// Creates a row for controlling horizontal position
 private func horizontalPropertyRow() -> some View {
     propertyRow(title: "Horizontal", icon: "arrow.left.and.right") {
         HStack {
             Slider(value: $horizontal, in: -300...300)
                 .accessibilityIdentifier("Horizontal Slider")
                 .onChange(of: horizontal) { _, newValue in
                     horizontalText = "\(Int(newValue))"
                 }
             
             // Replace TextField with CustomNumericField for Horizontal
             CustomNumericField(text: $horizontalText, 
                              commitAction: { value in
                 if let doubleValue = Double(value), doubleValue >= -300, doubleValue <= 300 {
                     horizontal = doubleValue
                 }
             }, keyboardType: .numberPad,
                minValue: -300, maxValue: 300, propertyName: "Horizontal")
                 .frame(width: 65, height: 35)
                 .accessibilityIdentifier("Horizontal TextField")
         }
     }
 }
  /// Creates a row for controlling vertical position
 private func verticalPropertyRow() -> some View {
     propertyRow(title: "Vertical", icon: "arrow.up.and.down") {
         HStack {
             Slider(value: $vertical, in: -300...300)
                 .accessibilityIdentifier("Vertical Slider")
                 .onChange(of: vertical) { _, newValue in
                     verticalText = "\(Int(newValue))"
                 }
             
             // Replace TextField with CustomNumericField for Vertical
             CustomNumericField(text: $verticalText, 
                              commitAction: { value in
                 if let doubleValue = Double(value), doubleValue >= -300, doubleValue <= 300 {
                     vertical = doubleValue
                 }
             }, keyboardType: .numberPad,
                minValue: -300, maxValue: 300, propertyName: "Vertical")
                 .frame(width: 65, height: 35)
                 .accessibilityIdentifier("Vertical TextField")
         }
     }
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
         // Main Row Content
         HStack {
             Image(systemName: icon)
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
             
             content()
                 .frame(maxWidth: .infinity)
         }
         .padding()
         .background(Color(UIColor.systemGray6))
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
  /// Creates the current (Properties) button
   private func makePropertiesButton() -> some View {
       Button(action: {
           // No action needed - we're already in this panel
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
               .shadow(radius: 2)
       }
       .accessibilityIdentifier("Properties Button")
   }
  
   /// Creates a button that switches to the Color Properties panel
   private func makeAlternatePropertiesButton() -> some View {
       Button(action: {
           onSwitchToColorShapes()
       }) {
           Rectangle()
               .foregroundColor(Color(uiColor: .systemBackground))
               .frame(width: 50, height: 50)
               .cornerRadius(8)
               .overlay(
                   Image(systemName: "paintpalette")
                       .font(.system(size: 22))
                       .foregroundColor(Color(uiColor: .systemBlue))
               )
               .overlay(
                   RoundedRectangle(cornerRadius: 8)
                       .stroke(Color(uiColor: .systemGray3), lineWidth: 0.5)
               )
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

  // MARK: - Initialization
  /// Initializes a new PropertiesPanel with the given bindings
 /// - Parameters:
 ///   - rotation: Binding for rotation value
 ///   - scale: Binding for scale value
 ///   - layer: Binding for layer count
 ///   - skewX: Binding for horizontal skew
 ///   - skewY: Binding for vertical skew
 ///   - spread: Binding for shape spread
 ///   - horizontal: Binding for horizontal position
 ///   - vertical: Binding for vertical position
 ///   - primitive: Binding for primitive type
 ///   - isShowing: Binding for panel visibility
 ///   - onSwitchToColorShapes: Callback for switching to ColorPropertiesPanel
 ///   - onSwitchToShapes: Callback for switching to Shapes panel
 ///   - onSwitchToGallery: Callback for switching to Gallery panel 
    init(rotation: Binding<Double>, scale: Binding<Double>, layer: Binding<Double>, skewX: Binding<Double>, skewY: Binding<Double>,
         spread: Binding<Double>, horizontal: Binding<Double>, vertical: Binding<Double>, primitive: Binding<Double>, isShowing: Binding<Bool>,
         onSwitchToColorShapes: @escaping () -> Void, onSwitchToShapes: @escaping () -> Void, onSwitchToGallery: @escaping () -> Void) {
     self._rotation = rotation
     self._scale = scale
     self._layer = layer
     self._skewX = skewX
     self._skewY = skewY
     self._spread = spread
     self._horizontal = horizontal
     self._vertical = vertical
     self._primitive = primitive
     self._isShowing = isShowing
     self.onSwitchToColorShapes = onSwitchToColorShapes
     self.onSwitchToShapes = onSwitchToShapes
     self.onSwitchToGallery = onSwitchToGallery
  
     // Initialize text fields with formatted values
     self._rotationText = State(initialValue: "\(Int(rotation.wrappedValue))")
     self._scaleText = State(initialValue: String(format: "%.1f", scale.wrappedValue))
     self._layerText = State(initialValue: "\(Int(layer.wrappedValue))")
     self._skewXText = State(initialValue: "\(Int(skewX.wrappedValue))")
     self._skewYText = State(initialValue: "\(Int(skewY.wrappedValue))")
     self._spreadText = State(initialValue: "\(Int(spread.wrappedValue))")
     self._horizontalText = State(initialValue: "\(Int(horizontal.wrappedValue))")
     self._verticalText = State(initialValue: "\(Int(vertical.wrappedValue))")
     self._primitiveText = State(initialValue: "\(Int(primitive.wrappedValue))")
 }
  private func hideKeyboard() {
     UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                   to: nil,
                                   from: nil,
                                   for: nil)
 }
}

// MARK: - Custom Keyboard Accessory View
struct KeyboardAccessoryView: View {
    @FocusState.Binding var focusedField: PropertiesPanel.Field? 
    @Binding var textBinding: String
    
    // Determine keyboard type based on focused field
    private var keyboardType: UIKeyboardType {
        switch focusedField {
        case .scale: return .decimalPad
        default: return .numberPad
        }
    }

    var body: some View {
        // Create a view that matches the iOS system numeric input shown in the image
        ZStack {
            // Dark background for the whole accessory view
            Color(UIColor.darkGray.withAlphaComponent(0.9))
                .edgesIgnoringSafeArea(.bottom)
            
            HStack {
                // X button on left side (actually a circle with X)
                Button(action: {
                    // Cancel action - revert to original value
                    focusedField = nil
                }) {
                    Circle()
                        .fill(Color(UIColor.darkGray))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Image(systemName: "xmark")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        )
                }
                .padding(.leading, 16)
                
                // Center-aligned text field 
                TextField("", text: $textBinding)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .keyboardType(keyboardType)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                
                // Right side buttons 
                HStack(spacing: 16) {
                    Button("Done") {
                        focusedField = nil
                    }
                    .foregroundColor(Color.blue)
                    .font(.system(size: 18, weight: .medium))
                    
                    Button("Cancel") {
                        // Cancel action - revert to original value
                        focusedField = nil
                    }
                    .foregroundColor(Color.blue)
                    .font(.system(size: 18, weight: .medium))
                }
                .padding(.trailing, 16)
            }
            .padding(.vertical, 12)
        }
        .frame(height: 52) // Fixed height to match iOS standard
    }
}

// MARK: - Corner Radius Helper

/// Adds support for applying corner radius to specific corners of a view
extension View {
 /// Applies a corner radius to specific corners
 /// - Parameters:
 ///   - radius: The radius of the rounded corners
 ///   - corners: The corners to apply the radius to
 func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
     clipShape(RoundedCorner(radius: radius, corners: corners))
 }
}

/// A shape that enables selective corner rounding
struct RoundedCorner: Shape {
 /// The radius of the rounded corners
 var radius: CGFloat = .infinity
  /// The corners to apply the radius to
 var corners: UIRectCorner = .allCorners
  /// Creates the path for the rounded rectangle
 func path(in rect: CGRect) -> Path {
     let path = UIBezierPath(
         roundedRect: rect,
         byRoundingCorners: corners,
         cornerRadii: CGSize(width: radius, height: radius)
     )
     return Path(path.cgPath)
 }
}

// MARK: - Testing Extensions

/// Extension providing test access to text field values
extension PropertiesPanel {
 /// Test access to rotation text field value
 var testRotationText: String {
     get { rotationText }
     set { rotationText = newValue }
 }
  /// Test access to scale text field value
 var testScaleText: String {
     get { scaleText }
     set { scaleText = newValue }
 }
  /// Test access to layer text field value
 var testLayerText: String {
     get { layerText }
     set { layerText = newValue }
 }
  /// Test access to skewX text field value
 var testSkewXText: String {
     get { skewXText }
     set { skewXText = newValue}
 }
  /// Test access to skewY text field value
 var testSkewYText: String {
     get { skewYText }
     set { skewYText = newValue}
 }
  /// Test access to spread text field value
 var testSpreadText: String {
     get { spreadText }
     set { spreadText = newValue}
 }
  /// Test access to horizontal text field value
 var testHorizontalText: String {
     get { horizontalText }
     set { horizontalText = newValue }
 }
  /// Test access to vertical text field value
 var testVerticalText: String {
     get { verticalText }
     set { verticalText = newValue }
 }
  /// Test access to primitive text field value
 var testPrimitiveText: String {
    get { primitiveText }
    set { primitiveText = newValue }
 }

}

// MARK: - Previews

struct PropertiesPanel_Previews: PreviewProvider {
   static var previews: some View {
       PropertiesPanel(
           rotation: .constant(0),
           scale: .constant(1.0),
           layer: .constant(1),
           skewX: .constant(0),
           skewY: .constant(0),
           spread: .constant(0),
           horizontal: .constant(0),
           vertical: .constant(0),
           primitive: .constant(1),
           isShowing: .constant(true),
           onSwitchToColorShapes: {},
           onSwitchToShapes: {},
           onSwitchToGallery: {}
       )
   }
}
