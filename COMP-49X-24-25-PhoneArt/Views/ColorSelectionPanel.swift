// ColorSelectionPanel.swift


import SwiftUI
import Combine


/// A shared model to keep track of color presets across views
class ColorPresetManager: ObservableObject {
   static let shared = ColorPresetManager()
  
   @Published var colorPresets: [Color] {
       didSet {
           savePresetsToUserDefaults()
           distributeColorsToElements()
       }
   }
  
   @Published var numberOfVisiblePresets: Int = 5 {
       didSet {
           print("Updated numberOfVisiblePresets to: \(numberOfVisiblePresets)")
           UserDefaults.standard.set(numberOfVisiblePresets, forKey: "numberOfVisiblePresets")
           distributeColorsToElements()
       }
   }
  
   /// Controls whether to use default rainbow colors instead of presets
   @Published var useDefaultRainbowColors: Bool = false {
       didSet {
           // Save the preference
           UserDefaults.standard.set(useDefaultRainbowColors, forKey: "useDefaultRainbowColors")
           // Notify observers to redraw with the new color scheme
           NotificationCenter.default.post(name: Notification.Name("ColorPresetsChanged"), object: nil)
       }
   }
  
   /// Controls which rainbow style to use (0: dynamic, 1: cyberpunk, 2: half-spectrum)
   @Published var rainbowStyle: Int = 0 {
       didSet {
           // Save the preference
           UserDefaults.standard.set(rainbowStyle, forKey: "rainbowStyle")
           // Notify observers to redraw with the new color scheme
           NotificationCenter.default.post(name: Notification.Name("ColorPresetsChanged"), object: nil)
       }
   }
  
   /// Stores the background color for the canvas
   @Published var backgroundColor: Color = .white {
       didSet {
           // Save the preference
           if let colorData = try? JSONEncoder().encode(colorToComponents(backgroundColor)) {
               UserDefaults.standard.set(colorData, forKey: "canvasBackgroundColor")
           }
           // Notify observers to update the background
           NotificationCenter.default.post(name: Notification.Name("BackgroundColorChanged"), object: nil)
       }
   }
  
   /// Stores the stroke color for shapes
   @Published var strokeColor: Color = .black {
       didSet {
           // Save the preference
           if let colorData = try? JSONEncoder().encode(colorToComponents(strokeColor)) {
               UserDefaults.standard.set(colorData, forKey: "shapeStrokeColor")
           }
           // Notify observers to update
           NotificationCenter.default.post(name: Notification.Name("StrokeSettingsChanged"), object: nil)
       }
   }
  
   /// Stores the stroke width for shapes
   @Published var strokeWidth: Double = 2.0 {
       didSet {
           // Save the preference
           UserDefaults.standard.set(strokeWidth, forKey: "shapeStrokeWidth")
           // Notify observers to update
           NotificationCenter.default.post(name: Notification.Name("StrokeSettingsChanged"), object: nil)
       }
   }
  
   /// Stores the alpha (opacity) value for shapes
   @Published var shapeAlpha: Double = 1.0 {
       didSet {
           // Save the preference
           UserDefaults.standard.set(shapeAlpha, forKey: "shapeAlpha")
           // Notify observers to update
           NotificationCenter.default.post(name: Notification.Name("StrokeSettingsChanged"), object: nil)
       }
   }
  
   /// Stores the hue adjustment for rainbow colors (0-1)
   @Published var hueAdjustment: Double = 0.5 {
       didSet {
           // Save the preference
           UserDefaults.standard.set(hueAdjustment, forKey: "hueAdjustment")
           // Notify observers to update
           NotificationCenter.default.post(name: Notification.Name("ColorPresetsChanged"), object: nil)
       }
   }
  
