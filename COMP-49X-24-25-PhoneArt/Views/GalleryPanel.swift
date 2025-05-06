//
//  GalleryPanel.swift
//  COMP-49X-24-25-PhoneArt
//
//  Created by Emmett de Bruin on 2025-04-08.
//


import SwiftUI


struct GalleryPanel: View {
  // MARK: - Properties
  @ObservedObject var firebaseService: FirebaseService // Use injected service instead of shared
  @State var artworkItems: [ArtworkData] = []
  @State var isLoading = false
  @State var isGeneratingThumbnails = false // Track thumbnail generation
  @State var thumbnails: [String: UIImage] = [:] // Dictionary to store thumbnails [artworkId: UIImage]
  @State var errorMessage: String?
  @State private var sortOption = SortOption.lastUpdated // New state for sort option
   @State private var showingLoadConfirmation = false // State for load confirmation alert
  @State private var selectedArtworkForLoad: ArtworkData? // Track which artwork to load
 
  // States for Rename Alert
  @State private var showingRenameAlert = false
  @State private var artworkToRename: ArtworkData?
  @State private var newArtworkTitle: String = ""


  // States for Delete Alert
  @State private var showingDeleteConfirmation = false
  @State private var artworkToDelete: ArtworkData?
 
  // State for general feedback/error alerts
  @State private var showingFeedbackAlert = false
  @State private var feedbackAlertTitle = ""
  @State private var feedbackAlertMessage = ""
   @Binding var isShowing: Bool
   @Binding var confirmedArtworkId: IdentifiableArtworkID? // << Add binding for share popup
   // Callbacks for switching panels
  var onSwitchToProperties: () -> Void
  var onSwitchToColorShapes: () -> Void
  var onSwitchToShapes: () -> Void
  var onLoadArtwork: (ArtworkData) -> Void // << New callback for loading artwork
   // MARK: - Initialization
  init(isShowing: Binding<Bool>,
       confirmedArtworkId: Binding<IdentifiableArtworkID?>, // << Add binding to init
       onSwitchToProperties: @escaping () -> Void,
       onSwitchToColorShapes: @escaping () -> Void,
       onSwitchToShapes: @escaping () -> Void,
       onLoadArtwork: @escaping (ArtworkData) -> Void, // << Add callback to initializer
       firebaseService: FirebaseService = FirebaseService.shared) {
      self._isShowing = isShowing
      self._confirmedArtworkId = confirmedArtworkId // << Initialize binding
      self.onSwitchToProperties = onSwitchToProperties
      self.onSwitchToColorShapes = onSwitchToColorShapes
      self.onSwitchToShapes = onSwitchToShapes
      self.onLoadArtwork = onLoadArtwork // << Initialize callback
      self.firebaseService = firebaseService
  }
   // MARK: - Body
  var body: some View {
      VStack(spacing: 0) {
          // Header section with navigation buttons and close control
          panelHeader()
        
          // Main content area (Placeholder for Gallery)
          ScrollView { // ScrollView to contain the grid
              VStack {
                  Text("Artwork Gallery")
                      .font(.title2).bold()
                      .padding(.top)
                
                  Text("Your saved artworks! You can save a maximum of 12 artworks.")
                      .font(.caption)
                      .foregroundColor(.secondary)
                      .multilineTextAlignment(.center)
                      .frame(maxWidth: .infinity)
                      .padding(.horizontal)
                      .padding(.bottom, 4)

                  Text("Note: Custom Colors may be inaccurate in thumbnails below.")
                      .font(.caption)
                      .foregroundColor(.secondary)
                      .multilineTextAlignment(.center)
                      .frame(maxWidth: .infinity)
                      .padding(.horizontal)
                      .padding(.bottom, 8)
                     
                  // Sort and Refresh controls
                  ZStack(alignment: .trailing) {
                      // Centered picker
                      HStack {
                          Spacer()
                          Picker("Sort by", selection: $sortOption) {
                              Text("Alphabetical").tag(SortOption.alphabetical)
                              Text("Last Updated").tag(SortOption.lastUpdated)
                          }
                          .pickerStyle(.segmented)
                          .frame(width: 220)
                          Spacer()
                      }
                     
                      // Refresh button aligned with thumbnail edge
                      Button(action: {
                          // Refresh the gallery data when this button is pressed
                          loadArtwork()
                      }) {
                          Image(systemName: "arrow.clockwise")
                              .font(.system(size: 16))
                      }
                      .padding(.trailing, 16)
                  }
                  .padding(.bottom, 0)
                
                  // TODO: Implement Gallery Content Here
                  galleryContent()
              }
          }
          .onAppear(perform: loadArtwork) // Load artwork when the panel appears
      }
      .frame(maxWidth: .infinity)
      .frame(height: UIScreen.main.bounds.height / 2) // Panel takes up half of screen height
      .background(Color(.systemBackground))
      .cornerRadius(15, corners: [.topLeft, .topRight])
      .shadow(radius: 10)
      .onChange(of: artworkItems) { _, newItems in
          // Trigger thumbnail generation when artwork items are loaded
          generateThumbnails(for: newItems)
      }
      .alert("Load Artwork?", isPresented: $showingLoadConfirmation, presenting: selectedArtworkForLoad) { artworkToLoad in
          Button("Cancel", role: .cancel) { }
          Button("Load") {
              // Call the load callback and dismiss the panel
              onLoadArtwork(artworkToLoad)
              isShowing = false
          }
      } message: { artworkToLoad in
          Text("Do you want to load '\(artworkToLoad.title ?? "Untitled")'? This will replace your current canvas settings.")
      }
      // Add Rename Alert
      .alert("Rename Artwork", isPresented: $showingRenameAlert, presenting: artworkToRename) {
          artwork in // `artwork` is the ArtworkData passed to the alert
          TextField("New Title", text: $newArtworkTitle)
              .autocapitalization(.words)
          Button("Cancel", role: .cancel) { artworkToRename = nil } // Clear selection on cancel
          Button("Save") {
              handleRename(artwork: artwork)
          }
      } message: { artwork in
          Text("Enter a new title for \"\(artwork.title ?? "Untitled")\".")
      }
      // Add Delete Confirmation Alert
      .alert("Delete Artwork?", isPresented: $showingDeleteConfirmation, presenting: artworkToDelete) { artwork in
          Button("Cancel", role: .cancel) { artworkToDelete = nil } // Clear selection on cancel
          Button("Delete", role: .destructive) {
              handleDelete(artwork: artwork)
          }
      } message: { artwork in
          Text("Are you sure you want to delete \"\(artwork.title ?? "Untitled")\"? This cannot be undone.")
      }
      // General Feedback Alert
      .alert(feedbackAlertTitle, isPresented: $showingFeedbackAlert) {
          Button("OK", role: .cancel) { }
      } message: {
          Text(feedbackAlertMessage)
      }
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
          buttonContent(icon: "paintpalette", isActive: false)
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
          // Refresh the gallery data when this button is pressed
          loadArtwork()
      }) {
          buttonContent(icon: "photo.on.rectangle.angled", isActive: true) // Active state
      }
      .accessibilityIdentifier("Gallery Button")
  }


  // MARK: - Data Loading
  func loadArtwork() {
      isLoading = true
      errorMessage = nil
      // Clear existing thumbnails to force re-rendering
      thumbnails = [:]
      Task {
          do {
              let fetchedItems = try await firebaseService.getArtwork()
              // Update state on the main thread
              await MainActor.run {
                  self.artworkItems = fetchedItems
                  self.isLoading = false
                  print("Successfully fetched \(fetchedItems.count) artwork items.")
                  // Always regenerate thumbnails after refresh, even if items didn't change
                  generateThumbnails(for: fetchedItems)
              }
          } catch {
              // Update state on the main thread
              await MainActor.run {
                  self.errorMessage = "Failed to load artwork: \(error.localizedDescription)"
                  self.isLoading = false
                  print("Error fetching artwork: \(error)")
              }
          }
      }
  }


  @ViewBuilder
  private func galleryContent() -> some View {
      if isLoading {
          ProgressView()
              .padding()
      } else if let errorMsg = errorMessage {
          Text(errorMsg)
              .foregroundColor(.red)
              .padding()
      } else if artworkItems.isEmpty {
          Text("No saved artwork found.")
              .foregroundColor(.secondary)
              .padding()
      } else {
          // Grid layout: 2 columns
          let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 2)


          // Show overall generating indicator if needed
          if isGeneratingThumbnails && thumbnails.isEmpty {
              ProgressView("Generating Thumbnails...")
                  .padding()
          }


          // Sort the artwork items based on the selected option
          let sortedItems = sortedArtworkItems()
         
          LazyVGrid(columns: columns, spacing: 16) {
              ForEach(sortedItems) { item in // ArtworkData is Identifiable
                  ArtworkGridItem(
                      artwork: item,
                      thumbnail: thumbnails[item.id],
                      onTap: { // Main tap action for loading
                          self.selectedArtworkForLoad = item
                          self.showingLoadConfirmation = true
                          print("Tapped on artwork: \(item.title ?? "Untitled"). Showing load confirmation.")
                      },
                      onRename: { // Rename action
                          self.artworkToRename = item
                          self.newArtworkTitle = item.title ?? "" // Pre-fill text field
                          self.showingRenameAlert = true
                          print("Rename requested for: \(item.id)")
                      },
                      onDelete: { // Delete action
                          self.artworkToDelete = item
                          self.showingDeleteConfirmation = true
                          print("Delete requested for: \(item.id)")
                      },
                      onShare: { // << Add share action
                          handleShare(artwork: item)
                      }
                  )
              }
          }
          .padding()
      }
  }
 
  // Sort option enum
  enum SortOption {
      case alphabetical
      case lastUpdated
  }
 
  // Function to sort artwork items based on selected option
  private func sortedArtworkItems() -> [ArtworkData] {
      switch sortOption {
      case .alphabetical:
          return artworkItems.sorted { ($0.title ?? "").lowercased() < ($1.title ?? "").lowercased() }
      case .lastUpdated:
          return artworkItems.sorted { $0.timestamp > $1.timestamp }
      }
  }


  // MARK: - Thumbnail Generation
  func generateThumbnails(for items: [ArtworkData]) {
      guard !items.isEmpty else { return }
      isGeneratingThumbnails = true


      Task(priority: .userInitiated) { // Use a background task
          var generated: [String: UIImage] = [:]
          let targetSize = CGSize(width: 150, height: 150) // Target thumbnail size


          for item in items {
              // Check if thumbnail already exists (e.g., from previous generation)
              if let existing = thumbnails[item.id] {
                  generated[item.id] = existing
                  continue
              }


              // Decode parameters
              guard let params = decodeArtworkParameters(from: item.artworkString) else {
                  print("Skipping thumbnail for item \(item.id) due to decoding error.")
                  continue
              }


              // Render off-screen
              let renderer = ImageRenderer(content: ArtworkRendererView(params: params))
              renderer.scale = UIScreen.main.scale // Use screen scale for clarity


              // Capture UIImage
              if let uiImage = renderer.uiImage {
                  // Resize
                  if let resizedImage = resizeImage(image: uiImage, targetSize: targetSize) {
                      generated[item.id] = resizedImage
                      print("Generated thumbnail for item \(item.id)")
                  } else {
                      print("Failed to resize image for item \(item.id)")
                  }
              } else {
                  print("Failed to render image for item \(item.id)")
              }
          }


          // Update the state on the main thread
          await MainActor.run {
              self.thumbnails = generated
              self.isGeneratingThumbnails = false
              print("Finished thumbnail generation. Count: \(generated.count)")
          }
      }
  }


  // Resize helper function
  private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
      let size = image.size
      let widthRatio  = targetSize.width  / size.width
      let heightRatio = targetSize.height / size.height
      let ratio = min(widthRatio, heightRatio)
      let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
      let rect = CGRect(origin: .zero, size: newSize)


      UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
      image.draw(in: rect)
      let newImage = UIGraphicsGetImageFromCurrentImageContext()!
      UIGraphicsEndImageContext()


      return newImage
  }


  // MARK: - Alert Handlers
 
  private func handleRename(artwork: ArtworkData) {
      guard let artworkToRename = self.artworkToRename, artworkToRename.id == artwork.id else { return }
      let titleToSave = newArtworkTitle.trimmingCharacters(in: .whitespacesAndNewlines)
     
      // Basic validation: ensure title is not empty (optional)
      // if titleToSave.isEmpty {
      //     showFeedback(title: "Error", message: "Artwork title cannot be empty.")
      //     return
      // }
     
      Task {
          do {
              try await firebaseService.updateArtworkTitle(artwork: artworkToRename, newTitle: titleToSave)
              // Update local data immediately for responsiveness
              if let index = artworkItems.firstIndex(where: { $0.id == artworkToRename.id }) {
                  artworkItems[index] = artworkItems[index].withUpdatedTitle(titleToSave)
              }
              self.artworkToRename = nil // Clear selection
              showFeedback(title: "Success", message: "Artwork renamed successfully.")
          } catch {
              print("Error renaming artwork: \(error)")
              showFeedback(title: "Error", message: "Failed to rename artwork: \(error.localizedDescription)")
          }
      }
  }
 
  private func handleDelete(artwork: ArtworkData) {
      guard let artworkToDelete = self.artworkToDelete, artworkToDelete.id == artwork.id else { return }
     
      Task {
          do {
              try await firebaseService.deleteArtwork(artwork: artworkToDelete)
              // Remove from local data immediately
              artworkItems.removeAll { $0.id == artworkToDelete.id }
              thumbnails.removeValue(forKey: artworkToDelete.id) // Remove associated thumbnail
              self.artworkToDelete = nil // Clear selection
              showFeedback(title: "Success", message: "Artwork deleted successfully.")
          } catch {
              print("Error deleting artwork: \(error)")
              showFeedback(title: "Error", message: "Failed to delete artwork: \(error.localizedDescription)")
          }
      }
  }
 
  // Helper to show feedback alerts
  private func showFeedback(title: String, message: String) {
      feedbackAlertTitle = title
      feedbackAlertMessage = message
      showingFeedbackAlert = true
  }

  // << Add handler function for sharing
  private func handleShare(artwork: ArtworkData) {
      // Use the pieceId (document ID) for sharing if available, otherwise use the artworkString as a fallback ID
      guard let shareId = artwork.pieceId else {
          print("Error: Artwork pieceId is missing, cannot share.")
          // Optionally show an alert to the user
          showFeedback(title: "Cannot Share", message: "This artwork seems to be missing its ID.")
          return
      }
      print("Share requested for artwork ID: \(shareId)")
      // Set the binding to trigger the share popup in CanvasView
      self.confirmedArtworkId = IdentifiableArtworkID(id: shareId)
      // Optionally close the gallery panel after sharing
      // self.isShowing = false
  }
}




