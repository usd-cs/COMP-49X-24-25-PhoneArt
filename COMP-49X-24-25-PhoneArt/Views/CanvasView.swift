//
//  CanvasView.swift
//  COMP-49X-24-25-PhoneArt
//
//  Created by Aditya Prakash on 12/06/24.
//




import SwiftUI




/// A view that displays a draggable canvas with coordinate axes and a red circle.
/// The canvas can be moved around the screen and reset to its original position.
/// Features:
/// - Draggable canvas with bounce effects
/// - Coordinate system with X and Y axes
/// - Properties panel for shape manipulation
/// - Reset position functionality
struct CanvasView: View {
  // MARK: - Properties
   /// Current offset position of the canvas relative to its initial centered position
   @State private var offset = CGSize(
          width: (UIScreen.main.bounds.width - 1600) / 2,
          height: (UIScreen.main.bounds.height - 1800) / 2
      )
    
      /// Previous offset position of the canvas, used for calculating the next position during drag gestures
      @State private var lastOffset: CGSize = CGSize(
          width: (UIScreen.main.bounds.width - 1600) / 2,
          height: (UIScreen.main.bounds.height - 1800) / 2
      )
    
      /// Properties panel visibility state
      @State private var showProperties = false
    
      /// Shape transformation properties
      @State private var shapeRotation: Double = 0
      @State private var shapeScale: Double = 1.0
      @State private var shapeLayer: Double = 0
      @State private var shapeSkewX: Double = 0
      @State private var shapeSkewY: Double = 0
      @State private var shapeSpread: Double = 0
      @State private var shapeHorizontal: Double = 0
      @State private var shapeVertical: Double = 0
    
      @State private var layerCount: Double = 1 // Set default to 1
    
      /// Add zoom state property
      @State private var zoomLevel: Double = 1.0
    
      /// Add new state variable
      @State private var showColorShapes = false
    
      @State private var shapeColor: Color = .red  // Default to red
    
      private func validateLayerCount(_ count: Int) -> Int {
          max(0, min(360, count))
      }
    
      private func validateScale(_ scale: Double) -> Double {
          max(0.5, min(2.0, scale))
      }
    
      private func validateRotation(_ rotation: Double) -> Double {
          max(0.0, min(360.0, rotation))
      }
    
      private func validateSkewX(_ skewX: Double) -> Double {
          max(0.0, min(100.0, skewX))
      }
    
      private func validateSkewY(_ skewY: Double) -> Double {
          max(0.0, min(100.0, skewY))
      }
    
      private func validateSpread(_ spread: Double) -> Double {
          max(0.0, min(100.0, spread))
      }
    
      private func validateHorizontal(_ horizontal: Double) -> Double {
          max(-300.0, min(300.0, horizontal))
      }
    
      private func validateVertical(_ vertical: Double) -> Double {
          max(-300.0, min(300.0, vertical))
      }
    
      /// Computed vertical offset for the canvas when properties panel is shown
      private var canvasVerticalOffset: CGFloat {
          showProperties ? -UIScreen.main.bounds.height / 7 : 0
      }
    
      /// Computed minimum zoom level to fit canvas width to screen width
      private var minZoomLevel: Double {
          UIScreen.main.bounds.width / 1600.0
      }
    
      private func validateZoom(_ zoom: Double) -> Double {
          max(minZoomLevel, min(3.0, zoom))  // Updated to use dynamic minimum
      }
    
      // MARK: - Body
      var body: some View {
          ZStack {
              GeometryReader { geometry in
                  // Update canvas background to be dynamic
                  Color(uiColor: .systemBackground)
                      .frame(
                          width: 2400,
                          height: 2600
                      )
                      .contentShape(Rectangle())
                 
                  Canvas { context, size in
                      drawRedCircle(context: context, size: size)
                  }
                  .accessibilityIdentifier("Canvas")
                  .frame(width: 1600, height: 1800)
                  // Update border color to be dynamic
                  .border(Color(uiColor: .label), width: 2)
                  .scaleEffect(zoomLevel)
                  .gesture(
                      DragGesture()
                          .onChanged(handleDragChange)
                          .onEnded(handleDragEnd)
                  )
                  .offset(x: offset.width, y: offset.height + canvasVerticalOffset)
                  .animation(.spring(), value: showProperties)
              }
            
              VStack(spacing: 10) {
                  makeResetButton()
                      .padding(.bottom, 30)
                  makeZoomSlider()
              }
              .padding(.top, 50)
              .padding(.trailing, -20)
              .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            
              VStack {
                  Spacer()
                  HStack(spacing: 10) {
                      makePropertiesButton()
                      makeColorShapesButton()
                      Spacer()
                      if !showProperties && !showColorShapes {
                          makeCloseButton()
                      }
                  }
                  .padding(.horizontal)
                  .padding(.bottom, 20)
              }
            
              if showProperties {
                  VStack {
                      Spacer()
                      PropertiesPanel(
                          rotation: $shapeRotation,
                          scale: $shapeScale,
                          layer: $shapeLayer,
                          skewX: $shapeSkewX,
                          skewY: $shapeSkewY,
                          spread: $shapeSpread,
                          horizontal: $shapeHorizontal,
                          vertical: $shapeVertical,
                          isShowing: $showProperties,
                          onSwitchToColorShapes: {
                              showProperties = false
                              showColorShapes = true
                          }
                      )
                      .transition(.move(edge: .bottom))
                  }
                  .zIndex(3)
              }
            
              if showColorShapes {
                  VStack {
                      Spacer()
                      ColorShapesPanel(
                          isShowing: $showColorShapes,
                          selectedColor: $shapeColor,
                          onSwitchToProperties: {
                              showColorShapes = false
                              showProperties = true
                          }
                      )
                      .transition(.move(edge: .bottom))
                  }
                  .zIndex(3)
              }
          }
          .ignoresSafeArea()
      }
    
