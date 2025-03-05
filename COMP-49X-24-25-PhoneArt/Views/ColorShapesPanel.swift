//
//  ColorShapesPanel.swift
//  COMP-49X-24-25-PhoneArt
//
//  Created by Emmett DeBruin on 02/27/25.
//


import SwiftUI


/// A panel that provides controls for modifying colors and shapes on the canvas.
/// Features:
/// - Tab-based interface for switching between shapes and colors
/// - Integration with ColorSelectionPanel for color management
/// - Ability to switch to PropertiesPanel for other shape properties
struct ColorShapesPanel: View {
   /// Currently selected tab (0 = Shapes, 1 = Colors)
   @State private var selectedTab = 0
   @Binding var isShowing: Bool
   @Binding var selectedColor: Color  // Add this binding
   var onSwitchToProperties: () -> Void
   
   /// Initializes the panel with bindings and callback
   /// - Parameters:
   ///   - isShowing: Controls panel visibility
   ///   - selectedColor: Binding to the color applied to shapes
   ///   - onSwitchToProperties: Callback to switch to properties panel
   init(isShowing: Binding<Bool>, selectedColor: Binding<Color>, onSwitchToProperties: @escaping () -> Void) {
       self._isShowing = isShowing
       self._selectedColor = selectedColor
       self.onSwitchToProperties = onSwitchToProperties
   }
  
   var body: some View {
       VStack(spacing: 0) {
           // Header with buttons and close button
           HStack {
               // Properties and ColorShapes buttons
               HStack(spacing: 10) {
                   makePropertiesButton()
                   makeColorShapesButton()
               }
               Spacer()
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
           
           // Tab selector
           Picker("", selection: $selectedTab) {
               Text("Shapes").tag(0)
               Text("Colors").tag(1)
           }
           .pickerStyle(SegmentedPickerStyle())
           .padding(.horizontal, 20)
           .padding(.vertical, 10)
           .frame(maxWidth: .infinity)
           
           // Content based on selected tab
           if selectedTab == 0 {
               ShapesSection()
           } else {
               ColorSelectionPanel(selectedColor: $selectedColor)
                   .padding(.horizontal)
                   .onAppear {
                       // Get the first preset from our shared ColorPresetManager
                       let presetManager = ColorPresetManager.shared
                       if !presetManager.colorPresets.isEmpty {
                           selectedColor = presetManager.colorPresets[0]
                       }
                   }
           }
           
           Spacer()
       }
       .frame(maxWidth: .infinity)
       .frame(height: UIScreen.main.bounds.height / 3)
       .background(Color(.systemBackground))
       .cornerRadius(15, corners: [.topLeft, .topRight])
       .shadow(radius: 10)
   }
  
   // MARK: - UI Components
  
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
  
   private func makePropertiesButton() -> some View {
       Button(action: {
           withAnimation(.spring()) {
               onSwitchToProperties()  // Call the switch function
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
   }
  
   private func makeColorShapesButton() -> some View {
       Button(action: {}) {
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
   }
}

struct ShapesSection: View {
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

struct ColorShapesPanel_Previews: PreviewProvider {
    static var previews: some View {
        ColorShapesPanel(
            isShowing: .constant(true),
            selectedColor: .constant(.purple),
            onSwitchToProperties: {}
        )
    }
}

// MARK: - Corner Radius Extension has been moved to UIExtensions.swift