// MARK: - Artwork Grid Item View
struct ArtworkGridItem: View {
   let artwork: ArtworkData
   let thumbnail: UIImage? // Receive the generated thumbnail
  
   // Callbacks for actions
   var onTap: () -> Void
   var onRename: () -> Void
   var onDelete: () -> Void
   var onShare: () -> Void // << Add share callback
  
   // Placeholder image (lazy generation)
   private let placeholder: UIImage = {
       // Create a simple gray placeholder UIImage
       let size = CGSize(width: 50, height: 50)
       UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
       UIColor.systemGray5.setFill()
       UIRectFill(CGRect(origin: .zero, size: size))
       // Optional: Draw an icon on the placeholder
       let imageIcon = UIImage(systemName: "photo")?.withTintColor(.systemGray2)
       imageIcon?.draw(in: CGRect(x: size.width * 0.25, y: size.height * 0.25, width: size.width * 0.5, height: size.height * 0.5))
       let image = UIGraphicsGetImageFromCurrentImageContext()!
       UIGraphicsEndImageContext()
       return image
   }()


   // Formatter for timestamp
   private static let dateFormatter: DateFormatter = {
       let formatter = DateFormatter()
       formatter.dateStyle = .short
       formatter.timeStyle = .short
       return formatter
   }()


