//
//  CanvasView.swift
//  COMP-49X-24-25-PhoneArt
//
//  Created by Aditya Prakash on 12/06/24.
//

import SwiftUI
import UIKit
import Photos

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
    @State internal var lastOffset: CGSize = CGSize(
        width: (UIScreen.main.bounds.width - 1600) / 2,
        height: (UIScreen.main.bounds.height - 1800) / 2
    )
     /// Properties panel visibility state
    @State internal var showProperties = false
     /// Shape transformation properties
    @State private var shapeRotation: Double = 0
    @State private var shapeScale: Double = 1.0
    @State private var shapeLayer: Double = 0
    @State private var shapeSkewX: Double = 0
    @State private var shapeSkewY: Double = 0
    @State private var shapeSpread: Double = 0
    @State private var shapeHorizontal: Double = 0
    @State private var shapeVertical: Double = 0
    @State private var shapePrimitive: Double = 1
     @State private var layerCount: Double = 1 // Set default to 1
     /// Add zoom state property
    @State private var zoomLevel: Double = 1.0
    /// Add state to track the starting zoom level during a pinch gesture
    @State private var startingZoomLevel: Double = 1.0
     /// Add new state variable
    @State internal var showColorShapes = false
     /// Add new state variable for shapes panel
    @State internal var showShapesPanel = false
    /// Add state variable for the gallery panel
   @State internal var showGalleryPanel = false
    /// Tracks whether we are switching between panels (rather than opening/closing)
    @State private var isSwitchingPanels = false
     /// The color currently applied to the base shape on the canvas
    /// This color can be changed through the ColorSelectionPanel
    @State private var shapeColor: Color = .red  // Default to red
    /// The currently selected shape type
    @State private var selectedShape: ShapesPanel.ShapeType = .circle  // Default to circle
    /// Use the shared color preset manager for real-time updates
    @ObservedObject private var colorPresetManager = ColorPresetManager.shared
     /// State variable to force view updates when color presets change
    @State private var colorUpdateTrigger = UUID()
    /// State variable to track background color changes
    @State private var backgroundColorTrigger = UUID()
    /// State variable to track stroke setting changes
    @State private var strokeSettingsTrigger = UUID()
     @StateObject internal var firebaseService: FirebaseService // Make internal and declare type
     /// Add state for showing alerts
    @State internal var showAlert = false // Make internal
    @State internal var alertMessage = "" // Make internal
    @State internal var alertTitle = "" // Make internal
    
    /// State variable to store the UUID of the saved artwork
    @State internal var confirmedArtworkId: IdentifiableArtworkID? = nil // Make internal
    /// State variable to control the visibility of the save artwork prompt
    @State private var showingSavePrompt = false
    /// State variable to store the title entered by the user in the prompt
    @State private var artworkTitleInput = ""
    /// State variable for showing the import artwork sheet
    @State private var showImportSheet = false
    /// State variable to track the currently loaded artwork (if any)
    @State private var loadedArtworkData: ArtworkData? = nil
    // Add state for tracking photo saving
    @State private var isSavingPhoto = false
   
    // Add state variables to handle gallery full selection
    @State private var galleryFullArtworks: [ArtworkData] = []
    @State private var showGalleryFullAlert = false
    @State private var pendingArtworkData: (String, String?) = ("", nil) // (artworkString, title)
    @State private var showArtworkReplaceSheet = false
    @State private var galleryThumbnails: [String: UIImage] = [:] // Dictionary to store thumbnails [artworkId: UIImage]
   
    // Add initializer for dependency injection
    init(firebaseService: FirebaseService = FirebaseService()) {
        _firebaseService = StateObject(wrappedValue: firebaseService)
        // Need to initialize other @State properties manually if not default
        // For properties with default initial values like offset, showProperties, etc.,
        // Swift initializes them automatically. If any @State property didn't have
        // a default value assigned inline, you'd initialize it here.
    }
    
    // Make internal for testing
    internal func validatePrimitive(_ primitive: Double) -> Double {
        max(1.0, min(6.0, primitive))
    }
     /// Computed vertical offset for the canvas when properties panel or color shapes panel is shown
    internal var canvasVerticalOffset: CGFloat {
        // Estimate heights: Standard ~350, Gallery ~550
        let standardPanelOffset: CGFloat = -150 // Shift up less for shorter panels
        let galleryPanelOffset: CGFloat = -220  // Shift up more for the taller gallery

        if showGalleryPanel {
            return galleryPanelOffset
        } else if showProperties || showColorShapes || showShapesPanel {
            return standardPanelOffset
        } else {
            return 0 // No panel, no offset
        }
    }
     /// Computed minimum zoom level to fit canvas width to screen width
    private var minZoomLevel: Double {
        UIScreen.main.bounds.width / 1600.0
    }
     // Make internal for testing
    internal func validateZoom(_ zoom: Double) -> Double {
        max(minZoomLevel, min(3.0, zoom))  // Updated to use dynamic minimum
    }
     // MARK: - Body
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                // Update canvas background to use the background color from ColorPresetManager
                colorPresetManager.backgroundColor
                    .frame(
                        width: 2400,
                        height: 2600
                    )
                    .contentShape(Rectangle())
                
                Canvas { context, size in
                    drawShapes(context: context, size: size)
                }
                .accessibilityIdentifier("Canvas")
                .frame(width: 1600, height: 1800)
                // Update border color to be dynamic
                .border(Color(uiColor: .label), width: 2)
                .scaleEffect(zoomLevel)
                .offset(x: offset.width, y: offset.height +  canvasVerticalOffset)
                .animation(.easeInOut(duration: 0.25), value: canvasVerticalOffset)
            }
            .gesture(
                DragGesture()
                    .onChanged(handleDragChange)
                    .onEnded(handleDragEnd)
            )
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        let newZoom = startingZoomLevel * value
                        zoomLevel = validateZoom(newZoom)
                    }
                    .onEnded { value in
                        startingZoomLevel = zoomLevel
                    }
            )
            .onAppear {
                startingZoomLevel = zoomLevel
                
                // Load initial artwork when app starts
                loadInitialArtwork()
            }
      
            // Share button in upper left corner
            VStack(spacing: 10) {
                makeShareButton()
                    .padding(.bottom, 30)
            }
            .padding(.top, 50)
            .padding(.leading, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    
            // Existing reset button and zoom slider in upper right
            VStack(spacing: 10) {
                makeResetButton()
                    .padding(.bottom, 30)
                makeZoomSlider()
            }
            .padding(.top, 50)
            .padding(.trailing, -30)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
      
            VStack {
                Spacer()
                // Bottom button bar with evenly distributed buttons
                // Using Spacers before, between, and after buttons ensures equal spacing
                HStack(alignment: .center, spacing: 0) {
                    Spacer() // Left margin spacer for equal distribution
                 
                    makePropertiesButton()

                    Spacer() // Spacer between buttons for equal distribution
                 
                    makeColorShapesButton()
                 
                    Spacer() // Spacer between buttons for equal distribution
                 
                    makeShapesButton()

                    Spacer() // Spacer between buttons for equal distribution
               
                    makeGalleryButton()
                 
                    Spacer() // Spacer between buttons for equal distribution
                 
                    makeCloseButton()
                 
                    Spacer() // Right margin spacer for equal distribution
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
      
            // Conditional Overlays for Panels
            if showProperties {
               panelOverlay {
                    PropertiesPanel(
                        rotation: $shapeRotation,
                        scale: $shapeScale,
                        layer: $shapeLayer,
                        skewX: $shapeSkewX,
                        skewY: $shapeSkewY,
                        spread: $shapeSpread,
                        horizontal: $shapeHorizontal,
                        vertical: $shapeVertical,
                        primitive: $shapePrimitive,
                        isShowing: $showProperties,
                       onSwitchToColorShapes: switchToColorShapes,
                       onSwitchToShapes: switchToShapes,
                       onSwitchToGallery: switchToGallery
                   )
               }
            }
    
            if showColorShapes {
               panelOverlay {
                    ColorPropertiesPanel(
                        isShowing: $showColorShapes,
                        selectedColor: $shapeColor,
                       onSwitchToProperties: switchToProperties,
                       onSwitchToShapes: switchToShapes,
                       onSwitchToGallery: switchToGallery
                   )
               }
            }
      
            if showShapesPanel {
               panelOverlay {
                    ShapesPanel(
                        selectedShape: $selectedShape,
                        isShowing: $showShapesPanel,
                       onSwitchToProperties: switchToProperties,
                       onSwitchToColorProperties: switchToColorShapes,
                       onSwitchToGallery: switchToGallery
                   )
               }
           }

            // Add overlay for the new Gallery Panel
            if showGalleryPanel {
               panelOverlay {
                   GalleryPanel(
                       isShowing: $showGalleryPanel,
                       onSwitchToProperties: switchToProperties,
                       onSwitchToColorShapes: switchToColorShapes,
                       onSwitchToShapes: switchToShapes,
                       onLoadArtwork: loadArtwork
                   )
               }
           }
            
        }
        .ignoresSafeArea()
        // Alert for naming the artwork before saving
        .alert("Save Artwork", isPresented: $showingSavePrompt) {
            TextField("Enter Artwork Title (Optional)", text: $artworkTitleInput)
                .autocapitalization(.words)
                .accessibilityIdentifier("Artwork Title TextField")
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                // Call saveArtwork with the entered title (or nil if empty)
                let titleToSave = artworkTitleInput.trimmingCharacters(in: .whitespacesAndNewlines)
                saveArtwork(title: titleToSave.isEmpty ? nil : titleToSave)
            }
            .accessibilityIdentifier("Save Artwork Button")
        } message: {
            Text("Enter an optional title for your artwork.")
        }
        .onChange(of: showProperties) { _, newValue in
            if !isSwitchingPanels && newValue {
                withAnimation(.easeInOut(duration: 0.25)) {}
            }
        }
        .onChange(of: showColorShapes) { _, newValue in
            if !isSwitchingPanels && newValue {
                withAnimation(.easeInOut(duration: 0.25)) {}
            }
        }
        .onChange(of: showShapesPanel) { _, newValue in
            if !isSwitchingPanels && newValue {
                withAnimation(.easeInOut(duration: 0.25)) {}
            }
        }
        // Add an onReceive modifier to handle color preset changes
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ColorPresetsChanged"))) { _ in
            // Update the trigger to force a refresh
            colorUpdateTrigger = UUID()
        }
        // Add an onReceive modifier to handle background color changes
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("BackgroundColorChanged"))) { _ in
            // Update the trigger to force a refresh
            backgroundColorTrigger = UUID()
        }
        // Add an onReceive modifier to handle stroke setting changes
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("StrokeSettingsChanged"))) { _ in
            // Update the trigger to force a refresh
            strokeSettingsTrigger = UUID()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        // Add alert for gallery full notification
        .alert("Gallery Full", isPresented: $showGalleryFullAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Save to Photos") {
                saveToPhotos()
                showGalleryFullAlert = false
            }
            Button("Select Artwork to Replace") {
                showArtworkReplaceSheet = true
            }
        } message: {
            Text("Your gallery is full (12 artworks maximum). You need to replace an existing artwork to save a new one.")
        }
        // Add sheet for artwork replacement selection
        .sheet(isPresented: $showArtworkReplaceSheet) {
            ArtworkReplaceSheet(
                artworks: galleryFullArtworks,
                thumbnails: galleryThumbnails,
                onSelect: { selectedArtwork in
                    replaceArtwork(with: selectedArtwork)
                },
                onCancel: {
                    showArtworkReplaceSheet = false
                }
            )
        }
        // Apply the overlay modifier to the ZStack
        .overlay {
            // Conditionally display the modal overlay here
            ZStack { // Wrap existing and new overlay content in a ZStack
            if let confirmedId = confirmedArtworkId {
                    // Dimming background for Save Confirmation
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            // confirmedArtworkId = nil // Optional dismiss
                        }
                    
                    // Confirmation View
                    SaveConfirmationView(artworkId: confirmedId.id) {
                        // Action to dismiss the modal
                        confirmedArtworkId = nil
                    }
                    .transition(.opacity.animation(.easeInOut)) // Apply transition here
                }
                
                // Conditionally display Import View
                if showImportSheet {
                    // Dimming background for Import View
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showImportSheet = false // Dismiss on background tap
                        }
                    
                    // Import View
                    ImportArtworkView(
                        onImportSuccess: { artworkString in // Pass the callback
                            // Decode and apply the imported artwork string
                            self.applyImportedArtwork(artworkString)
                            // Dismiss the import sheet
                            self.showImportSheet = false
                        },
                        onClose: { // Add the onClose callback
                            self.showImportSheet = false
                        }
                    )
                    .onChange(of: showImportSheet) { _, newValue in
                        // If the parent state changes to false, ensure dismissal logic runs if needed
                        if !newValue {
                            // Potentially call dismiss() if ImportArtworkView manages its own presentation state
                            // Environment dismiss should handle this implicitly when presented this way.
                        }
                    }
                    .transition(.opacity.animation(.easeInOut)) // Apply transition here
                }
            }
        }
    }
     /// Draws shapes on the canvas above the origin point
    /// - Parameters:
    ///   - context: The graphics context to draw in
    ///   - size: The size of the canvas
    private func drawShapes(context: GraphicsContext, size: CGSize) {
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
        // Get the number of primitives (1-6)
        let primitiveCount = Int(validatePrimitive(shapePrimitive))
 
        for layerIndex in 0..<layers {
            // For each primitive in the current layer, draw evenly spaced shapes
            for primitiveIndex in 0..<primitiveCount {
                // Calculate the angle offset for each primitive shape (evenly distributed across 360°)
                let primitiveAngleOffset = (360.0 / Double(primitiveCount)) * Double(primitiveIndex)
  
                drawSingleShape(
                    context: context,
                    layerIndex: layerIndex,
                    primitiveAngleOffset: primitiveAngleOffset,
                    center: center,
                    radius: radius
                )
            }
        }
    }
     /// Draws a single shape with appropriate rotation, opacity, and color
    /// - Parameters:
    ///   - context: The graphics context to draw in
    ///   - layerIndex: Current layer number (0 is base layer)
    ///   - primitiveAngleOffset: Additional angle offset for primitive distribution
    ///   - center: Center point for rotation
    ///   - radius: Radius of the circle
    /// The shape is drawn using either the selected color or cycling through preset colors
    private func drawSingleShape(
        context: GraphicsContext,
        layerIndex: Int,
        primitiveAngleOffset: Double,
        center: CGPoint,
        radius: Double
    ) {
        let layerContext = context
  
        // Calculate the actual angle for this layer (clockwise) plus primitive offset
        let angleInDegrees = (shapeRotation * Double(layerIndex)) + primitiveAngleOffset
        let angleInRadians = angleInDegrees * (.pi / 180)
  
        // Scale compounds with each layer, but significantly reduced
        let scaleFactor = 0.25
        let layerScale = pow(1.0 + (shapeScale - 1.0) * scaleFactor, Double(layerIndex + 1))
        let scaledRadius = radius * layerScale
  
        // Apply spread to move shapes away from center
        let spreadDistance = max(shapeSpread * Double(layerIndex), Double(layerIndex))
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
  
        // Create the path based on the selected shape
        let shapePath: Path
        switch selectedShape {
        case .circle:
            shapePath = Path(ellipseIn: baseRect)
        case .square:
            shapePath = Path(CGRect(
                x: finalX - scaledRadius,
                y: finalY - scaledRadius,
                width: scaledRadius * 2,
                height: scaledRadius * 2
            ))
        case .triangle:
            var path = Path()
            path.move(to: CGPoint(x: finalX, y: finalY - scaledRadius))
            path.addLine(to: CGPoint(x: finalX - scaledRadius, y: finalY + scaledRadius))
            path.addLine(to: CGPoint(x: finalX + scaledRadius, y: finalY + scaledRadius))
            path.closeSubpath()
            shapePath = path
        case .hexagon:
            shapePath = ShapeUtils.createPolygonPath(center: CGPoint(x: finalX, y: finalY), radius: scaledRadius, sides: 6)
        case .star:
            shapePath = ShapeUtils.createStarPath(center: CGPoint(x: finalX, y: finalY), innerRadius: scaledRadius * 0.4, outerRadius: scaledRadius, points: 5)
        case .rectangle:
            shapePath = Path(CGRect(
                x: finalX - scaledRadius,
                y: finalY - scaledRadius * 0.6,
                width: scaledRadius * 2,
                height: scaledRadius * 1.2
            ))
        case .oval:
            shapePath = Path(ellipseIn: CGRect(
                x: finalX - scaledRadius,
                y: finalY - scaledRadius * 0.6,
                width: scaledRadius * 2,
                height: scaledRadius * 1.2
            ))
        case .diamond:
            var path = Path()
            path.move(to: CGPoint(x: finalX, y: finalY - scaledRadius))
            path.addLine(to: CGPoint(x: finalX + scaledRadius, y: finalY))
            path.addLine(to: CGPoint(x: finalX, y: finalY + scaledRadius))
            path.addLine(to: CGPoint(x: finalX - scaledRadius, y: finalY))
            path.closeSubpath()
            shapePath = path
        case .pentagon:
            shapePath = ShapeUtils.createPolygonPath(center: CGPoint(x: finalX, y: finalY), radius: scaledRadius, sides: 5)
        case .octagon:
            shapePath = ShapeUtils.createPolygonPath(center: CGPoint(x: finalX, y: finalY), radius: scaledRadius, sides: 8)
        case .arrow:
            shapePath = ShapeUtils.createArrowPath(center: CGPoint(x: finalX, y: finalY), size: scaledRadius)
        case .rhombus:
            var path = Path()
            path.move(to: CGPoint(x: finalX, y: finalY - scaledRadius))
            path.addLine(to: CGPoint(x: finalX + scaledRadius * 0.8, y: finalY))
            path.addLine(to: CGPoint(x: finalX, y: finalY + scaledRadius))
            path.addLine(to: CGPoint(x: finalX - scaledRadius * 0.8, y: finalY))
            path.closeSubpath()
            shapePath = path
        case .parallelogram:
            var path = Path()
            path.move(to: CGPoint(x: finalX - scaledRadius + scaledRadius * 0.4, y: finalY - scaledRadius * 0.6))
            path.addLine(to: CGPoint(x: finalX + scaledRadius + scaledRadius * 0.4, y: finalY - scaledRadius * 0.6))
            path.addLine(to: CGPoint(x: finalX + scaledRadius - scaledRadius * 0.4, y: finalY + scaledRadius * 0.6))
            path.addLine(to: CGPoint(x: finalX - scaledRadius - scaledRadius * 0.4, y: finalY + scaledRadius * 0.6))
            path.closeSubpath()
            shapePath = path
        case .trapezoid:
            var path = Path()
            path.move(to: CGPoint(x: finalX - scaledRadius * 0.8, y: finalY - scaledRadius * 0.6))
            path.addLine(to: CGPoint(x: finalX + scaledRadius * 0.8, y: finalY - scaledRadius * 0.6))
            path.addLine(to: CGPoint(x: finalX + scaledRadius, y: finalY + scaledRadius * 0.6))
            path.addLine(to: CGPoint(x: finalX - scaledRadius, y: finalY + scaledRadius * 0.6))
            path.closeSubpath()
            shapePath = path
        }
   
        // Create separate transformations and apply them in the correct sequence
   
        // The key insight: Skew transformation naturally shifts the object's center
        // To fix this, we need to:
        // 1. Create the shape centered at the origin (0,0)
        // 2. Apply skew and rotation transformations (in local coordinates)
        // 3. Then translate the result to its final position
   
        // First we'll create a shape centered at the origin and a separate transform to position it
        _ = shapePath
   
        // For positioning, we use a separate transform
        _ = CGAffineTransform(translationX: 0, y: 0) // We'll modify this later
   
        // Now create the transforms for rotation and skew (relative to origin)
        var shapeTransform = CGAffineTransform.identity
   
        // 1. Apply rotation
        if abs(angleInRadians) > 0.001 {
            shapeTransform = shapeTransform.rotated(by: CGFloat(angleInRadians))
        }
   
        // 2. Apply skew (relative to origin)
        if abs(shapeSkewX) > 0.01 || abs(shapeSkewY) > 0.01 {
            // Use smaller range to prevent extreme distortion
            let skewXRad = (shapeSkewX / 100.0) * (.pi / 15) // Max ±12 degrees
            let skewYRad = (shapeSkewY / 100.0) * (.pi / 15) // Max ±12 degrees
   
            // Build skew transform (this creates a skew centered at 0,0)
            if abs(shapeSkewX) > 0.01 {
                let shearX = CGFloat(tan(skewXRad))
                let skewXTransform = CGAffineTransform(a: 1, b: 0, c: shearX, d: 1, tx: 0, ty: 0)
                shapeTransform = shapeTransform.concatenating(skewXTransform)
            }
   
            if abs(shapeSkewY) > 0.01 {
                let shearY = CGFloat(tan(skewYRad))
                let skewYTransform = CGAffineTransform(a: 1, b: shearY, c: 0, d: 1, tx: 0, ty: 0)
                shapeTransform = shapeTransform.concatenating(skewYTransform)
            }
        }
     
        // Now combine the transforms:
        // 1. Create the shape path (already at position finalX, finalY)
        // 2. Transform it to the origin (0,0) by subtracting finalX, finalY
        // 3. Apply rotation and skew transforms to the centered shape
        // 4. Transform it back to final position
    
        // Complete transform chain:
        let toOriginTransform = CGAffineTransform(translationX: -finalX, y: -finalY)
        let backToPositionTransform = CGAffineTransform(translationX: finalX, y: finalY)
     
        // Chain the transforms in correct order:
        // First to origin, then apply shape transformations, then back to position
        let finalTransform = toOriginTransform
            .concatenating(shapeTransform)
            .concatenating(backToPositionTransform)
     
        // Apply the complete transform chain to get the final path
        let transformedPath = shapePath.applying(finalTransform)
     
        // Determine color for this layer - cycle through presets based on visible presets
        let layerColor = colorPresetManager.colorForPosition(position: layerIndex)
    
        // Draw the shape with appropriate opacity
        let baseOpacity = colorPresetManager.shapeAlpha  // Get the global alpha setting
        let layerOpacity = layerIndex == 0 ? baseOpacity : baseOpacity * 0.8  // Apply layer-specific opacity
        layerContext.fill(transformedPath, with: .color(layerColor.opacity(layerOpacity)))
    
        // Apply stroke if width is greater than 0
        if colorPresetManager.strokeWidth > 0 {
            layerContext.stroke(
                transformedPath,
                with: .color(colorPresetManager.strokeColor),  // Don't apply alpha to stroke
                lineWidth: CGFloat(colorPresetManager.strokeWidth)
            )
        }
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
    internal func resetPosition() {
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
            Rectangle() // Keep the Rectangle as the base shape
                .foregroundColor(.clear) // Make the rectangle transparent
                .frame(width: 40, height: 40)
                .background(Color(uiColor: .systemBackground)) // Apply background color
                .cornerRadius(8) // Apply corner radius
                .overlay( // Apply icon overlay
                    Image(systemName: "arrow.down.forward.and.arrow.up.backward")
                        .font(.system(size: 20))
                        .foregroundColor(Color(uiColor: .systemBlue)) // Use systemBlue for icon
                )
                .overlay( // Apply border overlay
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(uiColor: .systemGray3), lineWidth: 0.5)
                )
        }
        .accessibilityIdentifier("Reset Position")
    }
     /// Creates the properties panel toggle button
    private func makePropertiesButton() -> some View {
        Button(action: {
           if showProperties {
               showProperties = false
           } else {
               switchToProperties()
            }
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
     /// Creates an alternate button to toggle the properties panel
    private func makeColorShapesButton() -> some View {
        Button(action: {
           if showColorShapes {
               showColorShapes = false
           } else {
               switchToColorShapes()
            }
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
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(uiColor: .systemGray3), lineWidth: 0.5)
                )
        }
        .accessibilityIdentifier("Color Shapes Button")
    }
     /// Creates a button for the shapes panel
    private func makeShapesButton() -> some View {
        Button(action: {
           if showShapesPanel {
               showShapesPanel = false
           } else {
               switchToShapes()
            }
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
     /// Creates the close button that's always visible
    private func makeCloseButton() -> some View {
        Button(action: {
           // Close all panels
                showProperties = false
                showColorShapes = false
                showShapesPanel = false
           showGalleryPanel = false
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
        .accessibilityIdentifier("Close Button")
    }
     /// Creates the share button group for the top navigation bar
    private func makeShareButton() -> some View {
           return VStack(spacing: 20) {
               // --- Top Button Menu (New / Import) ---
               Menu {
                   Button(action: resetCanvasToDefault) {
                       Label("New Canvas", systemImage: "doc.badge.plus")
                   }
                   .accessibilityIdentifier("New Canvas Button")

                   Button(action: { showImportSheet = true }) {
                       Label("Import from ID...", systemImage: "square.and.arrow.down") // Icon indicates retrieving
            }
            .accessibilityIdentifier("Import Button")
            
               } label: {
                   buttonIcon(systemName: "plus") // Keep the plus icon for the menu
               }
               .accessibilityIdentifier("New/Import Menu")

               // --- Bottom Button Menu (Share/Save) ---
            Menu {
                   // Conditional Save Button
                   if let artworkToUpdate = loadedArtworkData {
                       Button(action: { updateCurrentArtwork(artwork: artworkToUpdate) }) {
                           Label("Save", systemImage: "square.and.arrow.down")
                       }
                       .accessibilityIdentifier("Save Update Button")
                   } // Else (no loaded artwork), this button doesn't appear

                   // --- Save as New Button ---
                   Button(action: { showSaveAsNewPrompt() }) {
                       Label("Save as New...", systemImage: "square.and.arrow.down.on.square")
                   }
                   .accessibilityIdentifier("Save as New Button")

                   // --- Save to Photos Button ---
                Button(action: saveToPhotos) {
                    Label("Save to Photos", systemImage: "photo")
                }
                .accessibilityIdentifier("Save to Photos Button")
                
                // Add other share options here
            } label: {
                   buttonIcon(systemName: "square.and.arrow.up")
            }
            .accessibilityIdentifier("Share Button")
        }
       }


       /// Creates a button for the Gallery.
       private func makeGalleryButton() -> some View {
           Button(action: {
              switchToGallery() // Use the correct callback method
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


     // Modify access level
     // private func saveArtwork() {
     internal func saveArtwork(title: String? = nil) {
        let artworkString = getCurrentArtworkString()
        
        // Save for potential later use if gallery is full
        pendingArtworkData = (artworkString, title)
        
        Task {
            do {
                let (docRef, isGalleryFull, existingArtworks) = try await firebaseService.saveArtwork(artworkData: artworkString, title: title)
                
                if isGalleryFull {
                    // Gallery is full, show alert
                    await MainActor.run {
                        galleryFullArtworks = existingArtworks
                        
                        // Generate thumbnails for the artworks
                        generateThumbnails(for: existingArtworks)
                        
                        showGalleryFullAlert = true
                    }
                } else if let pieceRef = docRef {
                    let newPieceId = pieceRef.documentID
                    
                    // Update the loadedArtworkData state to reflect the newly saved piece
                    self.loadedArtworkData = ArtworkData(
                        deviceId: firebaseService.getDeviceId(), // Get current device ID
                        artworkString: artworkString,
                        timestamp: Date(), // Use current time
                        title: title,
                        pieceId: newPieceId
                    )
                    
                    await firebaseService.listAllPieces()
                    
                    await MainActor.run {
                        confirmedArtworkId = IdentifiableArtworkID(id: newPieceId)
                    }
                }
            } catch {
                await MainActor.run {
                    alertTitle = "Error Saving New"
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }
  
   /// Save artwork to Photos library using ImageRenderer
   private func saveToPhotos() {
       Task { @MainActor in
              // 1. Define the content to render (Canvas + Background)
              let contentToRender = ZStack {
                   colorPresetManager.backgroundColor
                   Canvas { context, size in
                      // Use the exact same drawing logic as the main canvas
                       drawShapes(context: context, size: size)
                   }
               }
              // Use the desired export size (e.g., canvas size without border)
              .frame(width: 1600, height: 1800)


              // 2. Create the ImageRenderer
              let renderer = ImageRenderer(content: contentToRender)


              // Optional: Improve quality if needed by setting scale
              renderer.scale = UIScreen.main.scale // Use screen scale for better quality


              // 3. Render the image (this can take time, keep ProgressView)
              isSavingPhoto = true


              // Asynchronously render the image
              if let uiImage = renderer.uiImage {
                  // 4. Call the updated ExportService function
                  ExportService.saveImageToPhotoLibrary(image: uiImage) { success, error in
                      // Update UI on the main thread
                      isSavingPhoto = false // Hide progress view

                  
                   if success {
                          alertTitle = "Success"
                          alertMessage = "Artwork saved to Photos successfully!"
                   } else {
                          alertTitle = "Error"
                          alertMessage = error?.localizedDescription ?? "Failed to save to Photos"
                      }
                      showAlert = true // Show the result alert
                  }
              } else {
                  // Handle rendering failure
                  isSavingPhoto = false
                  alertTitle = "Error"
                  alertMessage = "Failed to render artwork image."
                  showAlert = true
              }
          }
      }


    // Function to apply imported artwork data to the canvas state
    private func applyImportedArtwork(_ artworkString: String) {
        print("Applying imported artwork string:")
        // Decode the string into a dictionary
        let decodedParams = ArtworkData.decode(from: artworkString)
        print("Decoded parameters: \(decodedParams)")

        // Update state variables - use helper function for safe unwrapping and type conversion
        self.selectedShape = ShapesPanel.ShapeType(rawValue: decodedParams["shape"] ?? "circle") ?? .circle
        self.shapeRotation = doubleValue(from: decodedParams["rotation"]) ?? 0
        self.shapeScale = doubleValue(from: decodedParams["scale"]) ?? 1.0
        self.shapeLayer = doubleValue(from: decodedParams["layer"]) ?? 0
        self.shapeSkewX = doubleValue(from: decodedParams["skewX"]) ?? 0
        self.shapeSkewY = doubleValue(from: decodedParams["skewY"]) ?? 0
        self.shapeSpread = doubleValue(from: decodedParams["spread"]) ?? 0
        self.shapeHorizontal = doubleValue(from: decodedParams["horizontal"]) ?? 0
        self.shapeVertical = doubleValue(from: decodedParams["vertical"]) ?? 0
        self.shapePrimitive = doubleValue(from: decodedParams["primitive"]) ?? 1.0
        
        // Update colors via ColorPresetManager
        if let colorsString = decodedParams["colors"] {
            let importedColors = ArtworkData.reconstructColors(from: colorsString)
            // Ensure we have exactly 10 presets if necessary, padding with defaults if needed
            var finalPresets = importedColors
            if finalPresets.count < 10 {
                let defaultColors: [Color] = [.purple, .blue, .pink, .yellow, .green, .red, .orange, .cyan, .indigo, .mint]
                for i in finalPresets.count..<10 {
                    finalPresets.append(defaultColors[i % defaultColors.count])
                }
            } else if finalPresets.count > 10 {
                finalPresets = Array(finalPresets.prefix(10))
            }
            colorPresetManager.colorPresets = finalPresets
            print("Applied \(finalPresets.count) color presets.")
        }

        if let backgroundString = decodedParams["background"],
           let bgColor = ArtworkData.hexToColor(backgroundString) {
            colorPresetManager.backgroundColor = bgColor
            print("Applied background color: \(bgColor)")
        }
        
        // Apply saved preset count if available
        if let presetCountString = decodedParams["presetCount"], let presetCount = Int(presetCountString) {
            // Validate the range (1-10)
            colorPresetManager.numberOfVisiblePresets = max(1, min(10, presetCount))
            print("Applied numberOfVisiblePresets: \(presetCount)")
        }
        
        // --- Re-add Apply color mode settings --- 
        if let useRainbowString = decodedParams["useRainbow"] {
            colorPresetManager.useDefaultRainbowColors = (useRainbowString == "true")
            print("Applied useDefaultRainbowColors: \(colorPresetManager.useDefaultRainbowColors)")
        }

        if let styleString = decodedParams["rainbowStyle"], let style = Int(styleString) {
            colorPresetManager.rainbowStyle = style
            print("Applied rainbowStyle: \(style)")
        }

        if let hueAdjString = decodedParams["hueAdj"], let hueAdj = Double(hueAdjString) {
            colorPresetManager.hueAdjustment = hueAdj
            print("Applied hueAdjustment: \(hueAdj)")
        }

        if let satAdjString = decodedParams["satAdj"], let satAdj = Double(satAdjString) {
            colorPresetManager.saturationAdjustment = satAdj
            print("Applied saturationAdjustment: \(satAdj)")
        }
        // --- End Re-add ---

        // Note: Stroke and Alpha are not currently saved in artworkString, 
        // so they are not applied during import.

        print("Finished applying imported artwork.")
        
        // --- Apply Stroke and Alpha --- 
        if let strokeColorString = decodedParams["strokeColor"], 
           let color = ArtworkData.hexToColor(strokeColorString) {
            colorPresetManager.strokeColor = color
            print("Applied strokeColor: \(color)")
        }

        // Use the existing doubleValue helper for strokeWidth and alpha
        if let strokeWidth = doubleValue(from: decodedParams["strokeWidth"]) {
            // Clamp stroke width to a reasonable range (e.g., 0-20)
            colorPresetManager.strokeWidth = max(0, min(20.0, strokeWidth))
            print("Applied strokeWidth: \(colorPresetManager.strokeWidth)")
        }

        if let alpha = doubleValue(from: decodedParams["alpha"]) {
            // Clamp alpha to 0-1 range
            colorPresetManager.shapeAlpha = max(0.0, min(1.0, alpha))
            print("Applied shapeAlpha: \(colorPresetManager.shapeAlpha)")
        }
        // --- End Apply Stroke and Alpha ---
    }

    // Helper function to safely convert String? to Double?
    private func doubleValue(from stringValue: String?) -> Double? {
        guard let string = stringValue else { return nil }
        return Double(string)
    }

    /// Generic function to handle panel switching logic
   private func switchPanel(hideOthersAndShow panelToShow: Binding<Bool>) {
       isSwitchingPanels = true
       showProperties = false
       showColorShapes = false
       showShapesPanel = false
       showGalleryPanel = false
       panelToShow.wrappedValue = true
       isSwitchingPanels = false
   }
   
   /// Switch to Properties panel
   private func switchToProperties() {
       switchPanel(hideOthersAndShow: $showProperties)
   }
   
   /// Switch to Color Shapes panel
   private func switchToColorShapes() {
       switchPanel(hideOthersAndShow: $showColorShapes)
   }
   
   /// Switch to Shapes panel
   private func switchToShapes() {
       switchPanel(hideOthersAndShow: $showShapesPanel)
   }
  
   /// Switch to Gallery panel
   private func switchToGallery() {
       switchPanel(hideOthersAndShow: $showGalleryPanel)
   }


   /// Helper view modifier to wrap panel content with standard layout and transition
   @ViewBuilder
   private func panelOverlay<Content: View>(@ViewBuilder content: () -> Content) -> some View {
       VStack {
           Spacer()
           content()
       }
       .zIndex(3) // Ensure panels appear above the canvas content
       .transition(!isSwitchingPanels ? .asymmetric(
           insertion: .move(edge: .bottom),
           removal: .move(edge: .bottom)
       ) : .identity) // Use standard transition unless switching panels
   }

    /// Loads the parameters from a saved ArtworkData object into the current canvas state.
    private func loadArtwork(artwork: ArtworkData) {
        print("[CanvasView] Loading artwork: \(artwork.title ?? "Untitled") (ID: \(artwork.id))")
        // Store the loaded artwork data, including its pieceId
        self.loadedArtworkData = artwork

        let decodedParams = ArtworkData.decode(from: artwork.artworkString)
        print("[CanvasView] Decoded params for load: \(decodedParams)")

        // Helper to safely extract double values
        func doubleValue(from key: String, default defaultValue: Double) -> Double {
            guard let stringValue = decodedParams[key], let value = Double(stringValue) else {
                print("[CanvasView Load] Warning: Could not decode Double for key '\(key)', using default: \(defaultValue)")
                return defaultValue
            }
            // Note: Validation happens within ArtworkData.decode, so we trust the values here
            return value
        }

        // Update shape parameters
        shapeRotation = doubleValue(from: "rotation", default: shapeRotation)
        shapeScale = doubleValue(from: "scale", default: shapeScale)
        shapeLayer = doubleValue(from: "layer", default: shapeLayer)
        shapeSkewX = doubleValue(from: "skewX", default: shapeSkewX)
        shapeSkewY = doubleValue(from: "skewY", default: shapeSkewY)
        shapeSpread = doubleValue(from: "spread", default: shapeSpread)
        shapeHorizontal = doubleValue(from: "horizontal", default: shapeHorizontal)
        shapeVertical = doubleValue(from: "vertical", default: shapeVertical)
        shapePrimitive = doubleValue(from: "primitive", default: shapePrimitive)

        // Update selected shape type
        if let shapeString = decodedParams["shape"],
           let loadedShape = ShapesPanel.ShapeType(rawValue: shapeString) {
            selectedShape = loadedShape
            print("[CanvasView Load] Loaded shape: \(loadedShape.rawValue)")
        } else {
             print("[CanvasView Load] Warning: Could not decode 'shape'.")
        }

        // Update ColorPresetManager with decoded color settings
        // This handles presets, background, rainbow settings, stroke, alpha, etc.
        ColorPresetManager.shared.update(from: decodedParams)

        // Reset zoom and position (optional, but often desired when loading)
        // resetPositionAndZoom()
        // Commented out reset - user might want to keep current view

        print("[CanvasView] Finished loading artwork.")

        // Force UI refresh (though ColorPresetManager updates should trigger it)
        // self.objectWillChange.send() // Usually not needed due to @State updates
    }

    /// Shows the prompt for entering a title when saving new artwork.
    private func showSaveAsNewPrompt() {
        artworkTitleInput = "" // Reset title input
        showingSavePrompt = true // Show the alert
    }

    /// Updates the currently loaded artwork in Firestore with the current canvas state.
    private func updateCurrentArtwork(artwork: ArtworkData) {
        guard let pieceId = artwork.pieceId else {
            // Should not happen if the button is only shown for loaded artwork
            print("Error: Attempted to update artwork without a pieceId.")
            alertTitle = "Error"
            alertMessage = "Cannot update artwork: Missing original ID."
            showAlert = true
            return
        }
        print("Attempting to update artwork with pieceId: \(pieceId)")

        let currentArtworkString = getCurrentArtworkString()

        Task {
            do {
                try await firebaseService.updateArtwork(artwork: artwork, newArtworkString: currentArtworkString)
                // Optionally update the local loadedArtworkData timestamp or string if needed
                // self.loadedArtworkData?.timestamp = Date() // Example
                await MainActor.run {
                    // Show success feedback (optional)
                    alertTitle = "Success"
                    alertMessage = "Artwork '\(artwork.title ?? "Untitled")' updated successfully!"
                    showAlert = true
                    // Maybe show the confirmation view?
                    // confirmedArtworkId = IdentifiableArtworkID(id: pieceId)
                }
            } catch {
                await MainActor.run {
                    alertTitle = "Error Updating"
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }

    /// Helper function to generate the artwork string from the current canvas state.
    private func getCurrentArtworkString() -> String {
        return ArtworkData.createArtworkString(
            shapeType: selectedShape,
            rotation: shapeRotation,
            scale: shapeScale,
            layer: shapeLayer,
            skewX: shapeSkewX,
            skewY: shapeSkewY,
            spread: shapeSpread,
            horizontal: shapeHorizontal,
            vertical: shapeVertical,
            primitive: shapePrimitive,
            colorPresets: colorPresetManager.colorPresets,
            backgroundColor: colorPresetManager.backgroundColor,
            useDefaultRainbowColors: colorPresetManager.useDefaultRainbowColors,
            rainbowStyle: colorPresetManager.rainbowStyle,
            hueAdjustment: colorPresetManager.hueAdjustment,
            saturationAdjustment: colorPresetManager.saturationAdjustment,
            numberOfVisiblePresets: colorPresetManager.numberOfVisiblePresets,
            strokeColor: colorPresetManager.strokeColor,
            strokeWidth: colorPresetManager.strokeWidth,
            shapeAlpha: colorPresetManager.shapeAlpha
        )
    }

    /// Resets the canvas state and color settings to their default values.
    private func resetCanvasToDefault() {
        print("[CanvasView] Resetting canvas to default state.")

        // Reset shape parameters
        shapeRotation = 0
        shapeScale = 1.0
        shapeLayer = 0
        shapeSkewX = 0
        shapeSkewY = 0
        shapeSpread = 0
        shapeHorizontal = 0
        shapeVertical = 0
        shapePrimitive = 1
        selectedShape = .circle // Default shape

        // Reset color manager
        ColorPresetManager.shared.resetToDefaults()

        // Clear loaded artwork data
        loadedArtworkData = nil

        // Reset zoom and position
        resetPosition() // Call the existing position reset function
        zoomLevel = 1.0   // Reset zoom level to default

        print("[CanvasView] Canvas reset complete.")
    }

    /// Loads initial artwork when the app starts
    private func loadInitialArtwork() {
        Task {
            do {
                // Attempt to get artwork from Firebase
                let artworks = try await firebaseService.getArtwork()
                
                if let mostRecentArtwork = artworks.first {
                    // Found artwork in gallery, load the most recent one
                    print("[CanvasView] Loading most recent artwork: \(mostRecentArtwork.title ?? "Untitled")")
                    await MainActor.run {
                        loadArtwork(artwork: mostRecentArtwork)
                    }
                } else {
                    // No artwork found, create randomized artwork
                    print("[CanvasView] No artwork found, creating randomized artwork")
                    await MainActor.run {
                        createRandomizedArtwork()
                    }
                }
            } catch {
                // Error fetching artwork, create randomized artwork
                print("[CanvasView] Error fetching artwork: \(error.localizedDescription)")
                await MainActor.run {
                    createRandomizedArtwork()
                }
            }
        }
    }
    
    /// Creates an artwork with randomized properties
    private func createRandomizedArtwork() {
        // Random shape type from available options
        let shapeTypes: [ShapesPanel.ShapeType] = [.circle, .square, .triangle, .pentagon, .star]
        selectedShape = shapeTypes.randomElement() ?? .circle
        
        // Random shape properties within reasonable ranges
        shapeRotation = Double.random(in: 0...360)
        shapeScale = Double.random(in: 0.8...1.5)
        shapeLayer = Double.random(in: 0...5)
        shapeSkewX = Double.random(in: 0...30)
        shapeSkewY = Double.random(in: 0...30)
        shapeSpread = Double.random(in: 5...40)
        shapeHorizontal = Double.random(in: -50...50)
        shapeVertical = Double.random(in: -50...50)
        shapePrimitive = Double.random(in: 1...5).rounded()
        
        // Create random colors for the presets (using hue rotation for variety)
        var randomColors: [Color] = []
        for i in 0..<10 {
            let hue = Double.random(in: 0...1)
            let saturation = Double.random(in: 0.7...1.0)
            let brightness = Double.random(in: 0.7...1.0)
            randomColors.append(Color(hue: hue, saturation: saturation, brightness: brightness))
        }
        
        // Apply colors to presets and background
        colorPresetManager.colorPresets = randomColors
        colorPresetManager.backgroundColor = Color(hue: Double.random(in: 0...1), 
                                                  saturation: Double.random(in: 0.1...0.3), 
                                                  brightness: Double.random(in: 0.9...1.0))
                                                  
        // Random stroke and alpha settings
        colorPresetManager.strokeWidth = Double.random(in: 0...5)
        colorPresetManager.strokeColor = randomColors.randomElement() ?? .black
        colorPresetManager.shapeAlpha = Double.random(in: 0.7...1.0)
        
        print("[CanvasView] Created randomized artwork")
    }

    // Add a function to handle replacing an existing artwork
    private func replaceArtwork(with selectedArtwork: ArtworkData) {
        let (artworkString, title) = pendingArtworkData
        
        Task {
            do {
                let pieceRef = try await firebaseService.saveArtworkReplacing(
                    artworkData: artworkString,
                    title: title,
                    replacingArtwork: selectedArtwork
                )
                
                let newPieceId = pieceRef.documentID
                
                // Update the loadedArtworkData state to reflect the newly saved piece
                self.loadedArtworkData = ArtworkData(
                    deviceId: firebaseService.getDeviceId(),
                    artworkString: artworkString,
                    timestamp: Date(),
                    title: title,
                    pieceId: newPieceId
                )
                
                await firebaseService.listAllPieces()
                
                await MainActor.run {
                    confirmedArtworkId = IdentifiableArtworkID(id: newPieceId)
                    showArtworkReplaceSheet = false // Close the selection sheet
                }
            } catch {
                await MainActor.run {
                    alertTitle = "Error Replacing Artwork"
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }

    // Add a function to generate thumbnails for artwork selection
    private func generateThumbnails(for artworks: [ArtworkData]) {
        Task(priority: .userInitiated) {
            var generated: [String: UIImage] = [:]
            let targetSize = CGSize(width: 50, height: 50) // Small preview size for the list
            
            for artwork in artworks {
                // Skip if we already have a thumbnail
                if let existingThumb = galleryThumbnails[artwork.id] {
                    generated[artwork.id] = existingThumb
                    continue
                }
                
                // Decode artwork parameters for rendering
                if let params = decodeArtworkParameters(from: artwork.artworkString) {
                    // Create a renderer for the artwork
                    let renderer = ImageRenderer(content: ArtworkRendererView(params: params))
                    renderer.scale = UIScreen.main.scale
                    
                    if let uiImage = renderer.uiImage {
                        // Resize the image to thumbnail size
                        if let resizedImage = resizeImage(image: uiImage, targetSize: targetSize) {
                            generated[artwork.id] = resizedImage
                        }
                    }
                }
            }
            
            // Update thumbnails on the main thread
            await MainActor.run {
                self.galleryThumbnails = generated
            }
        }
    }
    
    // Helper for resizing images
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let ratio = min(widthRatio, heightRatio)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    // Helper to decode artwork parameters
    private func decodeArtworkParameters(from artworkString: String) -> ArtworkParameters? {
        let decodedParams = ArtworkData.decode(from: artworkString)
        
        // Helper for doubles
        func doubleValue(from key: String, default defaultValue: Double) -> Double {
            guard let stringValue = decodedParams[key], let value = Double(stringValue) else {
                return defaultValue
            }
            return value
        }
        
        guard let shapeString = decodedParams["shape"],
              let shapeType = ShapesPanel.ShapeType(rawValue: shapeString) else {
            return nil // Cannot render without shape type
        }
        
        let colors = ArtworkData.reconstructColors(from: decodedParams["colors"] ?? "")
        let background = ArtworkData.hexToColor(decodedParams["background"] ?? "") ?? .white
        
        // Decode color mode flag
        let useRainbowFlag = (decodedParams["useRainbow"] ?? "false") == "true"
        
        // Decode rainbow settings
        let rainbowStyle = Int(decodedParams["rainbowStyle"] ?? "") ?? 0
        let hueAdjustment = Double(decodedParams["hueAdj"] ?? "") ?? 0.0
        let saturationAdjustment = Double(decodedParams["satAdj"] ?? "") ?? 0.0
        
        // Decode stroke and alpha
        let shapeAlpha = doubleValue(from: "alpha", default: 1.0)
        let strokeWidth = doubleValue(from: "strokeWidth", default: 0.0)
        let strokeColor = ArtworkData.hexToColor(decodedParams["strokeColor"] ?? "") ?? .black
        
        return ArtworkParameters(
            shapeType: shapeType,
            rotation: doubleValue(from: "rotation", default: 0),
            scale: doubleValue(from: "scale", default: 1.0),
            layer: doubleValue(from: "layer", default: 1.0),
            skewX: doubleValue(from: "skewX", default: 0),
            skewY: doubleValue(from: "skewY", default: 0),
            spread: doubleValue(from: "spread", default: 0),
            horizontal: doubleValue(from: "horizontal", default: 0),
            vertical: doubleValue(from: "vertical", default: 0),
            primitive: doubleValue(from: "primitive", default: 1.0),
            colorPresets: colors,
            backgroundColor: background,
            useDefaultRainbowColors: useRainbowFlag,
            rainbowStyle: rainbowStyle,
            hueAdjustment: hueAdjustment,
            saturationAdjustment: saturationAdjustment,
            shapeAlpha: shapeAlpha,
            strokeWidth: strokeWidth,
            strokeColor: strokeColor
        )
    }
}

/// Helper for share/import button appearance
@ViewBuilder
private func buttonIcon(systemName: String) -> some View {
    VStack {
        Image(systemName: systemName)
            .font(.system(size: 20))
            .foregroundColor(Color(uiColor: .systemBlue))
    }
    .padding(8)
    .frame(width: 40, height: 40)
    .background(Color(uiColor: .systemBackground))
    .cornerRadius(8)
    .overlay(
        RoundedRectangle(cornerRadius: 8)
            .stroke(Color(uiColor: .systemGray3), lineWidth: 0.5)
    )
}

// MARK: - Artwork Replace Sheet

struct ArtworkReplaceSheet: View {
    let artworks: [ArtworkData]
    let thumbnails: [String: UIImage]
    let onSelect: (ArtworkData) -> Void
    let onCancel: () -> Void
    
    // Formatter for timestamp
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Select an artwork to replace:")) {
                    ForEach(artworks) { artwork in
                        Button(action: {
                            onSelect(artwork)
                        }) {
                            HStack {
                                // Add a preview of the artwork
                                ArtworkPreview(artwork: artwork, thumbnail: thumbnails[artwork.id])
                                    .frame(width: 50, height: 50)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color(uiColor: .systemGray3), lineWidth: 0.5)
                                    )
                                
                                VStack(alignment: .leading) {
                                    Text(artwork.title ?? "Untitled")
                                        .font(.headline)
                                    Text("Last modified: \(Self.dateFormatter.string(from: artwork.timestamp))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "arrow.forward.circle")
                                    .foregroundColor(.blue)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Gallery Full")
            .navigationBarItems(
                trailing: Button("Cancel") {
                    onCancel()
                }
            )
        }
    }
}

// New view to render artwork preview
struct ArtworkPreview: View {
    let artwork: ArtworkData
    let thumbnail: UIImage?
    
    var body: some View {
        if let thumbnailImage = thumbnail {
            // Use the pre-rendered thumbnail
            Image(uiImage: thumbnailImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .background(Color(.systemBackground))
        } else {
            // Fallback if no thumbnail is available
            ZStack {
                Color.gray.opacity(0.3)
                Image(systemName: "photo")
                    .foregroundColor(.gray)
            }
        }
    }
}

// Add ArtworkParameters struct to support the ArtworkPreview view
private struct ArtworkParameters {
    let shapeType: ShapesPanel.ShapeType
    let rotation: Double
    let scale: Double
    let layer: Double
    let skewX: Double
    let skewY: Double
    let spread: Double
    let horizontal: Double
    let vertical: Double
    let primitive: Double
    let colorPresets: [Color]
    let backgroundColor: Color
    let useDefaultRainbowColors: Bool
    let rainbowStyle: Int
    let hueAdjustment: Double
    let saturationAdjustment: Double
    let shapeAlpha: Double
    let strokeWidth: Double
    let strokeColor: Color
}

// ArtworkRendererView for rendering thumbnails
private struct ArtworkRendererView: View {
    let params: ArtworkParameters
    // Define the rendering size
    private let renderSize = CGSize(width: 100, height: 100)
    
    var body: some View {
        Canvas { context, size in
            // Fill background
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(params.backgroundColor))
            // Draw the shapes
            drawShapes(context: context, size: size, params: params)
        }
        .frame(width: renderSize.width, height: renderSize.height)
    }
    
    // MARK: - Drawing Logic
    private func drawShapes(context: GraphicsContext, size: CGSize, params: ArtworkParameters) {
        let circleRadius = 10.0 // Smaller radius for thumbnails
        let centerX = size.width / 2
        let centerY = size.height / 2
        let center = CGPoint(x: centerX, y: centerY)
        
        let numberOfLayers = max(0, min(360, Int(params.layer)))
        if numberOfLayers > 0 {
            drawLayers(
                context: context,
                layers: numberOfLayers,
                center: center,
                radius: circleRadius,
                params: params
            )
        }
    }
    
    private func drawLayers(
        context: GraphicsContext,
        layers: Int,
        center: CGPoint,
        radius: Double,
        params: ArtworkParameters
    ) {
        let primitiveCount = Int(max(1.0, min(6.0, params.primitive)))
        
        for layerIndex in 0..<layers {
            for primitiveIndex in 0..<primitiveCount {
                let primitiveAngleOffset = (360.0 / Double(primitiveCount)) * Double(primitiveIndex)
                drawSingleShape(
                    context: context,
                    layerIndex: layerIndex,
                    primitiveAngleOffset: primitiveAngleOffset,
                    center: center,
                    radius: radius,
                    params: params
                )
            }
        }
    }
    
    private func drawSingleShape(
        context: GraphicsContext,
        layerIndex: Int,
        primitiveAngleOffset: Double,
        center: CGPoint,
        radius: Double,
        params: ArtworkParameters
    ) {
        let angleInDegrees = (params.rotation * Double(layerIndex)) + primitiveAngleOffset
        let angleInRadians = angleInDegrees * (.pi / 180)
        
        let scaleFactor = 0.25
        let layerScale = pow(1.0 + (params.scale - 1.0) * scaleFactor, Double(layerIndex + 1))
        let scaledRadius = radius * layerScale
        
        let spreadDistance = max(params.spread * Double(layerIndex), Double(layerIndex))
        let spreadX = spreadDistance * cos(angleInRadians)
        let spreadY = spreadDistance * sin(angleInRadians)
        
        let finalX = center.x + scaledRadius * cos(angleInRadians) + spreadX + params.horizontal
        let finalY = center.y + scaledRadius * sin(angleInRadians) + spreadY - params.vertical
        
        let baseRect = CGRect(
            x: finalX - scaledRadius,
            y: finalY - scaledRadius,
            width: scaledRadius * 2,
            height: scaledRadius * 2
        )
        
        // Create shape path based on type
        let shapePath: Path
        switch params.shapeType {
        case .circle:
            shapePath = Path(ellipseIn: baseRect)
        case .square:
            shapePath = Path(baseRect)
        case .triangle:
            var path = Path()
            path.move(to: CGPoint(x: finalX, y: finalY - scaledRadius))
            path.addLine(to: CGPoint(x: finalX - scaledRadius, y: finalY + scaledRadius))
            path.addLine(to: CGPoint(x: finalX + scaledRadius, y: finalY + scaledRadius))
            path.closeSubpath()
            shapePath = path
        case .hexagon:
            shapePath = createPolygonPath(center: CGPoint(x: finalX, y: finalY), radius: scaledRadius, sides: 6)
        case .star:
            shapePath = createStarPath(center: CGPoint(x: finalX, y: finalY), innerRadius: scaledRadius * 0.4, outerRadius: scaledRadius, points: 5)
        case .pentagon:
            shapePath = createPolygonPath(center: CGPoint(x: finalX, y: finalY), radius: scaledRadius, sides: 5)
        case .octagon:
            shapePath = createPolygonPath(center: CGPoint(x: finalX, y: finalY), radius: scaledRadius, sides: 8)
        default:
            // Default to circle for other shapes to keep it simple
            shapePath = Path(ellipseIn: baseRect)
        }
        
        // Apply transformations
        var shapeTransform = CGAffineTransform.identity
        
        if abs(angleInRadians) > 0.001 {
            shapeTransform = shapeTransform.rotated(by: CGFloat(angleInRadians))
        }
        
        // Apply skew if needed
        if abs(params.skewX) > 0.01 || abs(params.skewY) > 0.01 {
            let skewXRad = (params.skewX / 100.0) * (.pi / 15)
            let skewYRad = (params.skewY / 100.0) * (.pi / 15)
            
            if abs(params.skewX) > 0.01 {
                let shearX = CGFloat(tan(skewXRad))
                shapeTransform = shapeTransform.concatenating(CGAffineTransform(a: 1, b: 0, c: shearX, d: 1, tx: 0, ty: 0))
            }
            
            if abs(params.skewY) > 0.01 {
                let shearY = CGFloat(tan(skewYRad))
                shapeTransform = shapeTransform.concatenating(CGAffineTransform(a: 1, b: shearY, c: 0, d: 1, tx: 0, ty: 0))
            }
        }
        
        // Apply the complete transform
        let toOriginTransform = CGAffineTransform(translationX: -finalX, y: -finalY)
        let backToPositionTransform = CGAffineTransform(translationX: finalX, y: finalY)
        let finalTransform = toOriginTransform.concatenating(shapeTransform).concatenating(backToPositionTransform)
        let transformedPath = shapePath.applying(finalTransform)
        
        // Determine color for this layer
        let layerColor: Color
        if params.useDefaultRainbowColors {
            // Use rainbow colors based on style
            switch params.rainbowStyle {
            case 1: layerColor = ColorUtils.cyberpunkRainbowColor(for: layerIndex, hueAdjustment: params.hueAdjustment, saturationAdjustment: params.saturationAdjustment)
            case 2: layerColor = ColorUtils.halfSpectrumRainbowColor(for: layerIndex, hueAdjustment: params.hueAdjustment, saturationAdjustment: params.saturationAdjustment)
            default: layerColor = ColorUtils.rainbowColor(for: layerIndex, hueAdjustment: params.hueAdjustment, saturationAdjustment: params.saturationAdjustment)
            }
        } else {
            // Use presets
            if !params.colorPresets.isEmpty {
                let colorIndex = layerIndex % params.colorPresets.count
                layerColor = params.colorPresets[colorIndex]
            } else {
                layerColor = .gray // Fallback
            }
        }
        
        // Draw the shape
        let baseOpacity = params.shapeAlpha
        let layerOpacity = layerIndex == 0 ? baseOpacity : baseOpacity * 0.8
        
        context.fill(transformedPath, with: .color(layerColor.opacity(layerOpacity)))
        
        // Apply stroke if needed
        if params.strokeWidth > 0 {
            context.stroke(
                transformedPath,
                with: .color(params.strokeColor),
                lineWidth: CGFloat(params.strokeWidth)
            )
        }
    }
    
    // Helper to create polygon paths
    private func createPolygonPath(center: CGPoint, radius: Double, sides: Int) -> Path {
        var path = Path()
        let angle = (2.0 * .pi) / Double(sides)
        for i in 0..<sides {
            let currentAngle = angle * Double(i) - (.pi / 2)
            let x = center.x + CGFloat(radius * cos(currentAngle))
            let y = center.y + CGFloat(radius * sin(currentAngle))
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        path.closeSubpath()
        return path
    }
    
    // Helper to create star paths
    private func createStarPath(center: CGPoint, innerRadius: Double, outerRadius: Double, points: Int) -> Path {
        var path = Path()
        let totalPoints = points * 2
        let angle = (2.0 * .pi) / Double(totalPoints)
        for i in 0..<totalPoints {
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let currentAngle = angle * Double(i) - (.pi / 2)
            let x = center.x + CGFloat(radius * cos(currentAngle))
            let y = center.y + CGFloat(radius * sin(currentAngle))
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        path.closeSubpath()
        return path
    }
}
