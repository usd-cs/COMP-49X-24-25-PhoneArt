//
//  PropertiesPanel.swift
//  COMP-49X-24-25-PhoneArt
//
//  Created by Zachary Letcher on 12/08/24.
//








import SwiftUI








/// A panel that provides controls for modifying shape properties on the canvas.
/// This panel includes sliders and text inputs for precise control over:
/// - Rotation (0-360 degrees)
/// - Scale (0.5x-2.0x)
/// - Layer count (0-360)
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
 var onSwitchToColorShapes: () -> Void  // Callback for switching to Color panel
 var onSwitchToShapes: () -> Void       // Callback for switching to Shapes panel
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
  var body: some View {
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
            
             // Close button
             Button(action: {
                 withAnimation(.easeInOut(duration: 0.25)) {
                     isShowing = false
                 }
             }) {
                 Rectangle()
                     .foregroundColor(Color(uiColor: .systemBackground))
                     .frame(width: 60, height: 60)
                     .cornerRadius(8)
                     .overlay(
                         Image(systemName: "xmark")
                             .font(.system(size: 24))
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
             .toolbar {
                 ToolbarItem(placement: .keyboard) {
                     Button("Done") {
                         hideKeyboard()
                     }
                 }
             }
         }
         .background(Color(uiColor: .systemBackground))
     }
     .frame(maxWidth: .infinity)
     .frame(height: UIScreen.main.bounds.height / 3)
     .background(Color(uiColor: .systemBackground))
     .cornerRadius(15, corners: [.topLeft, .topRight])
     .shadow(radius: 10)
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
          
             TextField("", text: $primitiveText)
                 .frame(width: 50)
                 .textFieldStyle(RoundedBorderTextFieldStyle())
                 .keyboardType(.numberPad)
                 .multilineTextAlignment(.center)
                 .onChange(of: primitiveText) { _, newValue in
                     if let value = Double(newValue), value >= 1, value <= 6 {
                         primitive = value
                     }
                 }
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
          
             TextField("", text: $rotationText)
                 .frame(width: 50)
                 .textFieldStyle(RoundedBorderTextFieldStyle())
                 .keyboardType(.numberPad)
                 .multilineTextAlignment(.center)
                 .onChange(of: rotationText) { _, newValue in
                     if let value = Double(newValue), value >= 0, value <= 360 {
                         rotation = value
                     }
                 }
             Text("°")
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
          
             TextField("", text: $scaleText)
                 .frame(width: 50)
                 .textFieldStyle(RoundedBorderTextFieldStyle())
                 .keyboardType(.decimalPad)
                 .multilineTextAlignment(.center)
                 .onChange(of: scaleText) { _, newValue in
                     if let value = Double(newValue), value >= 0.5, value <= 2.0 {
                         scale = value
                     }
                 }
             Text("x")
         }
     }
 }
  /// Creates a row for controlling layer count
 private func layerPropertyRow() -> some View {
     propertyRow(title: "Layer", icon: "square.3.stack.3d") {
         HStack {
             Slider(value: $layer, in: 0...360)
                 .accessibilityIdentifier("Layer Slider")
                 .onChange(of: layer) { _, newValue in
                     layerText = "\(Int(newValue))"
                 }
          
             TextField("", text: $layerText)
                 .frame(width: 50)
                 .textFieldStyle(RoundedBorderTextFieldStyle())
                 .keyboardType(.numberPad)
                 .multilineTextAlignment(.center)
                 .onChange(of: layerText) { _, newValue in
                     if let value = Double(newValue), value >= 0, value <= 360 {
                         layer = value
                     }
                 }
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
          
             TextField("", text: $skewXText)
                 .frame(width: 50)
                 .textFieldStyle(RoundedBorderTextFieldStyle())
                 .keyboardType(.numberPad)
                 .multilineTextAlignment(.center)
                 .onChange(of: skewXText) { _, newValue in
                     if let value = Double(newValue), value >= 0, value <= 80 {
                         skewX = value
                     }
                 }
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
          
             TextField("", text: $skewYText)
                 .frame(width: 50)
                 .textFieldStyle(RoundedBorderTextFieldStyle())
                 .keyboardType(.numberPad)
                 .multilineTextAlignment(.center)
                 .onChange(of: skewYText) { _, newValue in
                     if let value = Double(newValue), value >= 0, value <= 80 {
                         skewY = value
                     }
                 }
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
          
             TextField("", text: $spreadText)
                 .frame(width: 50)
                 .textFieldStyle(RoundedBorderTextFieldStyle())
                 .keyboardType(.numberPad)
                 .multilineTextAlignment(.center)
                 .onChange(of: spreadText) { _, newValue in
                     if let value = Double(newValue), value >= 0, value <= 100 {
                         spread = value
                     }
                 }
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
          
             TextField("", text: $horizontalText)
                 .frame(width: 50)
                 .textFieldStyle(RoundedBorderTextFieldStyle())
                 .keyboardType(.numberPad)
                 .multilineTextAlignment(.center)
                 .onChange(of: horizontalText) { _, newValue in
                     if let value = Double(newValue), value >= -300, value <= 300 {
                         horizontal = value
                     }
                 }
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
          
             TextField("", text: $verticalText)
                 .frame(width: 50)
                 .textFieldStyle(RoundedBorderTextFieldStyle())
                 .keyboardType(.numberPad)
                 .multilineTextAlignment(.center)
                 .onChange(of: verticalText) { _, newValue in
                     if let value = Double(newValue), value >= -300, value <= 300 {
                         vertical = value
                     }
                 }
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
  /// Creates the current (Properties) button
   private func makePropertiesButton() -> some View {
       Button(action: {
           // No action needed - we're already in this panel
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
   }
  
   /// Creates a button that switches to the Color Properties panel
   private func makeAlternatePropertiesButton() -> some View {
       Button(action: {
           onSwitchToColorShapes()
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
  
   /// Creates a button that switches to the Shapes panel
   private func makeShapesButton() -> some View {
       Button(action: {
           onSwitchToShapes()
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
               .overlay(
                   RoundedRectangle(cornerRadius: 8)
                       .stroke(Color(uiColor: .systemGray3), lineWidth: 0.5)
               )
       }
       .accessibilityIdentifier("Shapes Button")
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
 init(rotation: Binding<Double>, scale: Binding<Double>, layer: Binding<Double>, skewX: Binding<Double>, skewY: Binding<Double>,
      spread: Binding<Double>, horizontal: Binding<Double>, vertical: Binding<Double>, primitive: Binding<Double>, isShowing: Binding<Bool>,
      onSwitchToColorShapes: @escaping () -> Void, onSwitchToShapes: @escaping () -> Void) {
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
           onSwitchToShapes: {}
       )
   }
}