   var body: some View {
       VStack(alignment: .leading, spacing: 8) {
          // Display the generated thumbnail or a placeholder
          Image(uiImage: thumbnail ?? placeholder)
              .resizable()
              .aspectRatio(1, contentMode: .fit) // Keep it square
              .background(Color(.systemGray6)) // Background behind the image
              .cornerRadius(8)




          // Row with title/date on left and action buttons on right
          HStack {
              // Title and timestamp on the left
              VStack(alignment: .leading, spacing: 2) {
                  Text(artwork.title ?? "Untitled")
                      .font(.caption.weight(.semibold))
                      .lineLimit(1)




                  Text(Self.dateFormatter.string(from: artwork.timestamp))
                      .font(.caption2)
                      .foregroundColor(.secondary)
              }
            
              Spacer()
            
              // Action buttons on the right
              HStack(spacing: 8) { // Adjust spacing if needed
                  // Share button
                  Button(action: onShare) {
                      Image(systemName: "square.and.arrow.up")
                          .font(.system(size: 14))
                          .foregroundColor(.blue) // Or another appropriate color
                  }
                  .frame(width: 30, height: 30)
                  .background(Color(.systemBackground).opacity(0.001))
                  .cornerRadius(4)
                  .accessibilityLabel("Share Artwork")

                  // Edit/Rename button
                  Button(action: onRename) { // Use the callback
                      Image(systemName: "pencil")
                          .font(.system(size: 14))
                          .foregroundColor(.blue)
                  }
                  .frame(width: 30, height: 30)
                  .background(Color(.systemBackground).opacity(0.001)) // Ensure hittable area
                  .cornerRadius(4)
                  .accessibilityLabel("Rename Artwork")

                  // Delete button
                  Button(action: onDelete) { // Use the callback
                      Image(systemName: "trash")
                          .font(.system(size: 14))
                          .foregroundColor(.red)
                  }
                  .frame(width: 30, height: 30)
                  .background(Color(.systemBackground).opacity(0.001)) // Ensure hittable area
                  .cornerRadius(4)
                  .accessibilityLabel("Delete Artwork")
              }
          }
      }
       .contentShape(Rectangle()) // Make the whole VStack tappable for the main action
       .onTapGesture(perform: onTap) // Assign the main tap action here
       .accessibilityElement(children: .combine)
       .accessibilityLabel("Artwork titled \(artwork.title ?? "Untitled"), saved \(Self.dateFormatter.string(from: artwork.timestamp))")
   }
}