   /// Stores the saturation adjustment for rainbow colors (0-1)
   @Published var saturationAdjustment: Double = 0.8 {
       didSet {
           // Save the preference
           UserDefaults.standard.set(saturationAdjustment, forKey: "saturationAdjustment")
           // Notify observers to update
           NotificationCenter.default.post(name: Notification.Name("ColorPresetsChanged"), object: nil)
       }
   }
  
   // Track elements on the canvas that need color updates
   @Published var canvasElements: [UUID: Color] = [:]
  
   init() {
       // Initialize with default values first - 10 distinct colors
       self.colorPresets = [
           .purple, .blue, .pink, .yellow, .green,
           .red, .orange, .cyan, .indigo, .mint
       ]
      
       // Load number of visible presets
       let savedCount = UserDefaults.standard.integer(forKey: "numberOfVisiblePresets")
       if savedCount >= 1 && savedCount <= 10 {
           self.numberOfVisiblePresets = savedCount
       } else {
           // Set default of 5 if no valid value is saved
           self.numberOfVisiblePresets = 5
       }
      
       // Load default colors toggle preference
       self.useDefaultRainbowColors = UserDefaults.standard.bool(forKey: "useDefaultRainbowColors")
      
       // Load rainbow style preference
       self.rainbowStyle = UserDefaults.standard.integer(forKey: "rainbowStyle")
      
       // Load background color
       if let data = UserDefaults.standard.data(forKey: "canvasBackgroundColor"),
          let components = try? JSONDecoder().decode([CGFloat].self, from: data) {
           self.backgroundColor = Color(
               red: Double(components[0]),
               green: Double(components[1]),
               blue: Double(components[2]),
               opacity: Double(components[3])
           )
       } else {
           // Default to white if no saved color
           self.backgroundColor = .white
       }
      
       // Load stroke color
       if let data = UserDefaults.standard.data(forKey: "shapeStrokeColor"),
          let components = try? JSONDecoder().decode([CGFloat].self, from: data) {
           self.strokeColor = Color(
               red: Double(components[0]),
               green: Double(components[1]),
               blue: Double(components[2]),
               opacity: Double(components[3])
           )
       } else {
           // Default to black if no saved color
           self.strokeColor = .black
       }
      
       // Load stroke width
       let savedStrokeWidth = UserDefaults.standard.double(forKey: "shapeStrokeWidth")
       if savedStrokeWidth > 0 {
           self.strokeWidth = savedStrokeWidth
       } else {
           // Default to 2.0 if no valid value is saved
           self.strokeWidth = 2.0
       }
      
       // Load alpha value
       let savedAlpha = UserDefaults.standard.double(forKey: "shapeAlpha")
       if savedAlpha > 0 && savedAlpha <= 1.0 {
           self.shapeAlpha = savedAlpha
       } else {
           // Default to 1.0 (fully opaque) if no valid value is saved
           self.shapeAlpha = 1.0
       }
      
       // Load hue adjustment
       let savedHue = UserDefaults.standard.double(forKey: "hueAdjustment")
       if savedHue >= 0.0 && savedHue <= 1.0 {
           self.hueAdjustment = savedHue
       } else {
           // Default to 0.5 if no valid value is saved
           self.hueAdjustment = 0.5
       }
      
       // Load saturation adjustment
       let savedSaturation = UserDefaults.standard.double(forKey: "saturationAdjustment")
       if savedSaturation >= 0.0 && savedSaturation <= 1.0 {
           self.saturationAdjustment = savedSaturation
       } else {
           // Default to 0.8 if no valid value is saved
           self.saturationAdjustment = 0.8
       }
      
       print("ColorPresetManager initialized with \(colorPresets.count) colors and \(numberOfVisiblePresets) visible presets")
      
       // Then try to load from UserDefaults
       if let savedColors = loadPresetsFromUserDefaults() {
           // Make sure we have at least 10 colors
           var loadedColors = savedColors
           if loadedColors.count < 10 {
               // Append default colors if not enough saved
               let defaultColors: [Color] = [.purple, .blue, .pink, .yellow, .green, .red, .orange, .cyan, .indigo, .mint]
               for i in loadedColors.count..<10 {
                   loadedColors.append(defaultColors[i % defaultColors.count])
               }
           }
           self.colorPresets = loadedColors
           print("Loaded \(loadedColors.count) colors from UserDefaults")
       }
   }
  
