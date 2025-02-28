//
//  ColorShapesPanel.swift
//  COMP-49X-24-25-PhoneArt
//
//  Created by Emmett DeBruin on 02/27/25.
//


import SwiftUI


/// A panel that provides controls for modifying colors and shapes on the canvas.
struct ColorShapesPanel: View {
   // MARK: - Properties
  
   @Binding var isShowing: Bool
   var onSwitchToProperties: () -> Void  // Add callback for switching
  
   var body: some View {
       VStack(spacing: 0) {
           HStack(spacing: 20) {
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
           .background(Color(uiColor: .systemGray5))
           .cornerRadius(8, corners: [.topLeft, .topRight])
          
           ScrollView {
               VStack(spacing: 12) {
                   colorShapesSection()
               }
               .padding()
           }
           .background(Color(uiColor: .systemBackground))
       }
       .frame(maxWidth: .infinity)
       .frame(height: UIScreen.main.bounds.height / 2.5)
       .background(Color(uiColor: .systemBackground))
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