// MARK: - Artwork Parameters Struct
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


// MARK: - Decoding Helper
private func decodeArtworkParameters(from artworkString: String) -> ArtworkParameters? {
   let decodedParams = ArtworkData.decode(from: artworkString)
   // print("[GalleryPanel] Decoded Raw Params for \(artworkString.prefix(30))...: \(decodedParams)")


   // Use helper for doubles, including strokeWidth and alpha
   // Helper to safely extract double values
   func doubleValue(from key: String, default defaultValue: Double) -> Double {
       guard let stringValue = decodedParams[key], let value = Double(stringValue) else {
           return defaultValue
       }
       return value
   }


   guard let shapeString = decodedParams["shape"],
         let shapeType = ShapesPanel.ShapeType(rawValue: shapeString) else {
       // print("Error: Could not decode shapeType from string")
       return nil // Cannot render without shape type
   }


   let colors = ArtworkData.reconstructColors(from: decodedParams["colors"] ?? "")
   let background = ArtworkData.hexToColor(decodedParams["background"] ?? "") ?? .white


   // Decode the saved color mode flag
   let useRainbowFlag = (decodedParams["useRainbow"] ?? "false") == "true"


   // Decode saved rainbow settings, using current manager settings as fallback for older data
   let savedStyleString = decodedParams["rainbowStyle"]
   let savedHueAdjString = decodedParams["hueAdj"]
   let savedSatAdjString = decodedParams["satAdj"]


   let manager = ColorPresetManager.shared // Get current settings for fallback


   let rainbowStyle = Int(savedStyleString ?? "") ?? manager.rainbowStyle
   let hueAdjustment = Double(savedHueAdjString ?? "") ?? manager.hueAdjustment
   let saturationAdjustment = Double(savedSatAdjString ?? "") ?? manager.saturationAdjustment


   // Decode stroke and alpha using the helper
   let shapeAlpha = doubleValue(from: "alpha", default: 1.0)
   let strokeWidth = doubleValue(from: "strokeWidth", default: 0.0)
   let strokeColor = ArtworkData.hexToColor(decodedParams["strokeColor"] ?? "") ?? .black // Fallback to black


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
       useDefaultRainbowColors: useRainbowFlag, // Use the decoded flag
       rainbowStyle: rainbowStyle,           // Use decoded or fallback
       hueAdjustment: hueAdjustment,           // Use decoded or fallback
       saturationAdjustment: saturationAdjustment, // Use decoded or fallback
       shapeAlpha: shapeAlpha,
       strokeWidth: strokeWidth,
       strokeColor: strokeColor
   )
}