   // Register a canvas element to receive color updates
   func registerElement(id: UUID, initialColor: Color) {
       canvasElements[id] = initialColor
       // Apply appropriate color based on current distribution
       distributeColorsToElements()
   }
  
   // Remove a canvas element
   func unregisterElement(id: UUID) {
       canvasElements.removeValue(forKey: id)
   }
  
   // Distribute colors to all registered elements based on visible presets
   private func distributeColorsToElements() {
       // Get only the visible colors based on numberOfVisiblePresets
       let visibleColors = Array(colorPresets.prefix(min(numberOfVisiblePresets, colorPresets.count)))
      
       // Skip if no colors or no elements
       guard !visibleColors.isEmpty, !canvasElements.isEmpty else { return }
      
       print("Distributing \(visibleColors.count) colors to \(canvasElements.count) elements")
      
       // Loop through elements and assign colors based on their position
       let sortedIDs = canvasElements.keys.sorted()
       for (index, id) in sortedIDs.enumerated() {
           let colorIndex = index % visibleColors.count
           canvasElements[id] = visibleColors[colorIndex]
           print("Element \(index): assigned color \(colorIndex) of \(visibleColors.count)")
       }
      
       // Force a UI update to reflect the changes
       objectWillChange.send()
      
       // Post notification for canvas to update
       NotificationCenter.default.post(name: Notification.Name("ColorPresetsChanged"), object: nil)
   }
  
   // Get the appropriate color for an element
   func colorForElement(id: UUID) -> Color {
       return canvasElements[id] ?? colorPresets[0]
   }
  
   // Get the appropriate color for an element at a specific position
   func colorForPosition(position: Int) -> Color {
       // If using default rainbow colors, generate a rainbow color based on position
       if useDefaultRainbowColors {
           // Use the shared ColorUtils functions
           let currentHueAdj = self.hueAdjustment
           let currentSatAdj = self.saturationAdjustment
           switch rainbowStyle {
           case 1:
               return ColorUtils.cyberpunkRainbowColor(for: position, hueAdjustment: currentHueAdj, saturationAdjustment: currentSatAdj)
           case 2:
               return ColorUtils.halfSpectrumRainbowColor(for: position, hueAdjustment: currentHueAdj, saturationAdjustment: currentSatAdj)
           default:
               return ColorUtils.rainbowColor(for: position, hueAdjustment: currentHueAdj, saturationAdjustment: currentSatAdj)
           }
       }

       // Otherwise use preset colors
       let visibleColors = Array(colorPresets.prefix(min(numberOfVisiblePresets, colorPresets.count)))
       guard !visibleColors.isEmpty else { return .black }
       let colorIndex = position % visibleColors.count
       let baseColor = visibleColors[colorIndex]

       // Use the shared ColorUtils.adjustColor function
       // IMPORTANT: Always pass false for useDefaultRainbowColors when adjusting PRESETS
       // This prevents applying rainbow hue shift to preset colors.
       return ColorUtils.adjustColor(baseColor, hueShift: hueAdjustment - 0.5, saturationScale: saturationAdjustment, useDefaultRainbowColors: false)
   }
  
   // This is triggered whenever colorPresets changes
   func savePresetsToUserDefaults() {
       let colorData = colorPresets.map { color -> [CGFloat] in
           let uiColor = UIColor(color)
           var red: CGFloat = 0
           var green: CGFloat = 0
           var blue: CGFloat = 0
           var alpha: CGFloat = 0
           uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
           return [red, green, blue, alpha]
       }
      
       UserDefaults.standard.set(try? JSONEncoder().encode(colorData), forKey: "savedColorPresets")
   }
  
