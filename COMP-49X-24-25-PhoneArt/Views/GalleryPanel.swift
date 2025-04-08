//
//  GalleryPanel.swift
//  COMP-49X-24-25-PhoneArt
//
//  Created by Emmett de Bruin on 2025-04-08.
//


import SwiftUI


struct GalleryPanel: View {
   // MARK: - Properties
   @Binding var isShowing: Bool
  
   // Callbacks for switching panels
   var onSwitchToProperties: () -> Void
   var onSwitchToColorShapes: () -> Void
   var onSwitchToShapes: () -> Void
  
   // MARK: - Body
   var body: some View {
       VStack(spacing: 0) {
           // Header section with navigation buttons and close control
           panelHeader()
          
           // Main content area (Placeholder)
           ScrollView {
               VStack {
                   Text("Artwork Gallery")
                       .font(.title2).bold()
                       .padding(.top)
                  
                   Text("Saved artwork will appear here.")
                       .foregroundColor(.secondary)
                       .padding()
                  
                   // TODO: Add gallery content (e.g., grid of artwork previews)
                   Spacer()
               }
               .frame(maxWidth: .infinity, maxHeight: .infinity)
           }
       }
       .frame(maxWidth: .infinity)
       .frame(height: UIScreen.main.bounds.height / 3) // Panel takes up one-third of screen height
       .background(Color(.systemBackground))
       .cornerRadius(15, corners: [.topLeft, .topRight])
       .shadow(radius: 10)
   }
  
   // MARK: - UI Components (Panel Header)
  
   /// Creates the header section of the panel containing navigation buttons and close control.
   private func panelHeader() -> some View {
       HStack(alignment: .center, spacing: 0) {
           Spacer() // Left margin spacer for equal distribution
          
           makePropertiesButton()
          
           Spacer() // Spacer between buttons
          
           makeColorShapesButton()
          
           Spacer() // Spacer between buttons
          
           makeShapesButton()
          
           Spacer() // Spacer between buttons
          
           makeGalleryButton() // Current panel button
          
           Spacer() // Spacer between buttons
          
           // Close button
           Button(action: {
               withAnimation(.easeInOut(duration: 0.25)) {
                   isShowing = false
               }
           }) {
               buttonContent(icon: "xmark", isActive: false)
           }
           .accessibilityLabel("Close")
           .accessibilityIdentifier("CloseButton")
          
           Spacer() // Right margin spacer
       }
       .padding(.horizontal)
       .padding(.vertical, 4)
       .background(Color(.systemGray5))
       .cornerRadius(8, corners: [.topLeft, .topRight])
   }
  
   // MARK: - Header Button Creation Helpers
  
   /// Generic button content view
   @ViewBuilder
   private func buttonContent(icon: String, isActive: Bool) -> some View {
       Rectangle()
           .foregroundColor(Color(uiColor: .systemBackground))
           .frame(width: 50, height: 50)
           .cornerRadius(8)
           .overlay(
               Image(systemName: icon)
                   .font(.system(size: 22))
                   .foregroundColor(Color(uiColor: .systemBlue))
           )
           .overlay(
               RoundedRectangle(cornerRadius: 8)
                   .stroke(isActive ? Color.clear : Color(uiColor: .systemGray3), lineWidth: 0.5) // Border only if not active
           )
           .shadow(radius: isActive ? 2 : 0) // Shadow only if active
   }
  
   /// Creates a button that switches to the Properties panel.
   private func makePropertiesButton() -> some View {
       Button(action: onSwitchToProperties) {
           buttonContent(icon: "slider.horizontal.3", isActive: false)
       }
       .accessibilityIdentifier("Properties Button")
   }
  
   /// Creates a button that switches to the Color Shapes panel.
   private func makeColorShapesButton() -> some View {
       Button(action: onSwitchToColorShapes) {
           buttonContent(icon: "square.3.stack.3d", isActive: false)
       }
       .accessibilityIdentifier("Color Shapes Button")
   }
  
   /// Creates a button that switches to the Shapes panel.
   private func makeShapesButton() -> some View {
       Button(action: onSwitchToShapes) {
           buttonContent(icon: "square.on.square", isActive: false)
       }
       .accessibilityIdentifier("Shapes Button")
   }


   /// Creates a button representing the current (Gallery) panel.
   private func makeGalleryButton() -> some View {
       Button(action: {
           // No action needed - we're already in this panel
       }) {
           buttonContent(icon: "photo.on.rectangle.angled", isActive: true) // Active state
       }
       .accessibilityIdentifier("Gallery Button")
   }
}


// MARK: - Preview
#Preview {
   GalleryPanel(
       isShowing: .constant(true),
       onSwitchToProperties: { print("Switch to Properties") },
       onSwitchToColorShapes: { print("Switch to Color/Shapes") },
       onSwitchToShapes: { print("Switch to Shapes") }
   )
}