// MARK: - Drawing Logic (Copied and adapted from CanvasView)


// Note: This logic is duplicated from CanvasView. Consider refactoring into a shared service/utility.


/// Draws the shapes based on provided parameters.
private func drawShapes(context: GraphicsContext, size: CGSize, params: ArtworkParameters) {
   // --- Original Logic (Restored) ---
   let circleRadius = 30.0 // Fixed base radius, same as main CanvasView
   let centerX = size.width / 2
   // Shift the vertical center up slightly for thumbnail rendering
   let centerY = size.height * 0.45
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
   // --- End Original Logic ---
}


/// Draws multiple layers of shapes.
private func drawLayers(
   context: GraphicsContext,
   layers: Int,
   center: CGPoint,
   radius: Double,
   params: ArtworkParameters
) {
   let primitiveCount = Int(max(1.0, min(6.0, params.primitive))) // Validate primitive


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


/// Draws a single shape with transformations and color.
private func drawSingleShape(
   context: GraphicsContext,
   layerIndex: Int,
   primitiveAngleOffset: Double,
   center: CGPoint,
   radius: Double,
   params: ArtworkParameters
) {
   let layerContext = context


   let angleInDegrees = (params.rotation * Double(layerIndex)) + primitiveAngleOffset
   let angleInRadians = angleInDegrees * (.pi / 180)


   let scaleFactor = 0.125 // Reduced from 0.25 to 0.125 to halve the scale effect strength
   let layerScale = pow(1.0 + (params.scale - 1.0) * scaleFactor, Double(layerIndex + 1))
   let scaledRadius = radius * layerScale


   // Use original spread, offsets etc for full rendering
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


   let shapePath = createShapePath(shapeType: params.shapeType, finalX: finalX, finalY: finalY, scaledRadius: scaledRadius, baseRect: baseRect)


   // Apply Transformations (Skew, Rotation)
   var shapeTransform = CGAffineTransform.identity
   if abs(angleInRadians) > 0.001 {
       // Rotation might be okay, keep for now
       shapeTransform = shapeTransform.rotated(by: CGFloat(angleInRadians))
   }
   if abs(params.skewX) > 0.01 || abs(params.skewY) > 0.01 {
       // Update skew calculation to match CanvasView implementation
       let skewXRad = params.skewX * (.pi / 180)
       let skewYRad = params.skewY * (.pi / 180)
       if abs(params.skewX) > 0.01 {
           let shearX = CGFloat(tan(skewXRad))
           shapeTransform = shapeTransform.concatenating(CGAffineTransform(a: 1, b: 0, c: shearX, d: 1, tx: 0, ty: 0))
       }
       if abs(params.skewY) > 0.01 {
           let shearY = CGFloat(tan(skewYRad))
           shapeTransform = shapeTransform.concatenating(CGAffineTransform(a: 1, b: shearY, c: 0, d: 1, tx: 0, ty: 0))
       }
   }


   let toOriginTransform = CGAffineTransform(translationX: -finalX, y: -finalY)
   let backToPositionTransform = CGAffineTransform(translationX: finalX, y: finalY)
   let finalTransform = toOriginTransform.concatenating(shapeTransform).concatenating(backToPositionTransform)
   let transformedPath = shapePath.applying(finalTransform)


   // Determine color for this layer
   let layerColor: Color
   if params.useDefaultRainbowColors {
       // Use the appropriate shared rainbow function based on style
       switch params.rainbowStyle {
       case 1: layerColor = ColorUtils.cyberpunkRainbowColor(for: layerIndex, hueAdjustment: params.hueAdjustment, saturationAdjustment: params.saturationAdjustment)
       case 2: layerColor = ColorUtils.halfSpectrumRainbowColor(for: layerIndex, hueAdjustment: params.hueAdjustment, saturationAdjustment: params.saturationAdjustment)
       default: layerColor = ColorUtils.rainbowColor(for: layerIndex, hueAdjustment: params.hueAdjustment, saturationAdjustment: params.saturationAdjustment)
       }
   } else {
       // Use presets, cycling through them and applying saturation adjustment using the shared utility
       if !params.colorPresets.isEmpty {
           let colorIndex = layerIndex % params.colorPresets.count
           let baseColor = params.colorPresets[colorIndex]
           // Use ColorUtils.adjustColor, passing useDefaultRainbowColors as false to prevent unwanted hue shift
           layerColor = ColorUtils.adjustColor(baseColor, hueShift: 0, saturationScale: params.saturationAdjustment, useDefaultRainbowColors: false)
       } else {
           layerColor = .gray // Fallback if no presets
       }
   }


   // Draw the shape with opacity from decoded parameters
   let baseOpacity = params.shapeAlpha // Use decoded alpha
   
   // Updated opacity calculation to match CanvasView
   let layerOpacity: Double
   if baseOpacity >= 0.99 { // Using 0.99 instead of 1.0 to account for floating point imprecision
       layerOpacity = 1.0 // Keep all layers fully opaque when alpha is 100%
   } else {
       // For alpha < 100%, maintain the existing behavior with reduced opacity for deeper layers
       layerOpacity = layerIndex == 0 ? baseOpacity : baseOpacity * 0.8
   }


   layerContext.fill(transformedPath, with: .color(layerColor.opacity(layerOpacity)))


   // Apply stroke using decoded parameters if width > 0
   if params.strokeWidth > 0 {
       layerContext.stroke(
           transformedPath,
           with: .color(params.strokeColor),  // Use decoded stroke color
           lineWidth: CGFloat(params.strokeWidth) // Use decoded stroke width
       )
   }
}


/// Creates the path for the selected shape.
private func createShapePath(shapeType: ShapesPanel.ShapeType, finalX: CGFloat, finalY: CGFloat, scaledRadius: CGFloat, baseRect: CGRect) -> Path {
   switch shapeType {
       case .circle: return Path(ellipseIn: baseRect)
       case .square: return Path(baseRect)
       case .triangle:
           var path = Path()
           path.move(to: CGPoint(x: finalX, y: finalY - scaledRadius))
           path.addLine(to: CGPoint(x: finalX - scaledRadius, y: finalY + scaledRadius))
           path.addLine(to: CGPoint(x: finalX + scaledRadius, y: finalY + scaledRadius))
           path.closeSubpath()
           return path
       case .hexagon: return createPolygonPath(center: CGPoint(x: finalX, y: finalY), radius: scaledRadius, sides: 6)
       case .star: return createStarPath(center: CGPoint(x: finalX, y: finalY), innerRadius: scaledRadius * 0.4, outerRadius: scaledRadius, points: 5)
       case .rectangle: return Path(CGRect(x: finalX - scaledRadius, y: finalY - scaledRadius * 0.6, width: scaledRadius * 2, height: scaledRadius * 1.2))
       case .oval: return Path(ellipseIn: CGRect(x: finalX - scaledRadius, y: finalY - scaledRadius * 0.6, width: scaledRadius * 2, height: scaledRadius * 1.2))
       case .diamond:
           var path = Path()
           path.move(to: CGPoint(x: finalX, y: finalY - scaledRadius))
           path.addLine(to: CGPoint(x: finalX + scaledRadius, y: finalY))
           path.addLine(to: CGPoint(x: finalX, y: finalY + scaledRadius))
           path.addLine(to: CGPoint(x: finalX - scaledRadius, y: finalY))
           path.closeSubpath()
           return path
       case .pentagon: return createPolygonPath(center: CGPoint(x: finalX, y: finalY), radius: scaledRadius, sides: 5)
       case .octagon: return createPolygonPath(center: CGPoint(x: finalX, y: finalY), radius: scaledRadius, sides: 8)
       case .arrow: return createArrowPath(center: CGPoint(x: finalX, y: finalY), size: scaledRadius)
       case .rhombus:
            var path = Path()
            path.move(to: CGPoint(x: finalX, y: finalY - scaledRadius))
            path.addLine(to: CGPoint(x: finalX + scaledRadius * 0.8, y: finalY))
            path.addLine(to: CGPoint(x: finalX, y: finalY + scaledRadius))
            path.addLine(to: CGPoint(x: finalX - scaledRadius * 0.8, y: finalY))
            path.closeSubpath()
            return path
       case .parallelogram: // Re-adding parallelogram case
           var path = Path()
           path.move(to: CGPoint(x: finalX - scaledRadius + scaledRadius * 0.4, y: finalY - scaledRadius * 0.6))
           path.addLine(to: CGPoint(x: finalX + scaledRadius + scaledRadius * 0.4, y: finalY - scaledRadius * 0.6))
           path.addLine(to: CGPoint(x: finalX + scaledRadius - scaledRadius * 0.4, y: finalY + scaledRadius * 0.6))
           path.addLine(to: CGPoint(x: finalX - scaledRadius - scaledRadius * 0.4, y: finalY + scaledRadius * 0.6))
           path.closeSubpath()
           return path
       case .capsule:
           // Create a capsule shape within the baseRect
           let capsuleRect = CGRect(
               x: finalX - scaledRadius * 0.8, // Match CanvasView
               y: finalY - scaledRadius,
               width: scaledRadius * 1.6,
               height: scaledRadius * 2
           )
           return Capsule(style: .continuous).path(in: capsuleRect)
   }
}


/// Helper to create polygon paths.
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


/// Helper to create star paths.
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


/// Helper to create arrow paths.
private func createArrowPath(center: CGPoint, size: Double) -> Path {
   let width = size * 1.5
   let height = size * 2
   let stemWidth = width * 0.3
   var path = Path()
   path.move(to: CGPoint(x: center.x, y: center.y - height * 0.5))
   path.addLine(to: CGPoint(x: center.x + width * 0.5, y: center.y))
   path.addLine(to: CGPoint(x: center.x + stemWidth * 0.5, y: center.y))
   path.addLine(to: CGPoint(x: center.x + stemWidth * 0.5, y: center.y + height * 0.5))
   path.addLine(to: CGPoint(x: center.x - stemWidth * 0.5, y: center.y + height * 0.5))
   path.addLine(to: CGPoint(x: center.x - stemWidth * 0.5, y: center.y))
   path.addLine(to: CGPoint(x: center.x - width * 0.5, y: center.y))
   path.closeSubpath()
   return path
}


// MARK: - Artwork Renderer View (for off-screen rendering)
private struct ArtworkRendererView: View {
   let params: ArtworkParameters
   // Define the rendering size (can be larger for better quality before resizing)
   private let renderSize = CGSize(width: 500, height: 500)


   var body: some View {
       Canvas { context, size in
           // Fill background
           context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(params.backgroundColor))
           // Draw the shapes using the *original* (non-simplified) drawing logic
           drawShapes(context: context, size: size, params: params)
       }
       .frame(width: renderSize.width, height: renderSize.height)
   }
}