   // Load color presets from UserDefaults
   private func loadPresetsFromUserDefaults() -> [Color]? {
       guard let data = UserDefaults.standard.data(forKey: "savedColorPresets"),
             let colorData = try? JSONDecoder().decode([[CGFloat]].self, from: data) else {
           return nil
       }
      
       return colorData.map { components in
           Color(red: Double(components[0]),
                green: Double(components[1]),
                blue: Double(components[2]),
                opacity: Double(components[3]))
       }
   }
  
   // Helper method to convert Color to components array for storage
   private func colorToComponents(_ color: Color) -> [CGFloat] {
       let uiColor = UIColor(color)
       var red: CGFloat = 0
       var green: CGFloat = 0
       var blue: CGFloat = 0
       var alpha: CGFloat = 0
       uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
       return [red, green, blue, alpha]
   }

   /// Updates the ColorPresetManager's properties based on decoded artwork parameters.
   /// - Parameter decodedParams: A dictionary decoded from an ArtworkData string.
   func update(from decodedParams: [String: String]) {
       print("[ColorPresetManager] Updating from decoded params: \(decodedParams)")

       // Helper to safely extract double values
       func doubleValue(from key: String, default defaultValue: Double) -> Double {
           guard let stringValue = decodedParams[key], let value = Double(stringValue) else {
               print("[ColorPresetManager] Warning: Could not decode Double for key '\(key)', using default: \(defaultValue)")
               return defaultValue
           }
           return value
       }
       // Helper to safely extract Int values
       func intValue(from key: String, default defaultValue: Int) -> Int {
           guard let stringValue = decodedParams[key], let value = Int(stringValue) else {
                print("[ColorPresetManager] Warning: Could not decode Int for key '\(key)', using default: \(defaultValue)")
               return defaultValue
           }
           return value
       }
       // Helper to safely extract Bool values
       func boolValue(from key: String, default defaultValue: Bool) -> Bool {
           guard let stringValue = decodedParams[key] else {
                print("[ColorPresetManager] Warning: Could not decode Bool for key '\(key)', using default: \(defaultValue)")
               return defaultValue
           }
           return stringValue.lowercased() == "true"
       }

       // Update Presets
       if let colorsString = decodedParams["colors"] {
           let loadedColors = ArtworkData.reconstructColors(from: colorsString)
           if !loadedColors.isEmpty {
               // Ensure we always have at least 10 slots, padding if necessary
               var finalPresets = loadedColors
               if finalPresets.count < 10 {
                   let defaultColors: [Color] = [.purple, .blue, .pink, .yellow, .green, .red, .orange, .cyan, .indigo, .mint]
                   for i in finalPresets.count..<10 {
                       finalPresets.append(defaultColors[i % defaultColors.count])
                   }
               }
               self.colorPresets = finalPresets
               print("[ColorPresetManager] Updated presets. Count: \(finalPresets.count)")
           } else {
               print("[ColorPresetManager] Warning: Decoded 'colors' string resulted in empty array.")
           }
       }

       // Update Background Color
       if let backgroundHex = decodedParams["background"],
          let bgColor = ArtworkData.hexToColor(backgroundHex) {
           self.backgroundColor = bgColor
           print("[ColorPresetManager] Updated background color to: \(backgroundHex)")
       } else {
            print("[ColorPresetManager] Warning: Could not decode 'background' color.")
       }

       // Update Rainbow Mode & Settings
       self.useDefaultRainbowColors = boolValue(from: "useRainbow", default: self.useDefaultRainbowColors)
       self.rainbowStyle = intValue(from: "rainbowStyle", default: self.rainbowStyle)
       self.hueAdjustment = doubleValue(from: "hueAdj", default: self.hueAdjustment)
       self.saturationAdjustment = doubleValue(from: "satAdj", default: self.saturationAdjustment)
       print("[ColorPresetManager] Updated rainbow settings: use=\(useDefaultRainbowColors), style=\(rainbowStyle), hue=\(hueAdjustment), sat=\(saturationAdjustment)")

       // Update Preset Count (visible presets)
       self.numberOfVisiblePresets = intValue(from: "presetCount", default: self.numberOfVisiblePresets)
       print("[ColorPresetManager] Updated numberOfVisiblePresets to: \(numberOfVisiblePresets)")

       // Update Stroke & Alpha
       self.strokeColor = ArtworkData.hexToColor(decodedParams["strokeColor"] ?? "") ?? self.strokeColor
       self.strokeWidth = doubleValue(from: "strokeWidth", default: self.strokeWidth)
       self.shapeAlpha = doubleValue(from: "alpha", default: self.shapeAlpha)
       print("[ColorPresetManager] Updated stroke/alpha: width=\(strokeWidth), alpha=\(shapeAlpha), color=\(strokeColor.toHex() ?? "N/A")")
       
       // Crucially, trigger notifications/updates AFTER all properties are set
       objectWillChange.send()
       NotificationCenter.default.post(name: Notification.Name("ColorPresetsChanged"), object: nil)
       NotificationCenter.default.post(name: Notification.Name("BackgroundColorChanged"), object: nil)
       NotificationCenter.default.post(name: Notification.Name("StrokeSettingsChanged"), object: nil)
       print("[ColorPresetManager] Update complete and notifications sent.")
   }

