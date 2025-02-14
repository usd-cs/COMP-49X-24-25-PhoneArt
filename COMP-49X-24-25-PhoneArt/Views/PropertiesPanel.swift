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
struct PropertiesPanel: View {
   // MARK: - Properties
   
   @Binding var rotation: Double
   @Binding var scale: Double
   @Binding var layer: Double
   @Binding var skewX: Double
   @Binding var skewY: Double
   @Binding var spread: Double
   @Binding var isShowing: Bool
   
   // Text field state
   @State private var rotationText: String
   @State private var scaleText: String
   @State private var layerText: String
   @State private var skewXText: String
   @State private var skewYText: String
   @State private var spreadText: String
   
   private let numberFormatter: NumberFormatter = {
       let formatter = NumberFormatter()
       formatter.numberStyle = .decimal
       formatter.minimumFractionDigits = 0
       formatter.maximumFractionDigits = 1
       return formatter
   }()
   
   var body: some View {
       VStack(spacing: 0) {
           HStack(spacing: 20) {
               makePropertiesButton()
               Spacer()
               Image(systemName: "xmark")
                   .font(.system(size: 20))
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
           .background(Color(UIColor.systemGray5))
           .cornerRadius(8, corners: [.topLeft, .topRight])
           
           ScrollView {
               VStack(spacing: 12) {
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
                                .onChange(of: skewXText) { _, newValue in
                                    if let value = Double(newValue), value >= 0, value <= 360 {
                                        spread = value
                                    }
                                }
                        }
                    }
                   
                   
               }
               .padding()
           }
           .background(Color(UIColor.systemBackground))
       }
       .frame(maxWidth: .infinity)
       .frame(height: UIScreen.main.bounds.height / 3)
       .background(Color(UIColor.systemBackground))
       .cornerRadius(15, corners: [.topLeft, .topRight])
       .shadow(radius: 10)
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
                   .frame(width: 40, height: 40)
                   .background(Color(UIColor.systemGray6))
                   .cornerRadius(8)
               
               Text(title)
                   .font(.headline)
               Spacer()
           }
           content()
       }
       .padding()
       .background(Color(UIColor.systemGray6))
       .cornerRadius(8)
   }
   
   /// Creates a button that toggles the properties panel visibility
   private func makePropertiesButton() -> some View {
       Button(action: {
           withAnimation(.spring()) {
               isShowing.toggle()
           }
       }) {
           VStack {
               Rectangle()
                   .foregroundColor(.white)
                   .frame(width: 60, height: 60)
                   .cornerRadius(8)
                   .overlay(
                       Image(systemName: "slider.horizontal.3")
                           .font(.system(size: 24))
                           .foregroundColor(.blue)
                   )
                   .shadow(radius: 2)
           }
       }
       .accessibilityIdentifier("Properties Button")
   }
   
   // MARK: - Initialization
   
    init(rotation: Binding<Double>, scale: Binding<Double>, layer: Binding<Double>, skewX: Binding<Double>, skewY: Binding<Double>,
         spread: Binding<Double>, isShowing: Binding<Bool>) {
       self._rotation = rotation
       self._scale = scale
       self._layer = layer
       self._skewX = skewX
       self._skewY = skewY
       self._spread = spread
       self._isShowing = isShowing
       
       // Initialize text fields with formatted values
       self._rotationText = State(initialValue: "\(Int(rotation.wrappedValue))")
       self._scaleText = State(initialValue: String(format: "%.1f", scale.wrappedValue))
       self._layerText = State(initialValue: "\(Int(layer.wrappedValue))")
       self._skewXText = State(initialValue: "\(Int(skewX.wrappedValue))")
       self._skewYText = State(initialValue: "\(Int(skewY.wrappedValue))")
       self._spreadText = State(initialValue: "\(Int(spread.wrappedValue))")
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

extension PropertiesPanel {
   // Expose text field values for testing
   var testRotationText: String {
       get { rotationText }
       set { rotationText = newValue }
   }
   
   var testScaleText: String {
       get { scaleText }
       set { scaleText = newValue }
   }
   
   var testLayerText: String {
       get { layerText }
       set { layerText = newValue }
   }
    

   var testSkewXText: String {
     get { skewXText }
     set { skewXText = newValue}
     }
    
   var testSkewYText: String {
     get { skewYText }
     set { skewYText = newValue}
     }
     
   var testSpreadText: String {
    get { spreadText }
    set { spreadText = newValue}
    }

}