// MARK: - Preview
#Preview {
  GalleryPanel(
      isShowing: .constant(true),
      confirmedArtworkId: .constant(nil),
      onSwitchToProperties: { print("Switch to Properties") },
      onSwitchToColorShapes: { print("Switch to Color/Shapes") },
      onSwitchToShapes: { print("Switch to Shapes") },
      onLoadArtwork: { artwork in print("Preview: Load artwork \(artwork.id)") } // << Add mock callback for preview
  )
  // Add a mock artwork item for the grid item preview
  .overlay(
      ArtworkGridItem(
          artwork: ArtworkData(deviceId: "previewDevice", artworkString: "shape:circle;colors:#FF0000", timestamp: Date(), title: "Preview Item", pieceId: "preview123"),
          thumbnail: nil,
          onTap: { print("Preview: Tap") },
          onRename: { print("Preview: Rename") },
          onDelete: { print("Preview: Delete") },
          onShare: { print("Preview: Share") }
      )
      .padding()
      .background(Color.gray.opacity(0.2))
  )
}


// Helper extension to create a new ArtworkData with an updated title (immutable update)
extension ArtworkData {
   func withUpdatedTitle(_ newTitle: String) -> ArtworkData {
       return ArtworkData(
           deviceId: self.deviceId,
           artworkString: self.artworkString,
           timestamp: self.timestamp,
           title: newTitle, // Use the new title
           pieceId: self.pieceId
       )
   }
}