   /// Resets all manager properties to their initial default values.
   func resetToDefaults() {
       print("[ColorPresetManager] Resetting to default values.")
       // Default Presets
       self.colorPresets = [
           .purple, .blue, .pink, .yellow, .green,
           .red, .orange, .cyan, .indigo, .mint
       ]
       self.numberOfVisiblePresets = 5

       // Default Rainbow Settings
       self.useDefaultRainbowColors = false
       self.rainbowStyle = 0
       self.hueAdjustment = 0.5
       self.saturationAdjustment = 0.8

       // Default Background
       self.backgroundColor = .white

       // Default Stroke & Alpha
       self.strokeColor = .black
       self.strokeWidth = 2.0
       self.shapeAlpha = 1.0

       // Save defaults to UserDefaults (optional, could also clear them)
       savePresetsToUserDefaults()
       UserDefaults.standard.set(numberOfVisiblePresets, forKey: "numberOfVisiblePresets")
       UserDefaults.standard.set(useDefaultRainbowColors, forKey: "useDefaultRainbowColors")
       UserDefaults.standard.set(rainbowStyle, forKey: "rainbowStyle")
       if let bgColorData = try? JSONEncoder().encode(colorToComponents(backgroundColor)) {
           UserDefaults.standard.set(bgColorData, forKey: "canvasBackgroundColor")
       }
       if let strokeColorData = try? JSONEncoder().encode(colorToComponents(strokeColor)) {
           UserDefaults.standard.set(strokeColorData, forKey: "shapeStrokeColor")
       }
       UserDefaults.standard.set(strokeWidth, forKey: "shapeStrokeWidth")
       UserDefaults.standard.set(shapeAlpha, forKey: "shapeAlpha")
       UserDefaults.standard.set(hueAdjustment, forKey: "hueAdjustment")
       UserDefaults.standard.set(saturationAdjustment, forKey: "saturationAdjustment")

       // Trigger updates
       objectWillChange.send()
       NotificationCenter.default.post(name: Notification.Name("ColorPresetsChanged"), object: nil)
       NotificationCenter.default.post(name: Notification.Name("BackgroundColorChanged"), object: nil)
       NotificationCenter.default.post(name: Notification.Name("StrokeSettingsChanged"), object: nil)
       print("[ColorPresetManager] Reset complete and notifications sent.")
   }
}