      /// Draws a red circle on the canvas above the origin point
      /// - Parameters:
      ///   - context: The graphics context to draw in
      ///   - size: The size of the canvas
      private func drawRedCircle(context: GraphicsContext, size: CGSize) {
          let circleRadius = 30.0
          let centerX = size.width/2
          let centerY = size.height/2
          let center = CGPoint(x: centerX, y: centerY)
        
          // Draw center point of the canvas
          drawCenterDot(context: context, at: center, color: .black)
        
          let numberOfLayers = max(0, min(360, Int(shapeLayer)))
          if numberOfLayers > 0 {
              drawLayers(
                  context: context,
                  layers: numberOfLayers,
                  center: center,
                  radius: circleRadius
              )
          }
      }
    
      /// Draws a small dot to indicate a center point
      /// - Parameters:
      ///   - context: The graphics context to draw in
      ///   - point: The position to draw the dot
      ///   - color: The color of the dot
      private func drawCenterDot(context: GraphicsContext, at point: CGPoint, color: Color) {
          let dotRadius = 2.0
          let dotPath = Path(ellipseIn: CGRect(
              x: point.x - dotRadius,
              y: point.y - dotRadius,
              width: dotRadius * 2,
              height: dotRadius * 2
          ))
          context.fill(dotPath, with: .color(color))
      }
    
      /// Draws multiple layers of shapes with cumulative rotation
      /// - Parameters:
      ///   - context: The graphics context to draw in
      ///   - layers: Number of layers to draw
      ///   - center: Center point for rotation
      ///   - radius: Radius of the circle
      private func drawLayers(
          context: GraphicsContext,
          layers: Int,
          center: CGPoint,
          radius: Double
      ) {
          for layerIndex in 0..<layers {
              drawSingleLayer(
                  context: context,
                  layerIndex: layerIndex,
                  center: center,
                  radius: radius
              )
          }
      }
    
      /// Draws a single layer with appropriate rotation and opacity
      /// - Parameters:
      ///   - context: The graphics context to draw in
      ///   - layerIndex: Current layer number (0 is base layer)
      ///   - center: Center point for rotation
      ///   - radius: Radius of the circle
      private func drawSingleLayer(
          context: GraphicsContext,
          layerIndex: Int,
          center: CGPoint,
          radius: Double
      ) {
          let layerContext = context
        
          // Calculate the actual angle for this layer (clockwise)
          let angleInDegrees = shapeRotation * Double(layerIndex)
          let angleInRadians = angleInDegrees * (.pi / 180)
        
          // Scale compounds with each layer, but significantly reduced
          let scaleFactor = 0.25
          let layerScale = pow(1.0 + (shapeScale - 1.0) * scaleFactor, Double(layerIndex + 1))
          let scaledRadius = radius * layerScale
        
          // Apply spread to move shapes away from center
          let spreadDistance = shapeSpread * 2.0
          let spreadX = spreadDistance * cos(angleInRadians)
          let spreadY = spreadDistance * sin(angleInRadians)
        
          // Calculate final position with horizontal and vertical offsets
          let finalX = center.x + scaledRadius * cos(angleInRadians) + spreadX + shapeHorizontal
          let finalY = center.y + scaledRadius * sin(angleInRadians) + spreadY - shapeVertical
        
          // Create base rectangle centered at the final position
          let baseRect = CGRect(
              x: finalX - scaledRadius,
              y: finalY - scaledRadius,
              width: scaledRadius * 2,
              height: scaledRadius * 2
          )
        
          // Create skew transform relative to the shape's center
          var transform = CGAffineTransform.identity
              .translatedBy(x: finalX, y: finalY)
        
          // Apply skew
          let skewXRadians = (shapeSkewX / 100.0) * .pi / 4
          let skewYRadians = (shapeSkewY / 100.0) * .pi / 4
          transform.c = CGFloat(tan(skewXRadians))  // Horizontal skew
          transform.b = CGFloat(tan(skewYRadians))  // Vertical skew
        
          // Complete the transform by translating back
          transform = transform.translatedBy(x: -finalX, y: -finalY)
        
          // Create and transform the circle path
          let circlePath = Path(ellipseIn: baseRect).applying(transform)
        
          // Draw the shape
          let opacity = layerIndex == 0 ? 1.0 : 0.5
          layerContext.fill(circlePath, with: .color(shapeColor.opacity(opacity)))
      }
    
