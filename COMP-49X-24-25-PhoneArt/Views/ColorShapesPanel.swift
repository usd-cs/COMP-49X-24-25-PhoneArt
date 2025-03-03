//
//  ColorShapesPanel.swift
//  COMP-49X-24-25-PhoneArt
//
//  Created by Emmett DeBruin on 02/27/25.
//


import SwiftUI


/// A panel that provides controls for modifying colors and shapes on the canvas.
struct ColorShapesPanel: View {
   @State private var selectedTab = 0
   @Binding var isShowing: Bool
   @Binding var selectedColor: Color  // Add this binding
   var onSwitchToProperties: () -> Void
   
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
               Button(action: {
                   withAnimation(.spring()) {
                       isShowing = false
                   }
               }) {
                   Image(systemName: "xmark")
                       .foregroundColor(.primary)
               }
           }
           .padding()
           .background(Color(.systemGray6))
           
           // Tab selector
           Picker("", selection: $selectedTab) {
               Text("Shapes").tag(0)
               Text("Colors").tag(1)
           }
           .pickerStyle(SegmentedPickerStyle())
           .padding()
           
           // Content based on selected tab
           if selectedTab == 0 {
               ShapesSection()
           } else {
               ColorSelectionPanel(selectedColor: $selectedColor)
           }
           
           Spacer()
       }
       .frame(maxWidth: .infinity)
       .frame(height: UIScreen.main.bounds.height / 2.5)
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