/// A panel that provides color selection functionality for shapes on the canvas.
/// Features:
/// - Five preset color slots for quick access to commonly used colors
/// - Color picker for selecting custom colors
/// - Hex color input field for precise color values
/// - Real-time color updates to the selected shape
struct ColorSelectionPanel: View {
   /// Index of the currently selected color preset
   @State private var selectedPresetIndex: Int = 0
  
   /// Use the shared observable object for color presets
   @ObservedObject private var presetManager = ColorPresetManager.shared
  
   /// Binding to the currently selected color, shared with the canvas
   @Binding var selectedColor: Color
  
   /// Current hex color value displayed in the text field
   @State private var hexValue: String = "#000000"
   
   // MARK: - Tooltip State
   @State private var showingTooltip: Bool = false
   @State private var tooltipText: String = ""
   @State private var activeTooltipIdentifier: String? = nil
   @State private var presetCountText: String = "5"
   
   // MARK: - Tooltip Descriptions
   private let tooltipDescriptions: [String: String] = [
       "Preset Count": "Determines how many color preset slots are visible for selection.",
       "Color Presets": "Quick access to saved colors you can apply to your artwork.",
       "Edit Color": "Change the selected color using the color picker or hex code input."
   ]
  
   /// Initializes the color selection panel with a binding to the selected color
   /// - Parameter selectedColor: Binding to the color that will be applied to shapes
   init(selectedColor: Binding<Color>) {
       self._selectedColor = selectedColor
       self._hexValue = State(initialValue: selectedColor.wrappedValue.toHex() ?? "#000000")
       self._presetCountText = State(initialValue: "\(ColorPresetManager.shared.numberOfVisiblePresets)")
   }
  