      /// Creates a circular path with specified parameters
      /// - Parameters:
      ///   - center: Center point of the circle
      ///   - radius: Base radius before scaling
      ///   - scale: Scale factor to apply
      /// - Returns: Path describing the circle
      private func createCirclePath(
          center: CGPoint,
          radius: Double,
          scale: Double
      ) -> Path {
          Path(ellipseIn: CGRect(
              x: center.x - (radius * scale),
              y: center.y - (radius * 2 * scale),
              width: radius * 2 * scale,
              height: radius * 2 * scale
          ))
      }
    
      // MARK: - Gesture Handlers
    
      /// Handles continuous updates during drag gesture
      /// - Parameter value: DragGesture.Value
      private func handleDragChange(value: DragGesture.Value) {
          withAnimation(.interactiveSpring(
              response: 0.3,
              dampingFraction: 0.7,
              blendDuration: 0.2
          )) {
              offset.width = lastOffset.width + value.translation.width
              offset.height = lastOffset.height + value.translation.height
          }
      }
    
      /// Handles the end of drag gesture
      /// - Parameter value: DragGesture.Value
      private func handleDragEnd(value: DragGesture.Value) {
          withAnimation(.spring(
              response: 0.4,
              dampingFraction: 0.8,
              blendDuration: 0.3
          )) {
              offset.width = lastOffset.width + value.translation.width
              offset.height = lastOffset.height + value.translation.height
          }
        
          lastOffset = offset
      }
    
      /// Resets the canvas position to the center of the screen
      private func resetPosition() {
          withAnimation(.spring(
              response: 0.8,
              dampingFraction: 0.5,
              blendDuration: 1.0
          )) {
              offset = CGSize(
                  width: (UIScreen.main.bounds.width - 1600) / 2,
                  height: (UIScreen.main.bounds.height - 1800) / 2
              )
              lastOffset = offset
          }
      }
    
      // MARK: - UI Components
    
      /// Creates the reset position button
      private func makeResetButton() -> some View {
          Button(action: resetPosition) {
              Rectangle()
                  .foregroundColor(Color(uiColor: .systemBlue))
                  .frame(width: 40, height: 40)
                  .clipShape(RoundedRectangle(cornerRadius: 8))
                  .overlay(
                      Image(systemName: "arrow.down.forward.and.arrow.up.backward")
                          .font(.system(size: 20))
                          .foregroundColor(Color(uiColor: .systemBackground))
                  )
          }
          .accessibilityIdentifier("Reset Position")
      }
    
      /// Creates the properties panel toggle button
      private func makePropertiesButton() -> some View {
          Button(action: {
              withAnimation(.spring()) {
                  if showColorShapes {  // If color shapes panel is showing
                      showColorShapes = false  // Hide it
                      showProperties = true    // Show properties panel
                  } else if !showProperties {  // If neither panel is showing
                      showProperties = true    // Show properties panel
                  }
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
                  .overlay(
                      RoundedRectangle(cornerRadius: 8)
                          .stroke(Color(uiColor: .systemGray3), lineWidth: 0.5)
                  )
          }
          .accessibilityIdentifier("Properties Button")
      }
    
      /// Creates an alternate button to toggle the properties panel
      private func makeColorShapesButton() -> some View {
          Button(action: {
              withAnimation(.spring()) {
                  if showProperties {     // If properties panel is showing
                      showProperties = false  // Hide it
                      showColorShapes = true  // Show color shapes panel
                  } else if !showColorShapes {  // If neither panel is showing
                      showColorShapes = true    // Show color shapes panel
                  }
              }
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
      }
    
      /// Creates the zoom control slider with + and - indicators
      private func makeZoomSlider() -> some View {
          VStack(spacing: 8) {
              Image(systemName: "plus")
                  .font(.system(size: 16, weight: .bold))
                  .foregroundColor(Color(uiColor: .secondaryLabel))
                  .padding(.bottom, 50)
            
              Slider(
                  value: $zoomLevel,
                  in: minZoomLevel...3.0,
                  step: 0.1
              )
              .rotationEffect(.degrees(-90))
              .frame(width: 120)
              .accessibilityIdentifier("Zoom Slider")
            
              Image(systemName: "minus")
                  .font(.system(size: 16, weight: .bold))
                  .foregroundColor(Color(uiColor: .secondaryLabel))
                  .padding(.top, 50)
          }
          .padding(8)
          .background(
              RoundedRectangle(cornerRadius: 8)
                  .fill(Color(uiColor: .systemBackground))
                  .overlay(
                      RoundedRectangle(cornerRadius: 8)
                          .stroke(Color(uiColor: .systemGray3), lineWidth: 0.5)
                  )
                  .frame(width: 40)
          )
      }
    
      /// Creates the close button for the properties panel
      private func makeCloseButton() -> some View {
          Button(action: {
              withAnimation(.spring()) {
                  showProperties = false
                  showColorShapes = false
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
          .accessibilityIdentifier("Close Button")
      }
   }
