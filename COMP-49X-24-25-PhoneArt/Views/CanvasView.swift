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
    @State internal var shapeRotation: Double = 0
    @State internal var shapeScale: Double = 1.0
    @State internal var shapeLayer: Double = 0
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
    /// Add zoom gesture center for proper scaling around touch point
    @State private var zoomCenter: CGPoint = .zero
    /// Track pinch gesture location for proper zooming
    @GestureState private var gesturePinchLocation: CGPoint = .zero
    /// Add state for current rotation angle (in degrees)
    @State private var currentRotation: Angle = .degrees(0)
    /// Add state to track starting rotation angle during rotation gesture
    @State private var startRotation: Angle = .degrees(0)
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
    @State internal var selectedShape: ShapesPanel.ShapeType = .capsule  // Default to capsule
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
    @State internal var loadedArtworkData: ArtworkData? = nil
    // Add state for tracking photo saving
    @State private var isSavingPhoto = false
   
    // Add state variables to handle gallery full selection
    @State private var galleryFullArtworks: [ArtworkData] = []
    @State private var showGalleryFullAlert = false
    @State private var pendingArtworkData: (String, String?) = ("", nil) // (artworkString, title)
    @State private var showArtworkReplaceSheet = false
    @State private var galleryThumbnails: [String: UIImage] = [:] // Dictionary to store thumbnails [artworkId: UIImage]
    
    // Add state variables for the artwork one change ago
    @State private var previousArtworkState: (selectedShape: ShapesPanel.ShapeType, shapeRotation: Double, shapeScale: Double, shapeLayer: Double, shapeSkewX: Double, shapeSkewY: Double, shapeSpread: Double, shapeHorizontal: Double, shapeVertical: Double, shapePrimitive: Double, colorPresets: [Color], backgroundColor: Color, strokeWidth: Double, strokeColor: Color, shapeAlpha: Double)? = nil
    @State private var showUndoButton: Bool = false

    // Add these state variables after the other @State declarations around line 80-90
    @State internal var hasUnsavedChanges = false
    @State private var lastCheckedArtworkString: String? = nil
    
    // Track initial state for new artworks
    @State private var hasRecordedInitialState = false
    @State private var initialArtworkString: String? = nil
   
    // Add scene phase environment property for monitoring app lifecycle
    @Environment(\.scenePhase) private var scenePhase
    // Add alert for restoration dialog
    @State private var showRestorationAlert = false
   
    // State for zoom slider visibility and timer
    //@State private var showZoomSlider = false
    //@State private var lastZoomInteractionTime = Date.distantPast
    
    // Timer publisher fires every second
    //private let zoomSliderTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
   
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
        // Increase the offset when any bottom panel is open
        let raisedPanelOffset: CGFloat = -150 // Raise more when a panel is open
        let standardPanelOffset: CGFloat = -50
        let result: CGFloat
        if showGalleryPanel || showProperties || showColorShapes || showShapesPanel {
            result = raisedPanelOffset
        } else {
            result = 0 // No panel, no offset
        }
        // print("DEBUG: Canvas vertical offset: \(result) - panels: \(showGalleryPanel ? \"gallery\" : \"\")\(showProperties ? \"properties\" : \"\")\(showColorShapes ? \"colorShapes\" : \"\")\(showShapesPanel ? \"shapesPanel\" : \"\")")
        return result
    }
     /// Computed minimum zoom level to fit canvas width to screen width
    private var minZoomLevel: Double {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let canvasWidth: CGFloat = 1600
        let canvasHeight: CGFloat = 1800
        
        let widthRatio = screenWidth / canvasWidth
        let heightRatio = screenHeight / canvasHeight
        
        // Return the smaller ratio to ensure canvas fits within screen
        return max(0.1, min(widthRatio, heightRatio) * 0.8)
    }
     // Make internal for testing
    internal func validateZoom(_ zoom: Double) -> Double {
        // Check for NaN values and replace with default 1.0
        if zoom.isNaN {
            print("DEBUG: NaN value detected in zoom, replacing with default 1.0")
            return 1.0
        }
        
        let maxZoom: Double = 5.0  // Increased max zoom for more flexibility
        return max(minZoomLevel, min(maxZoom, zoom))
    }
     // MARK: - Body
    var body: some View {
        // Wrap the entire content in a GeometryReader to get screen dimensions
        GeometryReader { geometry in
            ZStack {
                // Pass geometry down to canvasArea
                canvasArea(geometry: geometry)

                topControls()
                bottomControls()
                panelOverlays()
            }
            .ignoresSafeArea()
            // Keep modifiers attached to the main ZStack
            .alert("Save Artwork", isPresented: $showingSavePrompt) { saveArtworkAlertContent() }
            .alert(alertTitle, isPresented: $showAlert) { unsavedChangesAlertButtons() } message: { Text(alertMessage) }
            .alert("Gallery Full", isPresented: $showGalleryFullAlert) { galleryFullAlertButtons() } message: { galleryFullAlertMessage() }
            .alert("Restore Previous Work", isPresented: $showRestorationAlert) { restorationAlertButtons() } message: { restorationAlertMessage() }
            .onChange(of: scenePhase) { oldPhase, newPhase in handleScenePhaseChange(newPhase: newPhase) }
            //.onReceive(zoomSliderTimer) { _ in handleZoomTimerTick() }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ColorPresetsChanged"))) { _ in handleColorPresetsChanged() }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("BackgroundColorChanged"))) { _ in handleBackgroundColorChanged() }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("StrokeSettingsChanged"))) { _ in handleStrokeSettingsChanged() }
            .sheet(isPresented: $showArtworkReplaceSheet) { artworkReplaceSheetContent() }
            .overlay { modalOverlays() } // Extracted modal overlays (Share ID, Import)
            .onChange(of: shapeRotation) { _, _ in checkForUnsavedChanges() }
            .onChange(of: shapeScale) { _, _ in checkForUnsavedChanges() }
            .onChange(of: shapeLayer) { _, _ in checkForUnsavedChanges() }
            .onChange(of: shapeSkewX) { _, _ in checkForUnsavedChanges() }
            .onChange(of: shapeSkewY) { _, _ in checkForUnsavedChanges() }
            .onChange(of: shapeSpread) { _, _ in checkForUnsavedChanges() }
            .onChange(of: shapeHorizontal) { _, _ in checkForUnsavedChanges() }
            .onChange(of: shapeVertical) { _, _ in checkForUnsavedChanges() }
            .onChange(of: shapePrimitive) { _, _ in checkForUnsavedChanges() }
            .onChange(of: selectedShape) { _, _ in checkForUnsavedChanges() }
            .onChange(of: currentRotation) { _, _ in checkForUnsavedChanges() }
            // Note: .onChange for panel visibility (showProperties, etc.) removed as they only contained empty animations
        }
    }

    // MARK: - Extracted View Builders

    @ViewBuilder
    private func canvasArea(geometry: GeometryProxy) -> some View { // Receive geometry
        // Use local GeometryReader for canvas size if needed, but use outer geometry for offset calculation
        GeometryReader { canvasGeometry in // This inner reader is for the canvas element itself
            colorPresetManager.backgroundColor
                .frame(
                    width: 2400,
                    height: 2600
                )
                .contentShape(Rectangle())
                .onAppear {
                    // DEBUG: Log canvas background frame on appear
                    print("DEBUG: Canvas background frame initialized - size: 2400x2600")
                }

            Canvas { context, size in
                // DEBUG: Log when canvas is being drawn
                print("DEBUG: Canvas drawing - size: \(size), zoomLevel: \(zoomLevel)")
                drawShapes(context: context, size: size)
            }
            .accessibilityIdentifier("Canvas")
            .frame(width: 1600, height: 1800)
            .border(Color(uiColor: .label), width: 2)
            .scaleEffect(zoomLevel)
            .onChange(of: zoomLevel) { oldValue, newValue in
                // DEBUG: Log when scale effect changes
                print("DEBUG: Scale effect changed - oldZoom: \(oldValue), newZoom: \(newValue)")
            }
            .rotationEffect(currentRotation) // Apply rotation
            // Calculate and apply offset using the new function and outer geometry
            .offset(x: offset.width, y: offset.height + calculateCanvasVerticalOffset(geometry: geometry))
            .animation(.easeInOut(duration: 0.25), value: showProperties || showColorShapes || showShapesPanel || showGalleryPanel) // Animate based on panel visibility
        }
        .contentShape(Rectangle())
        // Combine all gestures properly using ExclusiveGesture and SimultaneousGesture
        .gesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in handleDragChange(value: value) }
                .onEnded { value in handleDragEnd(value: value) }
        )
        // Use an ExclusiveGesture to combine magnification and rotation, which ensures they don't conflict
        .gesture(
            SimultaneousGesture(
                MagnificationGesture()
                    .onChanged { value in handleZoomChange(value: value) }
                    .onEnded { value in handleZoomEnd(value: value) },
                RotationGesture()
                    .onChanged { angle in handleRotationChange(angle: angle) }
                    .onEnded { angle in handleRotationEnd(angle: angle) }
            )
        )
        .onAppear { handleOnAppear() }
        .onTapGesture(count: 2) {
            // Double tap to reset zoom
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                // Ensure we reset to valid zoom values
                zoomLevel = 1.0
                startingZoomLevel = 1.0
                print("DEBUG: Double tap reset - zoom level reset to 1.0")
            }
        }
    }

    @ViewBuilder
    private func topControls() -> some View {
        // Share button in upper left corner
        VStack(spacing: 10) {
            makeShareButton()
                .padding(.bottom, 0) // Reduced padding to accommodate labels
        }
        .padding(.top, 50)
        .padding(.leading, 20)
        .frame(width: 60) // Add width to accommodate text labels
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

        // Reset button in upper right
        VStack(spacing: 20) { // Increased spacing to match other buttons (was 8)
            // Center button
            VStack(spacing: 4) {
                makeResetButton()
                Text("Center")
                    .font(.system(size: 10))
                    .foregroundColor(.black)
            }
            
            // Randomize icon button with label
            VStack(spacing: 4) {
                Button(action: {
                    let suppressKey = "SuppressRandomizeWarningUntil"
                    let now = Date()
                    if let suppressUntil = UserDefaults.standard.object(forKey: suppressKey) as? Date, suppressUntil > now {
                        createRandomizedArtwork()
                        // No pop-up if suppressed
                        return
                    }
                    if hasUnsavedChanges {
                        alertTitle = "Randomize Artwork?"
                        alertMessage = "You have unsaved changes. Randomizing will overwrite your current work and you will lose your unsaved changes. Are you sure you want to continue?"
                        showAlert = true
                        UnsavedChangesHandler.proceedAction = {
                            createRandomizedArtwork()
                            alertTitle = "Randomized"
                            alertMessage = "Artwork has been randomized."
                            showAlert = true
                        }
                        // Add a special action for 'Don't warn me for 24 hours'
                        UnsavedChangesHandler.saveExistingArtworkAction = {
                            let suppressUntil = Calendar.current.date(byAdding: .hour, value: 24, to: now) ?? now.addingTimeInterval(24*60*60)
                            UserDefaults.standard.set(suppressUntil, forKey: suppressKey)
                            createRandomizedArtwork()
                        }
                    } else {
                        createRandomizedArtwork()
                        // No pop-up if there were no unsaved changes
                    }
                }) {
                    Rectangle()
                        .foregroundColor(.clear)
                        .frame(width: 40, height: 40) // Matches Reset button size
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            Image(systemName: "shuffle")
                                .font(.system(size: 20)) // Matches Reset button icon size
                                .foregroundColor(Color(uiColor: .systemBlue))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(uiColor: .systemGray3), lineWidth: 0.5)
                        )
                }
                .accessibilityIdentifier("Randomize Button")
                
                Text("Shuffle")
                    .font(.system(size: 10))
                    .foregroundColor(.black)
            }

            // Undo icon button (only appears when needed)
            if hasUnsavedChanges, let loadedArtwork = loadedArtworkData {
                VStack(spacing: 4) {
                    Button(action: {
                        // Show confirmation alert before undoing
                        alertTitle = "Undo Changes?"
                        alertMessage = "You have unsaved changes. Undoing will revert to your last saved artwork and you will lose your current work. Are you sure you want to continue?"
                        showAlert = true
                        // Set up the proceed action for the alert
                        UnsavedChangesHandler.proceedAction = {
                            applyLoadedArtwork(loadedArtwork)
                            alertTitle = "Undo Successful"
                            alertMessage = "Artwork reverted to last saved state."
                            showAlert = true
                        }
                    }) {
                        Rectangle()
                            .foregroundColor(.clear) // Match style
                            .frame(width: 40, height: 40) // Match size
                            .background(Color(uiColor: .systemBackground))
                            .cornerRadius(8)
                            .overlay(
                                Image(systemName: "arrow.uturn.backward")
                                    .font(.system(size: 20)) // Match icon size
                                    .foregroundColor(Color(uiColor: .systemOrange)) // Different color for distinction
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(uiColor: .systemGray3), lineWidth: 0.5)
                            )
                    }
                    .accessibilityIdentifier("Undo Button")
                    
                    Text("Undo")
                        .font(.system(size: 10))
                        .foregroundColor(.black)
                }
            }
        }
        .frame(width: 60) // Increased width to accommodate text labels
        .padding(.top, 50)
        .padding(.trailing, 15) 
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }

    @ViewBuilder
    private func bottomControls() -> some View {
        VStack(spacing: 8) {
            Spacer()

            makeArtworkInfoBanner()
                .padding(.bottom, 4)
                .zIndex(2)

            HStack(alignment: .center, spacing: 0) {
                Spacer()
                makePropertiesButton()
                Spacer()
                makeColorShapesButton()
                Spacer()
                makeShapesButton()
                Spacer()
                makeGalleryButton()
                Spacer()
                makeCloseButton()
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }

    @ViewBuilder
    private func panelOverlays() -> some View {
        if showProperties {
            panelOverlay {
                PropertiesPanel(
                    rotation: $shapeRotation, scale: $shapeScale, layer: $shapeLayer,
                    skewX: $shapeSkewX, skewY: $shapeSkewY, spread: $shapeSpread,
                    horizontal: $shapeHorizontal, vertical: $shapeVertical, primitive: $shapePrimitive,
                    isShowing: $showProperties,
                    onSwitchToColorShapes: switchToColorShapes, onSwitchToShapes: switchToShapes, onSwitchToGallery: switchToGallery
                )
            }
        }

        if showColorShapes {
            panelOverlay {
                ColorPropertiesPanel(
                    isShowing: $showColorShapes, selectedColor: $shapeColor,
                    onSwitchToProperties: switchToProperties, onSwitchToShapes: switchToShapes, onSwitchToGallery: switchToGallery
                )
            }
        }

        if showShapesPanel {
            panelOverlay {
                ShapesPanel(
                    selectedShape: $selectedShape, isShowing: $showShapesPanel,
                    onSwitchToProperties: switchToProperties, onSwitchToColorProperties: switchToColorShapes, onSwitchToGallery: switchToGallery
                )
            }
        }

        if showGalleryPanel {
            panelOverlay {
                GalleryPanel(
                    isShowing: $showGalleryPanel, confirmedArtworkId: $confirmedArtworkId,
                    onSwitchToProperties: switchToProperties, onSwitchToColorShapes: switchToColorShapes,
                    onSwitchToShapes: switchToShapes, onLoadArtwork: loadArtwork
                )
            }
        }
    }

    @ViewBuilder
    private func modalOverlays() -> some View {
        ZStack {
            if let confirmedId = confirmedArtworkId {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { confirmedArtworkId = nil }

                SaveConfirmationView(
                    artworkId: confirmedId.id,
                    title: "Share Your Artwork Code",
                    message: "Copy this ID and share it with friends so they can view and import your artwork!"
                ) { confirmedArtworkId = nil }
                .transition(.opacity.animation(.easeInOut))
            }

            if showImportSheet {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { showImportSheet = false }

                ImportArtworkView(
                    // Create and configure the ViewModel here
                    viewModel: {
                        let vm = ImportArtworkViewModel(firebaseService: FirebaseService.shared)
                        vm.onImportSuccess = { artworkString in
                           self.handleImportedArtwork(artworkString)
                           self.showImportSheet = false // Close sheet on success
                        }
                        vm.onCancel = {
                           self.showImportSheet = false // Close sheet on cancel
                       }
                       vm.onError = { errorMessage in
                           // Optionally handle errors here, e.g., show an alert
                           print("Import Error: \(errorMessage)")
                           // Maybe show the alert already handled by the VM, or a different one
                           // self.alertTitle = "Import Failed"
                           // self.alertMessage = errorMessage
                           // self.showAlert = true
                           self.showImportSheet = false // Close sheet on error too
                       }
                       return vm
                   }() // Immediately invoke the closure to get the configured ViewModel
                )
                .transition(.opacity.animation(.easeInOut))
            }
        }
    }
    
    // MARK: - Alert Content Builders (Helper functions for alert modifiers)

    @ViewBuilder
    private func saveArtworkAlertContent() -> some View {
        TextField("Enter Artwork Title (Optional)", text: $artworkTitleInput)
            .autocapitalization(.words)
            .accessibilityIdentifier("Artwork Title TextField")
        Button("Cancel", role: .cancel) { }
        Button("Save") {
            let titleToSave = artworkTitleInput.trimmingCharacters(in: .whitespacesAndNewlines)
            saveArtwork(title: titleToSave.isEmpty ? nil : titleToSave, forceSaveAsNew: true)
        }
        .accessibilityIdentifier("Save Artwork Button")
    }

    @ViewBuilder
    private func unsavedChangesAlertButtons() -> some View {
        if alertTitle == "Undo Changes?" {
            Button("Cancel", role: .cancel) {}
            Button("Undo", role: .destructive) {
                UnsavedChangesHandler.proceedAction?()
                UnsavedChangesHandler.proceedAction = nil
            }
        } else if alertTitle == "Randomize Artwork?" {
            Button("Cancel", role: .cancel) {}
            Button("Randomize", role: .destructive) {
                UnsavedChangesHandler.proceedAction?()
                UnsavedChangesHandler.proceedAction = nil
            }
            Button("Don't warn me for 24 hours") {
                UnsavedChangesHandler.saveExistingArtworkAction?()
                UnsavedChangesHandler.saveExistingArtworkAction = nil
            }
        } else if alertTitle.contains("Unsaved Changes") ||
           alertTitle == "Import Artwork Code" ||
           alertTitle == "Create New Artwork" ||
           alertTitle == "Share Artwork" ||
           alertTitle == "Share Modified Artwork" {
            UnsavedChangesHandler.alertButtons()
        } else {
            Button("OK", role: .cancel) {}
        }
    }

    @ViewBuilder
    private func galleryFullAlertButtons() -> some View {
        Button("Cancel", role: .cancel) {}
        Button("View Gallery & Replace") {
            showArtworkReplaceSheet = true
        }
    }

    @ViewBuilder
    private func galleryFullAlertMessage() -> some View {
         Text("You've reached the limit of 12 saved artworks. Please select an artwork to replace or cancel.")
    }
    
    @ViewBuilder
    private func restorationAlertButtons() -> some View {
        UnsavedChangesHandler.restorationAlertButtons()
    }

    @ViewBuilder
    private func restorationAlertMessage() -> some View {
        Text("We found unsaved work from your previous session. Would you like to restore it?")
    }

    @ViewBuilder
    private func artworkReplaceSheetContent() -> some View {
        ArtworkReplaceSheet(
            artworks: galleryFullArtworks,
            thumbnails: galleryThumbnails,
            onSelect: { selectedArtwork in replaceArtwork(with: selectedArtwork) },
            onCancel: { showArtworkReplaceSheet = false }
        )
    }
    
    // MARK: - Event Handlers (for extracted logic)

    private func handleZoomChange(value: MagnificationGesture.Value) {
        // Check for NaN value in the pinch gesture
        if value.isNaN {
            print("DEBUG: NaN value detected in magnification gesture, ignoring update")
            return
        }
        
        // Check for extreme magnification values (when fingers are too close or too far apart)
        if value < 0.01 || value > 100 {
            print("DEBUG: Extreme magnification value detected: \(value), ignoring update")
            return
        }
        
        let newZoom = startingZoomLevel * value
        zoomLevel = validateZoom(newZoom)
        
        // DEBUG: Log zoom changes
        print("DEBUG: Zoom changing - value: \(value), startingZoom: \(startingZoomLevel), newZoom: \(newZoom), validated: \(zoomLevel)")
    }

    private func handleZoomEnd(value: MagnificationGesture.Value) {
        // Check for NaN value in the pinch gesture
        if value.isNaN {
            print("DEBUG: NaN value detected in magnification gesture end, resetting to previous value")
            return
        }
        
        // Update the starting zoom value for the next gesture
        startingZoomLevel = zoomLevel
        
        // DEBUG: Log final zoom level after gesture
        print("DEBUG: Zoom ended - final zoomLevel: \(zoomLevel), offset: \(offset)")
    }

    private func handleRotationChange(angle: Angle) {
        // Check for extreme or NaN angles that could occur during combined gestures
        if angle.degrees.isNaN {
            print("DEBUG: NaN angle detected in rotation gesture, ignoring update")
            return
        }
        
        // Check for physically impossible angle changes (much higher threshold)
        if abs(angle.degrees) > 180 {
            print("DEBUG: Physically impossible rotation detected: \(angle.degrees), ignoring update")
            return
        }
        
        withAnimation(.interactiveSpring()) {
            // Combine the starting rotation with the change detected by the gesture
            currentRotation = startRotation + angle
            
            // Check bounds to allow continuous rotation
            if currentRotation.degrees > 360 {
                currentRotation = Angle(degrees: currentRotation.degrees.truncatingRemainder(dividingBy: 360))
                startRotation = currentRotation - angle
            } else if currentRotation.degrees < -360 {
                currentRotation = Angle(degrees: currentRotation.degrees.truncatingRemainder(dividingBy: 360))
                startRotation = currentRotation - angle
            }
        }
    }

    private func handleRotationEnd(angle: Angle) {
        // Check for NaN angles
        if angle.degrees.isNaN {
            print("DEBUG: NaN angle detected in rotation gesture end, ignoring update")
            return
        }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            // Update the starting rotation for the next gesture
            startRotation = currentRotation
        }
    }

    private func handleOnAppear() {
        let hasPopulatedKey = "HasPopulatedPremadeArtworks"
        let userDefaults = UserDefaults.standard
        if !userDefaults.bool(forKey: hasPopulatedKey) {
            userDefaults.set(true, forKey: hasPopulatedKey)
            let premadeArtworks = [
                ("Artwork1", "alpha:0.25675666332244873;background:#FEFFFF;colors:#D2D5FF,#4B20B5,#FF0275,#FA00F8,#000000,#DDC90A,#02CD23,#1F36BE,#13DA79,#0BCC9D;horizontal:67.46985912322998;hueAdj:1.0;layer:42.62637376785278;presetCount:5;primitive:5.0;rainbowStyle:0;rotation:212.94913530349731;satAdj:1.0;scale:1.759589046239853;shape:rectangle;skewX:11.124992370605469;skewY:0.0;spread:26.923072338104248;strokeColor:#FEFFFF;strokeWidth:0.0;useRainbow:false;vertical:0.0"),
                ("Artwork2", "alpha:0.49710142612457275;background:#B0DD8B;colors:#B72CC0,#67BF17,#0FE592,#29BEB0,#17C03B,#D64A16,#25BE91,#C52FD8,#B63407,#D83E8B;horizontal:0.0;hueAdj:0.748697817325592;layer:25.96246576309204;presetCount:5;primitive:6.0;rainbowStyle:0;rotation:170.06492614746094;satAdj:1.0;scale:1.725267231464386;shape:arrow;skewX:0.0;skewY:0.0;spread:6.101185828447342;strokeColor:#D64A16;strokeWidth:0.0;useRainbow:true;vertical:0.0"),
                ("Artwork3", "alpha:0.93;background:#EA1600;colors:#A23423,#B73317,#D22F8C,#345EDF,#CE2E6F,#B61B90,#E00204,#168FCA,#2BE409,#92D202;horizontal:0.0;hueAdj:0.2554806172847748;layer:30.29156184196472;presetCount:1;primitive:5.0;rainbowStyle:0;rotation:5.000000037252903;satAdj:1.0;scale:1.3360967636108398;shape:star;skewX:25.0;skewY:0.0;spread:5.0;strokeColor:#FEFFFF;strokeWidth:2.0;useRainbow:false;vertical:0.0"),
                ("Artwork4", "alpha:1.0;background:#E291FE;colors:#E569E4,#DA219A,#6923C1,#4056DC,#D4793D,#CC4B15,#C75392,#CE5A33,#1AD0C6,#BD295A;horizontal:0.0;hueAdj:1.0;layer:67.35163736343384;presetCount:9;primitive:3.0;rainbowStyle:0;rotation:17.694917768239975;satAdj:1.0;scale:1.1760272234678268;shape:star;skewX:0.0;skewY:33.0217981338501;spread:10.000000894069672;strokeColor:#BD295A;strokeWidth:0.0;useRainbow:false;vertical:0.0")
            ]
            Task {
                var savedArtworks: [ArtworkData] = []
                for (title, art) in premadeArtworks {
                    if let (docRef, _, _) = try? await firebaseService.saveArtwork(artworkData: art, title: title) {
                        let newArtwork = ArtworkData(
                            deviceId: firebaseService.getDeviceId(),
                            artworkString: art,
                            timestamp: Date(),
                            title: title,
                            pieceId: docRef?.documentID
                        )
                        savedArtworks.append(newArtwork)
                    }
                }
                if let randomArt = savedArtworks.randomElement() {
                    await MainActor.run {
                        self.loadedArtworkData = randomArt
                        self.applyLoadedArtwork(randomArt)
                    }
                }
            }
        } else {
            loadInitialArtwork()
        }
    }

    private func handleScenePhaseChange(newPhase: ScenePhase) {
        if newPhase == .background || newPhase == .inactive {
            saveCurrentStateForRestoration()
        }
    }
    
    private func handleColorPresetsChanged() {
        colorUpdateTrigger = UUID()
        checkForUnsavedChanges()
    }

    private func handleBackgroundColorChanged() {
        backgroundColorTrigger = UUID()
        checkForUnsavedChanges()
    }

    private func handleStrokeSettingsChanged() {
        strokeSettingsTrigger = UUID()
        checkForUnsavedChanges()
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
 
        // DEBUG: Log canvas center point
        print("DEBUG: Drawing shapes - center: \(center), size: \(size)")
 
        // Draw center point of the canvas
        // drawCenterDot(context: context, at: center, color: .black)
 
        let numberOfLayers = max(0, min(72, Int(shapeLayer)))
        
        // DEBUG: Log layer count
        print("DEBUG: Shape layers to draw: \(numberOfLayers)")
        
        if numberOfLayers > 0 {
            drawLayers(
                context: context,
                layers: numberOfLayers,
                center: center,
                radius: circleRadius
            )
        } else {
            // DEBUG: Warning if no layers to draw
            print("DEBUG: WARNING - No layers to draw (shapeLayer value: \(shapeLayer))")
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
        
        // DEBUG: Log layer drawing parameters
        print("DEBUG: drawLayers - layers: \(layers), primitiveCount: \(primitiveCount), center: \(center), radius: \(radius)")
  
        for layerIndex in 0..<layers {
            // For each primitive in the current layer, draw evenly spaced shapes
            for primitiveIndex in 0..<primitiveCount {
                // Calculate the angle offset for each primitive shape (evenly distributed across 360°)
                let primitiveAngleOffset = (360.0 / Double(primitiveCount)) * Double(primitiveIndex)
                
                // DEBUG: Occasionally log a sample of shapes being drawn (to avoid console flood)
                if layerIndex == 0 || layerIndex == layers-1 {
                    if primitiveIndex == 0 {
                        print("DEBUG: Drawing shape - layer: \(layerIndex), primitive: \(primitiveIndex), angleOffset: \(primitiveAngleOffset)")
                    }
                }
  
                drawSingleShape(
                    context: context,
                    layerIndex: layerIndex,
                    primitiveAngleOffset: primitiveAngleOffset,
                    center: center,
                    radius: radius
                )
            }
        }
        
        // DEBUG: Log completion of layer drawing
        print("DEBUG: Finished drawing \(layers) layers with \(primitiveCount) primitives each")
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
        let scaleFactor = 0.20  // Reduced from 0.25 to 0.125 to halve the scale effect strength
        let layerScale = pow(1.0 + (shapeScale - 1.0) * scaleFactor, Double(layerIndex + 1))
        let scaledRadius = radius * layerScale
  
        // Apply spread to move shapes away from center
        let spreadDistance = max(shapeSpread * Double(layerIndex), Double(layerIndex))
        let spreadX = spreadDistance * cos(angleInRadians)
        let spreadY = spreadDistance * sin(angleInRadians)
  
        // Calculate final position with horizontal and vertical offsets
        let finalX = center.x + scaledRadius * cos(angleInRadians) + spreadX + shapeHorizontal
        let finalY = center.y + scaledRadius * sin(angleInRadians) + spreadY - shapeVertical
        
        // DEBUG: Log if shape position is outside reasonable bounds
        let maxBound = 10000.0  // A reasonable upper bound for canvas coordinates
        if abs(finalX) > maxBound || abs(finalY) > maxBound || finalX.isNaN || finalY.isNaN {
            print("DEBUG: WARNING - Shape out of bounds or invalid - position: (\(finalX), \(finalY)), layerIndex: \(layerIndex)")
            return // Skip drawing this shape if it's out of bounds
        }
        
        // DEBUG: Occasionally log sample shape positions (to avoid console flood)
        if layerIndex % 10 == 0 && angleInDegrees < 10 {
            print("DEBUG: Shape position - layer: \(layerIndex), position: (\(finalX), \(finalY)), radius: \(scaledRadius)")
        }
 
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
        case .capsule:
             // Create a capsule shape within the baseRect
             // Adjust the height slightly to make it visually distinct from oval
             let capsuleRect = CGRect(
                 x: finalX - scaledRadius * 0.8, // Slightly narrower
                 y: finalY - scaledRadius, // Full height
                 width: scaledRadius * 1.6, // Slightly narrower
                 height: scaledRadius * 2
             )
             shapePath = Capsule(style: .continuous).path(in: capsuleRect)
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
            // Convert degrees directly to radians for 1:1 mapping
            let skewXRad = shapeSkewX * (.pi / 180) 
            let skewYRad = shapeSkewY * (.pi / 180)
   
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
    
        // Determine the final opacity for this layer
        let baseOpacity = colorPresetManager.shapeAlpha  // Get the global alpha setting
        
        // Modified opacity calculation:
        // When baseOpacity is 1.0 (100%), don't reduce opacity for layers
        // When baseOpacity is less than 1.0, use the existing falloff logic
        let layerOpacity: Double
        if baseOpacity >= 0.99 {  // Using 0.99 instead of 1.0 to account for floating point imprecision
            layerOpacity = 1.0  // Keep all layers fully opaque when alpha is 100%
        } else {
            // For alpha < 100%, maintain the existing behavior with reduced opacity for deeper layers
            layerOpacity = layerIndex == 0 ? baseOpacity : baseOpacity * 0.8
        }

        // Explicitly construct the final color with the calculated layerOpacity,
        // ignoring any potential alpha component in the original layerColor.
        let finalColor = layerColor.opacity(layerOpacity)

        // Fill the shape with the explicitly constructed final color
        layerContext.fill(transformedPath, with: .color(finalColor))
        
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
        
        // DEBUG: Log significant drag changes
        if abs(value.translation.width) > 50 || abs(value.translation.height) > 50 {
            print("DEBUG: Significant drag - translation: \(value.translation), new offset: \(offset)")
            logCanvasPosition()
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
        
        // DEBUG: Log final position after drag
        print("DEBUG: Drag ended - final offset: \(offset)")
        logCanvasPosition()
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
            
            // Reset rotation to original position (0 degrees)
            currentRotation = .degrees(0)
            startRotation = .degrees(0)
            
            // Check if current zoom level is NaN and fix it
            if zoomLevel.isNaN {
                print("DEBUG: NaN value detected in zoomLevel during reset, fixing to 1.0")
                zoomLevel = 1.0
                startingZoomLevel = 1.0
            }
            
            // Removed zoom reset - keep current zoom level
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
                    Image(systemName: "paintpalette")
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
            VStack(spacing: 4) {
                Menu {
                    Button(action: resetCanvasToDefault) {
                        Label("New Canvas", systemImage: "doc.badge.plus")
                    }
                    .accessibilityIdentifier("New Canvas Button")

                    Button(action: { showImportSheet = true }) {
                        Label("Import Artwork Code...", systemImage: "square.and.arrow.down") // Icon indicates retrieving
                    }
                    .accessibilityIdentifier("Import Button")
                
                } label: {
                    buttonIcon(systemName: "plus") // Keep the plus icon for the menu
                }
                .accessibilityIdentifier("New/Import Menu")
                
                Text("New")
                    .font(.system(size: 10))
                    .foregroundColor(.black)
            }

            // --- Share Button (for showing artwork ID) ---
            VStack(spacing: 4) {
                Button(action: showShareArtworkID) {
                    buttonIcon(systemName: "square.and.arrow.up")
                }
                .accessibilityIdentifier("Share Button")
                
                Text("Share")
                    .font(.system(size: 10))
                    .foregroundColor(.black)
            }
            
            // --- Save Button Menu ---
            VStack(spacing: 4) {
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
                    
                } label: {
                    buttonIcon(systemName: "arrow.down.to.line")
                }
                .accessibilityIdentifier("Save Menu Button")
                
                Text("Save")
                    .font(.system(size: 10))
                    .foregroundColor(.black)
            }
        }
    }

    /// Shows the artwork ID for sharing
    private func showShareArtworkID() {
        // If we have an existing artwork
        if let existingArtwork = loadedArtworkData, let pieceId = existingArtwork.pieceId {
            // Check if there are unsaved changes before sharing
            if hasUnsavedChanges {
                // If there are unsaved changes, prompt the user to save or share the previous version
                _ = UnsavedChangesHandler.alertButtons()
            } else {
                // No unsaved changes, show the ID directly
                confirmedArtworkId = IdentifiableArtworkID(id: pieceId)
                return
            }
        }
        
        // If there's no existing artwork with an ID, we need to save it first
        // Check if there are unsaved changes
        _ = UnsavedChangesHandler.checkUnsavedChanges(
            hasUnsavedChanges: true, // Always consider this a potential data operation
            action: .shareArtwork, // Use the specific share artwork action type
            showAlert: $showAlert,
            alertTitle: $alertTitle,
            alertMessage: $alertMessage,
            onProceed: {
                // We still need to save, but the user chose to proceed without saving
                alertTitle = "Cannot Share"
                alertMessage = "To share artwork, you need to save it first. Tap the save button (↓) below and select Save as New."
                showAlert = true
            },
            onSaveFirst: {
                // Save directly as new artwork without prompting for title
                let artworkString = getCurrentArtworkString()
                Task {
                    do {
                        let (docRef, isGalleryFull, existingArtworks) = try await firebaseService.saveArtwork(artworkData: artworkString, title: "Untitled Artwork")
                        
                        if isGalleryFull {
                            // Gallery is full, show alert
                            await MainActor.run {
                                galleryFullArtworks = existingArtworks
                                generateThumbnails(for: existingArtworks)
                                showGalleryFullAlert = true
                            }
                        } else if let pieceRef = docRef {
                            let newPieceId = pieceRef.documentID
                            
                            // Update state on the main thread
                            await MainActor.run {
                                // Update the loadedArtworkData state
                                self.loadedArtworkData = ArtworkData(
                                    deviceId: firebaseService.getDeviceId(),
                                    artworkString: artworkString,
                                    timestamp: Date(),
                                    title: "Untitled Artwork",
                                    pieceId: newPieceId
                                )
                                
                                // Reset unsaved changes flag
                                self.hasUnsavedChanges = false
                                self.lastCheckedArtworkString = artworkString
                                
                                // Show the share ID confirmation
                                self.confirmedArtworkId = IdentifiableArtworkID(id: newPieceId)
                            }
                        }
                    } catch {
                        // Display error alert
                        await MainActor.run {
                            alertTitle = "Error Saving"
                            alertMessage = error.localizedDescription
                            showAlert = true
                        }
                    }
                }
            }
        ) // Removed the trailing closure here as it's not needed after assigning to _
        // { // Trailing closure `onNoActionNeeded` - This part is now handled inside the check
        //     // If we get here, there were no unsaved changes and no artwork ID
        //     // This is an edge case - there are no unsaved changes but also no ID
        //     alertTitle = "Cannot Share"
        //     alertMessage = "To share artwork, you need to save it first. Tap the save button (↓) below and select Save as New."
        //     showAlert = true
        // }
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
    internal func saveArtwork(title: String? = nil, forceSaveAsNew: Bool = false) {
        let artworkString = getCurrentArtworkString()
        
        // Check if we're working with an existing artwork that should be updated
        if !forceSaveAsNew, let existingArtwork = loadedArtworkData, let pieceId = existingArtwork.pieceId {
            // Use existing artwork's title if no new title provided
            let titleToUse = title ?? existingArtwork.title
            
            // Update the existing artwork instead of creating a new one
            Task {
                do {
                    try await firebaseService.updateArtwork(artwork: existingArtwork, newArtworkString: artworkString)
                    
                    // Wrap state updates in MainActor.run to ensure UI refreshes
                    await MainActor.run {
                        // Update the loadedArtworkData state to reflect the updated piece
                        self.loadedArtworkData = ArtworkData(
                            deviceId: existingArtwork.deviceId,
                            artworkString: artworkString,
                            timestamp: Date(), // Use current time for the update
                            title: titleToUse,
                            pieceId: pieceId
                        )
                        
                        // Reset unsaved changes flag since we just updated the artwork
                        self.hasUnsavedChanges = false
                        self.lastCheckedArtworkString = artworkString
                        
                        // Execute any pending action after saving
                        if let pendingAction = UnsavedChangesHandler.proceedAction {
                            // Call the pending action (e.g., load imported artwork)
                            pendingAction()
                            // Clear the pending action to prevent duplicate execution
                            UnsavedChangesHandler.proceedAction = nil
                            UnsavedChangesHandler.saveFirstAction = nil
                            UnsavedChangesHandler.saveExistingArtworkAction = nil // Clear this too
                        } else {
                            // If no pending action, show success feedback
                            alertTitle = "Success"
                            alertMessage = "Artwork '\(titleToUse ?? "Untitled")' updated successfully!"
                            showAlert = true
                        }
                    }
                } catch {
                    await MainActor.run {
                        alertTitle = "Error Updating"
                        alertMessage = error.localizedDescription
                        showAlert = true
                    }
                }
            }
            return // Exit early, we've handled the update
        }
        
        // If we're here, this is a new artwork (or one without a pieceId)
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
                    
                    // Explicitly update state on the main thread to ensure UI updates
                    await MainActor.run {
                        // Update the loadedArtworkData state to reflect the newly saved piece
                        self.loadedArtworkData = ArtworkData(
                            deviceId: firebaseService.getDeviceId(), // Get current device ID
                            artworkString: artworkString,
                            timestamp: Date(), // Use current time
                            title: title,
                            pieceId: newPieceId
                        )
                        
                        // Reset unsaved changes flag since we just saved the artwork
                        self.hasUnsavedChanges = false
                        self.lastCheckedArtworkString = artworkString
                        
                        // Show confirmation ID (optional)
                        self.confirmedArtworkId = IdentifiableArtworkID(id: newPieceId)
                        
                        // Execute any pending action after saving
                        if let pendingAction = UnsavedChangesHandler.proceedAction {
                            // Call the pending action (e.g., reset canvas or load imported artwork)
                            pendingAction()
                            // Clear the pending action to prevent duplicate execution
                            UnsavedChangesHandler.proceedAction = nil
                            UnsavedChangesHandler.saveFirstAction = nil
                            UnsavedChangesHandler.saveExistingArtworkAction = nil // Ensure this is also cleared
                        }
                    }
                    
                    // List pieces (async) - this shouldn't affect UI state
                    await firebaseService.listAllPieces()
                }
            } catch {
                // Display error alert
                DispatchQueue.main.async {
                    alertTitle = "Error Saving"
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }
  
   /// Save artwork to Photos library using ImageRenderer
   private func saveToPhotos() {
       // Set loading state immediately on the main thread
       isSavingPhoto = true
       
       // Define the content to render (must be done on main thread)
       let contentToRender = ZStack {
           colorPresetManager.backgroundColor
           Canvas { context, size in
               drawShapes(context: context, size: size)
           }
       }
       .frame(width: 1600, height: 1800)
       
       // Detach the rendering and saving to a background task
       Task.detached(priority: .userInitiated) {
           // 1. Create the ImageRenderer (can be done in background)
           let renderer = await ImageRenderer(content: contentToRender)
           // Get scale and set it on the main thread, awaiting the operation
           await MainActor.run { // << Add await here
               renderer.scale = UIScreen.main.scale 
           }

           // 2. Render the image (potentially heavy, keep off main thread)
           // Await the rendering process
           let uiImage = await renderer.uiImage 

           // 3. Check if rendering succeeded
           guard let imageToSave = uiImage else {
               // If rendering failed, update UI back on main thread
               await MainActor.run {
                   isSavingPhoto = false
                   alertTitle = "Error"
                   alertMessage = "Failed to render artwork image."
                   showAlert = true
               }
               return // Stop execution
           }

           // 4. Call the ExportService function
           // Use await withCheckedContinuation to bridge the callback
           let success = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
               ExportService.saveImageToPhotoLibrary(image: imageToSave) { success, error in
                   if !success {
                       print("Error saving to photos: \(error?.localizedDescription ?? "Unknown error")")
                   }
                   continuation.resume(returning: success)
               }
           }

           // 5. Update UI on the main thread after saving attempt
           await MainActor.run {
               isSavingPhoto = false // Hide progress view
               if success {
                   alertTitle = "Success"
                   alertMessage = "Artwork saved to Photos successfully!"
               } else {
                   // Error details are logged by ExportService or above
                   alertTitle = "Error"
                   alertMessage = "Failed to save to Photos. Check Photos permissions?"
               }
               showAlert = true // Show the result alert
           }
       }
   }


    // Function to apply imported artwork data to the canvas state
    private func applyImportedArtwork(_ artworkString: String) {
        print("[DEBUG] applyImportedArtwork: Starting to apply artwork string")
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
        
        // Create a new ArtworkData object from the imported string
        self.loadedArtworkData = ArtworkData(
            deviceId: firebaseService.getDeviceId(),
            artworkString: artworkString,
            timestamp: Date(),
            title: "Imported Artwork",
            pieceId: nil // Not saved to database yet
        )
        
        // Set the imported artwork string as the reference point
        lastCheckedArtworkString = artworkString
        
        // Force artwork to be considered "saved" initially after import
        hasUnsavedChanges = false
        
        print("[DEBUG] applyImportedArtwork: Completed with loadedArtworkData set")
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
    internal func loadArtwork(artwork: ArtworkData) {
        // Check for unsaved changes before loading the artwork
        if !UnsavedChangesHandler.checkUnsavedChanges(
            hasUnsavedChanges: hasUnsavedChanges,
            action: .importArtwork,
            showAlert: $showAlert,
            alertTitle: $alertTitle,
            alertMessage: $alertMessage,
            onProceed: {
                // If user confirms, proceed with loading the artwork
                self.applyLoadedArtwork(artwork)
            },
            onSaveFirst: {
                // Check if we're updating existing artwork
                if let existingArtwork = self.loadedArtworkData, existingArtwork.pieceId != nil {
                    // Save existing artwork directly without showing name prompt
                    self.saveArtwork(title: existingArtwork.title)
                    
                    // Store artwork temporarily
                    let tempArtwork = artwork
                    // We'll rely on the save action to proceed with loading after saving
                    UnsavedChangesHandler.proceedAction = {
                        self.applyLoadedArtwork(tempArtwork)
                    }
                } else {
                    // Save first, then load
                    showingSavePrompt = true
                    // Store artwork temporarily
                    let tempArtwork = artwork
                    // We'll rely on the save action to proceed with loading after saving
                    UnsavedChangesHandler.proceedAction = {
                        self.applyLoadedArtwork(tempArtwork)
                    }
                }
            }
        ) {
            // If checkUnsavedChanges returns false, it means an alert is shown
            // So we return early and wait for the user's decision
            return
        }
        
        // If we get here, there were no unsaved changes, so proceed with loading
        applyLoadedArtwork(artwork)
    }
    
    /// Private helper method that performs the actual artwork loading
    private func applyLoadedArtwork(_ artwork: ArtworkData) {
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

        // Set the loaded artwork string as the reference point
        lastCheckedArtworkString = artwork.artworkString
        
        // Force artwork to be considered "saved" initially
        hasUnsavedChanges = false
        
        // Let the UI update before checking for differences
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Debug compare to see if strings match after loading
            let currentString = self.getCurrentArtworkString()
            print("[CanvasView] Checking if loaded artwork matches current state:")
            self.debugCompareArtworkStrings(loaded: artwork.artworkString, current: currentString)
            
            // Check if values actually match
            self.checkForUnsavedChanges()
        }

        print("[CanvasView] Finished loading artwork.")
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
                
                // Update the loadedArtworkData state to reflect the updated piece
                self.loadedArtworkData = ArtworkData(
                    deviceId: artwork.deviceId,
                    artworkString: currentArtworkString,
                    timestamp: Date(), // Use current time for the update
                    title: artwork.title,
                    pieceId: pieceId
                )
                
                // Reset unsaved changes flag since we just updated the artwork
                hasUnsavedChanges = false
                lastCheckedArtworkString = currentArtworkString
                
                await MainActor.run {
                    // Show success feedback
                    alertTitle = "Success"
                    alertMessage = "Artwork '\(artwork.title ?? "Untitled")' updated successfully!"
                    showAlert = true
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
    /// Returns a semicolon-separated string of key-value pairs in a consistent order.
    private func getCurrentArtworkString() -> String {
        // Get the validated data map
        let validatedData = ArtworkData.createValidatedDataMap(
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
        
        // Sort the keys for consistent ordering
        let sortedKeys = validatedData.keys.sorted()
        
        // Create the string with sorted keys
        return sortedKeys.map { key in
            "\(key):\(validatedData[key]!)"
        }.joined(separator: ";")
    }

    /// Resets the canvas state and color settings to their default values.
    private func resetCanvasToDefault() {
        // Check for unsaved changes first
        if !UnsavedChangesHandler.checkUnsavedChanges(
            hasUnsavedChanges: hasUnsavedChanges,
            action: .newArtwork,
            showAlert: $showAlert,
            alertTitle: $alertTitle,
            alertMessage: $alertMessage,
            onProceed: {
                // Reset canvas when user confirms
                performCanvasReset()
            },
            onSaveFirst: {
                // Check if we're updating existing artwork
                if let existingArtwork = self.loadedArtworkData, existingArtwork.pieceId != nil {
                    // Save existing artwork directly without showing name prompt
                    self.saveArtwork(title: existingArtwork.title)
                    
                    // Set up the action to reset after saving
                    UnsavedChangesHandler.proceedAction = {
                        self.performCanvasReset()
                    }
                } else {
                    // Save first, then reset
                    showingSavePrompt = true
                    // We'll rely on the save action to proceed with reset after saving
                    UnsavedChangesHandler.proceedAction = {
                        self.performCanvasReset()
                    }
                }
            }
        ) {
            // If checkUnsavedChanges returns false, it means an alert is shown
            // So we return early and wait for the user's decision
            return
        }
        
        // If we get here, there were no unsaved changes, so proceed with reset
        performCanvasReset()
    }

    /// Performs the actual canvas reset (extracted to avoid code duplication)
    private func performCanvasReset() {
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
        selectedShape = .capsule // Default shape

        // Reset color manager
        ColorPresetManager.shared.resetToDefaults()
        colorPresetManager.saturationAdjustment = 1.0 // Default to 100%

        // Clear loaded artwork data
        loadedArtworkData = nil
        
        // Reset unsaved changes tracking
        hasUnsavedChanges = true  // Set to true for new artwork
        lastCheckedArtworkString = nil
        initialArtworkString = nil
        hasRecordedInitialState = false  // Reset this so we record the new initial state

        // Reset zoom and position
        resetPosition() // Call the existing position reset function
        zoomLevel = 1.0   // Reset zoom level to default

        print("[CanvasView] Canvas reset complete.")
        
        // Record the initial state after reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.checkForUnsavedChanges() // This will record the initial state
        }
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
        colorPresetManager.saturationAdjustment = 1.0 // Default to 100%
    }
    
    /// Creates an artwork with randomized properties
    private func createRandomizedArtwork() {
        // Random shape type from available options
        let shapeTypes: [ShapesPanel.ShapeType] = [.capsule, .square, .triangle, .pentagon, .star]
        selectedShape = shapeTypes.randomElement() ?? .capsule
        
        // Random shape properties within reasonable ranges
        shapeRotation = Double.random(in: 2...360)
        shapeScale = Double.random(in: 0.9...1.4)
        shapeLayer = Double.random(in: 30...50)
        shapeSkewX = Double.random(in: 0...30)
        shapeSkewY = Double.random(in: 0...30)
        shapeSpread = Double.random(in: 5...40)
        shapeHorizontal = Double.random(in: 0...0)
        shapeVertical = Double.random(in: 0...0)
        shapePrimitive = Double.random(in: 1...5).rounded()
        
        // Create random colors for the presets (using hue rotation for variety)
        var randomColors: [Color] = []
        for _ in 0..<10 {
            let hue = Double.random(in: 0...1)
            let saturation = Double.random(in: 0.5...1.0) // Only randomize between 50-100%
            let brightness = Double.random(in: 0.7...0.9)
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
        
        // Randomize saturation adjustment between 0.5 and 1.0
        colorPresetManager.saturationAdjustment = Double.random(in: 0.5...1.0)
        
        // Set as unsaved
        hasUnsavedChanges = true
        
        print("[CanvasView] Created randomized artwork (Unsaved)")
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
                
                // Wrap state updates in MainActor.run for reliable UI refresh
                await MainActor.run {
                    // Update the loadedArtworkData state to reflect the newly saved piece
                    self.loadedArtworkData = ArtworkData(
                        deviceId: firebaseService.getDeviceId(),
                        artworkString: artworkString,
                        timestamp: Date(),
                        title: title,
                        pieceId: newPieceId
                    )
                    
                    // Set status to saved
                    self.hasUnsavedChanges = false
                    self.lastCheckedArtworkString = artworkString
                    
                    // Update confirmation state and close sheet
                    self.confirmedArtworkId = IdentifiableArtworkID(id: newPieceId)
                    self.showArtworkReplaceSheet = false // Close the selection sheet
                    
                    // Execute any pending action after saving (if needed)
                    if let pendingAction = UnsavedChangesHandler.proceedAction {
                        pendingAction()
                        UnsavedChangesHandler.proceedAction = nil
                        UnsavedChangesHandler.saveFirstAction = nil
                        UnsavedChangesHandler.saveExistingArtworkAction = nil
                    }
                }
                
                // List pieces (async)
                await firebaseService.listAllPieces()
                
                // Remove the older MainActor.run block
                // await MainActor.run {
                //     confirmedArtworkId = IdentifiableArtworkID(id: newPieceId)
                //     showArtworkReplaceSheet = false // Close the selection sheet
                // }
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

    // Add this method after the getCurrentArtworkString method around line 1320
    /// Checks if there are unsaved changes by comparing the current settings with the loaded artwork
    private func checkForUnsavedChanges() {
        // Get current artwork string
        let currentArtworkString = getCurrentArtworkString()
        
        // If no artwork is loaded, we'll compare to the initial state (if recorded)
        if loadedArtworkData == nil {
            // If we haven't recorded an initial state yet, do so now
            if !hasRecordedInitialState {
                initialArtworkString = currentArtworkString
                hasRecordedInitialState = true
                hasUnsavedChanges = true  // Set to true for new artwork
                print("[DEBUG] checkForUnsavedChanges: Recording initial state for new artwork (Unsaved)")
                return
            }
            
            // Compare with initial state
            if let initialString = initialArtworkString, initialString == currentArtworkString {
                // Even if unchanged from initial state, a new artwork is still considered unsaved until explicitly saved
                hasUnsavedChanges = true
                print("[DEBUG] New artwork matches initial state - still marked as unsaved")
            } else {
                hasUnsavedChanges = true
                print("[DEBUG] New artwork has changes compared to initial state")
            }
            return
        }
        
        // Otherwise, proceed with comparing to loaded artwork
        let loadedArtwork = loadedArtworkData!
        
        // If strings are identical, return immediately
        if loadedArtwork.artworkString == currentArtworkString {
            hasUnsavedChanges = false
            print("[DEBUG] Raw artwork strings are identical - artwork is saved")
            return
        }
        
        // Debug: compare the raw strings to spot possible issues
        debugCompareArtworkStrings(loaded: loadedArtwork.artworkString, current: currentArtworkString)
        
        // Parse both strings to get parameter dictionaries
        let loadedParams = ArtworkData.decode(from: loadedArtwork.artworkString)
        let currentParams = ArtworkData.decode(from: currentArtworkString)
        
        // Debug: print all differences
        print("[DEBUG] Comparing loaded vs current artwork parameters:")
        
        // Initialize to false - we'll set to true if we find any differences
        hasUnsavedChanges = false
        
        // Check shape type
        if loadedParams["shape"] != currentParams["shape"] {
            print("[DEBUG] Shape mismatch: loaded=\(loadedParams["shape"] ?? "nil"), current=\(currentParams["shape"] ?? "nil")")
            hasUnsavedChanges = true
            return
        }
        
        // Compare numeric properties with tolerance for floating point
        func compareDoubleValues(key: String) -> Bool {
            guard let loadedStr = loadedParams[key], let currentStr = currentParams[key],
                  let loadedVal = Double(loadedStr), let currentVal = Double(currentStr) else {
                print("[DEBUG] Missing \(key): loaded=\(loadedParams[key] ?? "nil"), current=\(currentParams[key] ?? "nil")")
                return false
            }
            
            // Use a larger tolerance for floating point comparison
            let tolerance = 0.001
            let matching = abs(loadedVal - currentVal) <= tolerance
            
            if !matching {
                print("[DEBUG] \(key) mismatch: loaded=\(loadedVal), current=\(currentVal), diff=\(abs(loadedVal - currentVal))")
            }
            return matching
        }
        
        // Compare all numeric properties
        let numericKeys = ["rotation", "scale", "layer", "skewX", "skewY", "spread", 
                          "horizontal", "vertical", "primitive"]
        
        for key in numericKeys {
            if !compareDoubleValues(key: key) {
                hasUnsavedChanges = true
                return
            }
        }
        
        // Special handling for strokeWidth and alpha which might be optional
        if loadedParams["strokeWidth"] != nil || currentParams["strokeWidth"] != nil {
            if !compareDoubleValues(key: "strokeWidth") {
                hasUnsavedChanges = true
                return
            }
        }
        
        if loadedParams["alpha"] != nil || currentParams["alpha"] != nil {
            if !compareDoubleValues(key: "alpha") {
                hasUnsavedChanges = true
                return
            }
        }
        
        // Check colors (this is a bit more complex due to string format)
        func compareColorValues(key: String) -> Bool {
            let loadedColors = loadedParams[key]?.uppercased() ?? ""
            let currentColors = currentParams[key]?.uppercased() ?? ""
            
            // If they're exactly the same, return true immediately
            if loadedColors == currentColors {
                return true
            }
            
            print("[DEBUG] \(key) mismatch: loaded=\(loadedColors), current=\(currentColors)")
            
            // For the "colors" key, need special handling of the color array
            if key == "colors" {
                // Split into individual color values
                let loadedColorArray = loadedColors.split(separator: ",").map { String($0) }
                let currentColorArray = currentColors.split(separator: ",").map { String($0) }
                
                // Check if arrays have same length
                if loadedColorArray.count != currentColorArray.count {
                    print("[DEBUG] Different number of colors: loaded=\(loadedColorArray.count), current=\(currentColorArray.count)")
                    return false
                }
                
                // Compare each color with tolerance
                for i in 0..<loadedColorArray.count {
                    if !areColorsVisuallyEquivalent(loadedColorArray[i], currentColorArray[i]) {
                        print("[DEBUG] Color at position \(i) differs significantly: loaded=\(loadedColorArray[i]), current=\(currentColorArray[i])")
                        return false
                    }
                }
                
                // If we get here, all colors are equivalent within tolerance
                print("[DEBUG] Colors are visually equivalent despite hex differences")
                return true
            } else {
                // For single colors (background, strokeColor), compare with tolerance
                return areColorsVisuallyEquivalent(loadedColors, currentColors)
            }
        }
        
        let colorKeys = ["colors", "background", "strokeColor"]
        for key in colorKeys {
            if !compareColorValues(key: key) {
                hasUnsavedChanges = true
                return
            }
        }
        
        // Check boolean and other values
        func compareStringValues(key: String) -> Bool {
            let loadedValue = loadedParams[key] ?? ""
            let currentValue = currentParams[key] ?? ""
            
            let matching = loadedValue == currentValue
            if !matching {
                print("[DEBUG] \(key) mismatch: loaded=\(loadedValue), current=\(currentValue)")
            }
            return matching
        }
        
        // Check boolean values and other string values
        let stringKeys = ["useRainbow", "rainbowStyle", "presetCount"]
        for key in stringKeys {
            if !compareStringValues(key: key) {
                hasUnsavedChanges = true
                return
            }
        }
        
        // Check adjustments
        if !compareDoubleValues(key: "hueAdj") || !compareDoubleValues(key: "satAdj") {
            hasUnsavedChanges = true
            return
        }
        
        // If we get here, everything matches (or is within acceptable tolerance)
        print("[DEBUG] All parameters match or are within tolerance - artwork is saved")
        hasUnsavedChanges = false
    }

    /// Makes an artwork info banner to display at the bottom of the screen
    private func makeArtworkInfoBanner() -> some View {
        HStack(spacing: 8) {
            // Show artwork title
            if let loadedArtwork = loadedArtworkData {
                Text(loadedArtwork.title ?? "Untitled Artwork")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            } else {
                Text("Untitled Artwork")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            
            // Show status indicator
            if hasUnsavedChanges {
                // Show "Unsaved" in red when changes detected
                Text("• Unsaved")
                    .font(.caption)
                    .foregroundColor(.red)
            } else {
                // Show "Saved" in green when no changes
                Text("• Saved")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemBackground).opacity(0.8))
        .cornerRadius(8)
        .shadow(radius: 1)
    }

    /// Debug method to compare raw artwork strings and identify conversion issues
    private func debugCompareArtworkStrings(loaded: String, current: String) {
        // Debug function removed
    }

    /// Helper function to compare colors with visual tolerance
    private func areColorsVisuallyEquivalent(_ hex1: String, _ hex2: String) -> Bool {
        // Convert hex to RGB
        func hexToRGB(_ hex: String) -> (r: Int, g: Int, b: Int)? {
            let hexSanitized = hex.replacingOccurrences(of: "#", with: "")
            if hexSanitized.count != 6 {
                return nil
            }
            
            var rgb: UInt64 = 0
            guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
                return nil
            }
            
            let r = Int((rgb & 0xFF0000) >> 16)
            let g = Int((rgb & 0x00FF00) >> 8)
            let b = Int(rgb & 0x0000FF)
            
            return (r, g, b)
        }
        
        // Get RGB values
        guard let rgb1 = hexToRGB(hex1), let rgb2 = hexToRGB(hex2) else {
            // If can't parse, return direct comparison
            return hex1 == hex2
        }
        
        // Calculate color difference using a simple Euclidean distance in RGB space
        let rDiff = abs(rgb1.r - rgb2.r)
        let gDiff = abs(rgb1.g - rgb2.g)
        let bDiff = abs(rgb1.b - rgb2.b)
        
        // Calculate the Euclidean distance
        let distance = sqrt(Double(rDiff*rDiff + gDiff*gDiff + bDiff*bDiff))
        
        // Tolerance of 8 in RGB space (out of 255) should handle minor color variations
        let tolerance = 8.0
        let equivalent = distance <= tolerance
        
        if !equivalent {
            // print("[DEBUG] Color difference: \(distance) - r:\(rDiff) g:\(gDiff) b:\(bDiff) between \(hex1) and \(hex2)")
        } else {
            // print("[DEBUG] Colors equivalent within tolerance: \(hex1) and \(hex2) - distance: \(distance)")
        }
        
        return equivalent
    }

    /// Handles the import of artwork with unsaved changes check
    private func handleImportedArtwork(_ artworkString: String) {
        print("[DEBUG] handleImportedArtwork called, hasUnsavedChanges = \(hasUnsavedChanges)")
        
        // Check for unsaved changes first
        if !UnsavedChangesHandler.checkUnsavedChanges(
            hasUnsavedChanges: hasUnsavedChanges,
            action: .importArtwork,
            showAlert: $showAlert,
            alertTitle: $alertTitle,
            alertMessage: $alertMessage,
            onProceed: {
                print("[DEBUG] Import: Proceeding without saving")
                // Apply imported artwork when user confirms
                self.applyImportedArtwork(artworkString)
            },
            onSaveFirst: {
                print("[DEBUG] Import: Save first selected")
                
                // Check if we're updating existing artwork
                if let existingArtwork = self.loadedArtworkData, existingArtwork.pieceId != nil {
                    // Save existing artwork directly without showing name prompt
                    self.saveArtwork(title: existingArtwork.title)
                    
                    // Store the artwork string temporarily
                    let tempArtworkString = artworkString
                    // Set up the action to proceed with import after saving
                    UnsavedChangesHandler.proceedAction = {
                        self.applyImportedArtwork(tempArtworkString)
                    }
                } else {
                    // This is a new artwork, show the save prompt
                    showingSavePrompt = true
                    // Store the artwork string temporarily
                    let tempArtworkString = artworkString
                    // We'll rely on the save action to proceed with import after saving
                    UnsavedChangesHandler.proceedAction = {
                        self.applyImportedArtwork(tempArtworkString)
                    }
                }
            }
        ) {
            // If checkUnsavedChanges returns false, it means an alert is shown
            // So we return early and wait for the user's decision
            print("[DEBUG] Import: Alert is being shown for unsaved changes")
            return
        }
        
        // If we get here, there were no unsaved changes, so proceed with import
        print("[DEBUG] Import: No unsaved changes, proceeding directly with import")
        applyImportedArtwork(artworkString)
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
    
    internal struct ArtworkReplaceSheet: View {
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
    internal struct ArtworkPreview: View {
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
    internal struct ArtworkParameters {
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
    internal struct ArtworkRendererView: View {
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
            
            let numberOfLayers = max(0, min(72, Int(params.layer)))
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
            case .capsule:
                // Create a capsule shape within the baseRect
                // Adjust the height slightly to make it visually distinct from oval
                let capsuleRect = CGRect(
                    x: finalX - scaledRadius * 0.8, // Slightly narrower
                    y: finalY - scaledRadius, // Full height
                    width: scaledRadius * 1.6, // Slightly narrower
                    height: scaledRadius * 2
                )
                shapePath = Capsule(style: .continuous).path(in: capsuleRect)
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
            for index in 0..<sides {
                let currentAngle = angle * Double(index) - (.pi / 2)
                let x = center.x + CGFloat(radius * cos(currentAngle))
                let y = center.y + CGFloat(radius * sin(currentAngle))
                if index == 0 { path.move(to: CGPoint(x: x, y: y)) }
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

    /// Saves the current artwork state for potential restoration
    private func saveCurrentStateForRestoration() {
        if hasUnsavedChanges {
            let currentArtworkString = getCurrentArtworkString()
            UnsavedChangesHandler.saveStateForRestoration(
                artworkString: currentArtworkString, 
                hasUnsavedChanges: hasUnsavedChanges
            )
            print("[DEBUG] Saved current artwork state for potential restoration")
        } else {
            // No unsaved changes, clear any previously saved state
            UnsavedChangesHandler.clearSavedState()
            print("[DEBUG] No unsaved changes, cleared any previous saved state")
        }
    }

    /// Checks if there's a previously saved artwork state to restore
    private func checkForPreviouslySavedWork() {
        // Don't check for previous state if we're intentionally loading an artwork
        if loadedArtworkData != nil {
            return
        }
        
        let result = UnsavedChangesHandler.checkForPreviousSession(
            showAlert: $showRestorationAlert,
            alertTitle: $alertTitle,
            alertMessage: $alertMessage,
            onRestore: {
                // Restore previous work
                if let savedArtworkString = UnsavedChangesHandler.getSavedArtworkString() {
                    restorePreviousWork(artworkString: savedArtworkString)
                    
                    // Clear saved state after restoring
                    UnsavedChangesHandler.clearSavedState()
                }
            },
            onDiscard: {
                // User chose to start fresh, do nothing
                // The saved state will be cleared in the UnsavedChangesHandler
            }
        )
        
        if result {
            print("[DEBUG] Found previously saved artwork state, showing restoration dialog")
        } else {
            print("[DEBUG] No previously saved artwork state found")
        }
    }

    /// Restores previously saved artwork
    private func restorePreviousWork(artworkString: String) {
        print("[DEBUG] Restoring previously saved artwork")
        
        // Parse the artwork string into parameters
        let params = ArtworkData.decode(from: artworkString)
        
        // Restore shape type
        if let shapeTypeStr = params["shape"], let shapeType = ShapesPanel.ShapeType(rawValue: shapeTypeStr) {
            selectedShape = shapeType
        }
        
        // Restore numeric values
        if let val = params["rotation"], let double = Double(val) { shapeRotation = double }
        if let val = params["scale"], let double = Double(val) { shapeScale = double }
        if let val = params["layer"], let double = Double(val) { shapeLayer = double }
        if let val = params["skewX"], let double = Double(val) { shapeSkewX = double }
        if let val = params["skewY"], let double = Double(val) { shapeSkewY = double }
        if let val = params["spread"], let double = Double(val) { shapeSpread = double }
        if let val = params["horizontal"], let double = Double(val) { shapeHorizontal = double }
        if let val = params["vertical"], let double = Double(val) { shapeVertical = double }
        if let val = params["primitive"], let double = Double(val) { shapePrimitive = double }
        if let val = params["strokeWidth"], let double = Double(val) { colorPresetManager.strokeWidth = double }
        if let val = params["alpha"], let double = Double(val) { colorPresetManager.shapeAlpha = double }
        
        // Restore color presets if available
        if let colorsStr = params["colors"] {
            let colors = ArtworkData.reconstructColors(from: colorsStr)
            if !colors.isEmpty {
                colorPresetManager.colorPresets = colors
                colorUpdateTrigger = UUID() // Force update
            }
        }
        
        // Restore background color
        if let backgroundStr = params["background"], let bgColor = ArtworkData.hexToColor(backgroundStr) {
            colorPresetManager.backgroundColor = bgColor
            backgroundColorTrigger = UUID() // Force update
        }
        
        // Restore stroke color
        if let strokeColorStr = params["strokeColor"], let strokeColor = ArtworkData.hexToColor(strokeColorStr) {
            colorPresetManager.strokeColor = strokeColor
            strokeSettingsTrigger = UUID() // Force update
        }
        
        // Restore rainbow settings
        if let useRainbowStr = params["useRainbow"], let useRainbow = Bool(useRainbowStr) {
            colorPresetManager.useDefaultRainbowColors = useRainbow
        }
        
        if let rainbowStyleStr = params["rainbowStyle"], let rainbowStyle = Int(rainbowStyleStr) {
            colorPresetManager.rainbowStyle = rainbowStyle
        }
        
        if let hueAdjStr = params["hueAdj"], let hueAdj = Double(hueAdjStr) {
            colorPresetManager.hueAdjustment = hueAdj
        }
        
        if let satAdjStr = params["satAdj"], let satAdj = Double(satAdjStr) {
            colorPresetManager.saturationAdjustment = satAdj
        }
        
        // Restore preset count if available
        if let presetCountStr = params["presetCount"], let presetCount = Int(presetCountStr) {
            colorPresetManager.numberOfVisiblePresets = presetCount
        }
        
        // Set proper initialization flags
        hasRecordedInitialState = true
        initialArtworkString = artworkString
        lastCheckedArtworkString = artworkString
        
        // This work is unsaved (it's a restoration, not a loaded saved artwork)
        hasUnsavedChanges = true
        
        print("[DEBUG] Successfully restored previous artwork state")
    }

    // MARK: - Offset Calculation

    /// Calculates the dynamic vertical offset for the canvas.
    private func calculateCanvasVerticalOffset(geometry: GeometryProxy) -> CGFloat {
        let verticalOffset = canvasVerticalOffset
        
        // DEBUG: Log calculated vertical offset with geometry
        print("DEBUG: Calculated canvas offset: \(verticalOffset), screen height: \(geometry.size.height)")
        
        return verticalOffset
    }

    // Add a function to debug the canvas position
    private func logCanvasPosition() {
        print("DEBUG: Canvas position - offset: \(offset), zoom: \(zoomLevel), rotation: \(currentRotation.degrees)")
    }
}