   var body: some View {
       ScrollView {
           VStack(alignment: .leading, spacing: 12) {
               // Slider for number of presets using propertyRow pattern
               propertyRow(title: "Preset Count", icon: "circle.grid.2x2") {
                   HStack {
                       Slider(
                           value: Binding<Double>(
                               get: { Double(presetManager.numberOfVisiblePresets) },
                               set: { newValue in
                                   // Immediately update the number of visible presets
                                   let newCount = max(1, min(10, Int(newValue)))
                                   if presetManager.numberOfVisiblePresets != newCount {
                                       presetManager.numberOfVisiblePresets = newCount
                                       presetCountText = "\(newCount)"
                                      
                                       // Immediately notify about the change
                                       NotificationCenter.default.post(
                                           name: Notification.Name("ColorPresetsChanged"),
                                           object: nil
                                       )
                                      
                                       // Force UI refresh
                                       presetManager.objectWillChange.send()
                                   }
                               }
                           ),
                           in: 1...10,
                           step: 1
                       )
                       .accessibilityIdentifier("Preset Count Slider")
                      
                       TextField("", text: $presetCountText)
                           .frame(width: 50)
                           .textFieldStyle(RoundedBorderTextFieldStyle())
                           .keyboardType(.numberPad)
                           .multilineTextAlignment(.center)
                           .onChange(of: presetCountText) { _, newValue in
                               if let value = Int(newValue), value >= 1, value <= 10 {
                                   presetManager.numberOfVisiblePresets = value
                                   // Notify about the change
                                   NotificationCenter.default.post(
                                       name: Notification.Name("ColorPresetsChanged"),
                                       object: nil
                                   )
                               }
                           }
                   }
               }
               .padding(.bottom, 12)
              
               // Preset color slots - clean design without border
               propertyRow(title: "Color Presets", icon: "paintbrush.pointed") {
                   ScrollView(.horizontal, showsIndicators: false) {
                       HStack(spacing: 12) {
                           // Show the actual visible colors
                           let visiblePresets = min(presetManager.numberOfVisiblePresets, presetManager.colorPresets.count)
                           let visibleColors = Array(presetManager.colorPresets.prefix(visiblePresets))
                          
                           ForEach(0..<visiblePresets, id: \.self) { index in
                               ColorPresetButton(
                                   color: visibleColors[index],
                                   isSelected: selectedPresetIndex == index
                               ) {
                                   selectedPresetIndex = index
                                   selectedColor = visibleColors[index]
                                   hexValue = selectedColor.toHex() ?? "#000000"
                               }
                           }
                       }
                       .padding(.horizontal, 10)
                       .padding(.vertical, 8)
                   }
                   .frame(height: 70)
               }
               .padding(.bottom, 12)
              
               // Color picker section with consistent styling
               propertyRow(title: "Edit Color", icon: "eyedropper") {
                   HStack(spacing: 16) {
                       // Custom styled color picker
                       ColorPicker("", selection: Binding(
                           get: { selectedColor },
                           set: { newColor in
                               selectedColor = newColor
                               // Update the color preset in our manager
                               var updatedPresets = presetManager.colorPresets
                               updatedPresets[selectedPresetIndex] = newColor
                               presetManager.colorPresets = updatedPresets
                               hexValue = newColor.toHex() ?? "#000000"
                           }
                       ))
                       .labelsHidden()
                       .frame(width: 40, height: 40)
                       .background(
                           Circle()
                               .fill(selectedColor)
                               .frame(width: 40, height: 40)
                               .overlay(
                                   Circle()
                                       .stroke(Color.black, lineWidth: 3)
                               )
                       )
                       .scaleEffect(1.2) // Slightly larger to ensure the picker is easily tappable
                       .clipShape(Circle())
                      
                       // Hex input field
                       TextField("Hex", text: $hexValue)
                           .textFieldStyle(RoundedBorderTextFieldStyle())
                           .frame(height: 40)
                           .onChange(of: hexValue) { _, newValue in
                               if let color = Color(hex: newValue) {
                                   selectedColor = color
                                   // Update the color preset in our manager
                                   var updatedPresets = presetManager.colorPresets
                                   updatedPresets[selectedPresetIndex] = color
                                   presetManager.colorPresets = updatedPresets
                               }
                           }
                   }
               }
           }
           .padding(8)
           .background(Color(.systemBackground))
           .cornerRadius(12)
           .simultaneousGesture(
               TapGesture()
                   .onEnded { _ in
                       if showingTooltip {
                           withAnimation(.easeOut(duration: 0.2)) {
                               showingTooltip = false
                               activeTooltipIdentifier = nil
                           }
                       }
                   }
           )
       }
   }
   
   // MARK: - UI Components
   
   /// Creates a custom property control row with consistent styling and tooltip support
   private func propertyRow<Content: View>(
       title: String,
       icon: String,
       @ViewBuilder content: () -> Content
   ) -> some View {
       let tooltipIdentifier = title // Use title as a unique identifier for the tooltip

       return ZStack(alignment: .topLeading) { // Use ZStack for tooltip overlay
           // Main Row Content - Changed to HStack
           HStack { // Changed from VStack
               Image(systemName: icon)
                   .foregroundColor(.secondary)
                   .frame(width: 20)
               
               Text(title)
                   .font(.headline)
                   .frame(width: 80, alignment: .leading) // Changed width from 100 to 80
               
               // Info Button for Tooltip
               Button {
                   // Set the text and identifier for the tooltip
                   tooltipText = tooltipDescriptions[title] ?? "No description available."
                   activeTooltipIdentifier = tooltipIdentifier
                   withAnimation { // Animate showing
                       showingTooltip = true // Show the overlay
                   }
               } label: {
                   Image(systemName: "info.circle")
                       .foregroundColor(.blue)
               }
               .accessibilityLabel("\(title) Info")
               .accessibilityIdentifier("\(title)InfoButton")
               
               // Content (Slider, TextField, etc.) now directly in HStack
               content()
                   .frame(maxWidth: .infinity) // Allow content to expand
           }
           .padding()
           .background(Color(uiColor: .systemGray6))
           .cornerRadius(8)
           
           // Tooltip overlay - only shown when this specific tooltip is active
           if showingTooltip && activeTooltipIdentifier == tooltipIdentifier {
               // Use GeometryReader to get container width for centering
               GeometryReader { geometry in
                   // Combined tooltip with single background
                   ZStack(alignment: .topTrailing) {
                       SharedTooltipView(text: tooltipText)
                           .padding(.horizontal, 16)
                           .padding(.vertical, 12)
                           .padding(.trailing, 30) // More room for the X button with larger text
                       
                       // X button - now directly in ZStack for better positioning
                       Button {
                           withAnimation(.easeOut(duration: 0.2)) {
                               showingTooltip = false
                               activeTooltipIdentifier = nil
                           }
                       } label: {
                           Image(systemName: "xmark.circle.fill")
                               .font(.system(size: 20)) // Larger X button
                               .foregroundColor(.white)
                               .padding(4)
                       }
                       .accessibility(label: Text("Close tooltip"))
                   }
                   .background(Color(UIColor.systemGray2))
                   .cornerRadius(8)
                   .shadow(radius: 2)
                   // Explicitly prevent tap-through with a high-priority gesture
                   .gesture(
                       TapGesture()
                           .onEnded { _ in
                               // Do nothing, but consume the event
                           }
                       , including: .all) // Higher priority than the ScrollView's gesture
                   // Center horizontally, position above the row
                   .position(
                       x: geometry.size.width / 2,
                       y: 10 // Position tooltip near top of the row
                   )
                   .transition(.opacity.combined(with: .scale))
                   .zIndex(1) // Ensure tooltip appears above other content
               }
           }
       }
   }
}


/// Helper view for preset color buttons that visually indicate selection
struct ColorPresetButton: View {
   /// The color to display in this preset button
   let color: Color
  
   /// Whether this preset is currently selected
   let isSelected: Bool
  
   /// Action to perform when this preset is tapped
   let action: () -> Void
  
   var body: some View {
       Button(action: action) {
           Circle()
               .fill(color)
               .frame(width: 40, height: 40)
               .overlay(
                   Circle()
                       .stroke(Color.black, lineWidth: 3)
               )
               .overlay(
                   Circle()
                       .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
               )
               .shadow(color: isSelected ? .black.opacity(0.3) : .clear, radius: 2)
       }
   }
}


// MARK: - Color Extensions for Hex Conversion


/// Extensions to Color for hex string conversion
extension Color {
   /// Converts a Color to its hexadecimal string representation
   /// - Returns: A string in the format "#RRGGBB" or nil if conversion fails
   func toHex() -> String? {
       let uiColor = UIColor(self)
       guard let components = uiColor.cgColor.components else { return nil }
      
       let r: Float
       let g: Float
       let b: Float
      
       if components.count >= 3 {
           r = Float(components[0])
           g = Float(components[1])
           b = Float(components[2])
       } else {
           // Handle grayscale colors
           r = Float(components[0])
           g = Float(components[0])
           b = Float(components[0])
       }
      
       return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
   }
  
   /// Creates a Color from a hexadecimal string
   /// - Parameter hex: A string in the format "#RRGGBB" or "RRGGBB"
   init?(hex: String) {
       var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
       hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
      
       var rgb: UInt64 = 0
      
       guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
      
       self.init(
           red: Double((rgb & 0xFF0000) >> 16) / 255.0,
           green: Double((rgb & 0x00FF00) >> 8) / 255.0,
           blue: Double(rgb & 0x0000FF) / 255.0
       )
   }
}


struct ColorSelectionPanel_Previews: PreviewProvider {
   static var previews: some View {
       ColorSelectionPanel(selectedColor: .constant(.purple))
           .frame(width: 300)
           .padding()
   }
}
