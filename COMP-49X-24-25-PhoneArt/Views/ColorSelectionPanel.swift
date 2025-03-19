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
           switch rainbowStyle {
           case 1:
               return cyberpunkRainbowColor(for: position)
           case 2:
               return halfSpectrumRainbowColor(for: position)
           default:
               return rainbowColor(for: position)
           }
       }
      
       // Otherwise use preset colors
       // Ensure we only use the number of visible presets
       let visibleColors = Array(colorPresets.prefix(min(numberOfVisiblePresets, colorPresets.count)))
      
       // If there are no colors visible, return a default color
       guard !visibleColors.isEmpty else { return .black }
      
       // Use modulo to cycle through the visible colors based on position
       let colorIndex = position % visibleColors.count
      
       // Log the color selection for debugging
       print("Position \(position) using color \(colorIndex) of \(visibleColors.count) visible colors")
      
       // Apply hue and saturation adjustments to the custom color
       let baseColor = visibleColors[colorIndex]
       return adjustColor(baseColor, hueShift: hueAdjustment - 0.5, saturationScale: saturationAdjustment)
   }
  
   /// Generate a rainbow color based on position
   /// - Parameter position: The position in the sequence
   /// - Returns: A color from the rainbow sequence
   private func rainbowColor(for position: Int) -> Color {
       // Create a more vibrant and dynamic rainbow pattern
       // Use trigonometric functions to create oscillating patterns
      
       // FASTER CYCLE: Make colors repeat more frequently by multiplying position
       // This makes the color wheel repeat every 12 positions instead of 360
       _ = 12
       let scaledPosition = (position * 30) % 360
      
       // Base angle adjusted by position
       let angle = Double(position) * 0.1
      
       // Oscillating hue with non-linear progression
       let baseHue = (Double(scaledPosition) / 360.0)
       let hueShift = 0.15 * sin(angle * 0.5)
      
       // Apply the user's hue adjustment
       let hueOffset = hueAdjustment - 0.5 // Convert 0-1 range to -0.5 to +0.5 range
       let finalHue = (baseHue + hueShift + hueOffset).truncatingRemainder(dividingBy: 1.0)
      
       // Dynamic saturation - slight variations to add depth
       let saturationBase = 0.9 * saturationAdjustment // Apply user's saturation preference
       let saturationVariation = 0.1 * sin(angle * 0.7) * saturationAdjustment
       let saturation = min(1.0, max(0.3, saturationBase + saturationVariation))
      
       // Dynamic brightness - adds visual interest
       let brightnessBase = 0.95
       let brightnessVariation = 0.1 * cos(angle * 0.3)
       let brightness = min(1.0, max(0.8, brightnessBase + brightnessVariation))
      
       return Color(hue: finalHue, saturation: saturation, brightness: brightness)
   }
  
   /// Generate a cyberpunk-inspired rainbow color based on position
   /// - Parameter position: The position in the sequence
   /// - Returns: A color with cyberpunk aesthetic
   private func cyberpunkRainbowColor(for position: Int) -> Color {
       // Create a more extreme, vibrant cyberpunk color pattern
       // Inspired by neon city lights and cyberpunk aesthetics
      
       // FASTER CYCLE: Make colors repeat more frequently
       // This makes the color wheel repeat every 15 positions
       _ = 15
       let scaledPosition = (position * 24) % 360
      
       // Use position to create a non-linear progression through color space
       let normalizedPosition = Double(position) * 0.05
      
       // Complex hue calculation with multiple sine waves for more interesting patterns
       let baseHue = (Double(scaledPosition) / 360.0)
       let hueShift1 = 0.2 * sin(normalizedPosition * 1.1)
       let hueShift2 = 0.15 * sin(normalizedPosition * 0.7 + 2.0)
      
       // Apply the user's hue adjustment
       let hueOffset = hueAdjustment - 0.5 // Convert 0-1 range to -0.5 to +0.5 range
       let finalHue = (baseHue + hueShift1 + hueShift2 + hueOffset).truncatingRemainder(dividingBy: 1.0)
      
       // Oscillating saturation with occasional dips for color contrast
       let satPhase = sin(normalizedPosition * 0.5)
       // Apply user's saturation preference
       let saturation = min(1.0, (0.85 + (0.15 * satPhase)) * saturationAdjustment)
      
       // Brightness that occasionally flares brighter for "neon" effect
       let brightPhase = 0.5 * sin(normalizedPosition * 1.7) + 0.5 * cos(normalizedPosition * 2.3)
       let brightness = min(1.0, 0.85 + 0.15 * brightPhase)
      
       return Color(hue: finalHue, saturation: saturation, brightness: brightness)
   }
  
   /// Generate a half-spectrum rainbow that cycles through approximately half the color wheel
   /// - Parameter position: The position in the sequence
   /// - Returns: A color from a limited part of the color spectrum
   private func halfSpectrumRainbowColor(for position: Int) -> Color {
       // FASTER CYCLE: Make colors repeat more frequently
       // This makes the color range repeat every 10 positions
       _ = 10
       let scaledPosition = (position * 18) % 180
      
       // Use a range of only 180 degrees (half) of the color wheel
       // We'll use the range from purple to green which includes vibrant colors
      
       // Start at purple (270°) and go 180° around the wheel
       let startHue = 0.75 // Purple (270° / 360° = 0.75)
       let hueRange = 0.5  // Half the wheel (180° / 360° = 0.5)
      
       // Base angle with smaller increments to make the transition smoother
       let angle = Double(position) * 0.05
      
       // Calculate the base hue in our limited range
       let positionInRange = Double(scaledPosition) / 180.0
       // Apply the user's hue adjustment
       let hueOffset = hueAdjustment - 0.5 // Convert 0-1 range to -0.5 to +0.5 range
       let baseHue = startHue + (positionInRange * hueRange) + hueOffset
       let wrappedHue = baseHue.truncatingRemainder(dividingBy: 1.0)
      
       // Add oscillation to the hue for more interest
       let hueShift = 0.08 * sin(angle * 0.7)
       let finalHue = (wrappedHue + hueShift).truncatingRemainder(dividingBy: 1.0)
      
       // Dynamic saturation and brightness similar to the full rainbow
       // Apply user's saturation preference
       let saturationBase = 0.95 * saturationAdjustment
       let saturationVariation = 0.05 * sin(angle * 0.9) * saturationAdjustment
       let saturation = min(1.0, max(0.3, saturationBase + saturationVariation))
      
       let brightnessBase = 0.95
       let brightnessVariation = 0.05 * cos(angle * 0.5)
       let brightness = min(1.0, max(0.9, brightnessBase + brightnessVariation))
      
       return Color(hue: finalHue, saturation: saturation, brightness: brightness)
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
  
   // Helper method to adjust a color with hue shift and saturation scaling
   private func adjustColor(_ color: Color, hueShift: Double, saturationScale: Double) -> Color {
       let uiColor = UIColor(color)
       var hue: CGFloat = 0
       var saturation: CGFloat = 0
       var brightness: CGFloat = 0
       var alpha: CGFloat = 0
       
       if uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
           // Adjust hue (shift by -0.5 to 0.5) only if useDefaultRainbowColors is true
           let newHue = useDefaultRainbowColors ? 
               (hue + CGFloat(hueShift)).truncatingRemainder(dividingBy: 1.0) : hue
           
           // Adjust saturation (scale by 0-1) always
           let newSaturation = min(1.0, max(0.0, saturation * CGFloat(saturationScale)))
           
           return Color(hue: Double(newHue), saturation: Double(newSaturation), brightness: Double(brightness), opacity: Double(alpha))
       }
       
       // Return original color if conversion fails
       return color
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
  
   /// Initializes the color selection panel with a binding to the selected color
   /// - Parameter selectedColor: Binding to the color that will be applied to shapes
   init(selectedColor: Binding<Color>) {
       self._selectedColor = selectedColor
       self._hexValue = State(initialValue: selectedColor.wrappedValue.toHex() ?? "#000000")
   }
  
   var body: some View {
       ScrollView {
           VStack(alignment: .leading, spacing: 12) {
               // Slider for number of presets that matches property row slider style
               VStack(alignment: .leading) {
                   HStack {
                       Image(systemName: "circle.grid.2x2")
                           .foregroundColor(.blue)
                           .font(.system(size: 18))
                       Text("Preset Count")
                           .font(.headline)
                   }
                   
                   HStack(spacing: 12) {
                       Slider(
                           value: Binding<Double>(
                               get: { Double(presetManager.numberOfVisiblePresets) },
                               set: { newValue in
                                   // Immediately update the number of visible presets
                                   let newCount = max(1, min(10, Int(newValue)))
                                   if presetManager.numberOfVisiblePresets != newCount {
                                       presetManager.numberOfVisiblePresets = newCount
                                      
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
                      
                       TextField("", text: Binding<String>(
                           get: { "\(presetManager.numberOfVisiblePresets)" },
                           set: { newValue in
                               if let value = Int(newValue), value >= 1, value <= 10 {
                                   presetManager.numberOfVisiblePresets = value
                                   // Notify about the change
                                   NotificationCenter.default.post(
                                       name: Notification.Name("ColorPresetsChanged"),
                                       object: nil
                                   )
                               }
                           }
                       ))
                       .frame(width: 40)
                       .textFieldStyle(RoundedBorderTextFieldStyle())
                       .keyboardType(.numberPad)
                       .multilineTextAlignment(.center)
                   }
               }
               .padding()
               .background(Color(uiColor: .systemGray6))
               .cornerRadius(8)
               .padding(.horizontal, 16)
               .padding(.bottom, 12)
              
               // Preset color slots - clean design without border
               VStack(alignment: .leading) {
                   HStack {
                       Image(systemName: "paintbrush.pointed")
                           .foregroundColor(.blue)
                           .font(.system(size: 18))
                       Text("Color Presets")
                           .font(.headline)
                   }
                   
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
               .padding()
               .background(Color(uiColor: .systemGray6))
               .cornerRadius(8)
               .padding(.horizontal, 16)
               .padding(.bottom, 12)
              
               // Color picker section with consistent styling
               VStack(alignment: .leading) {
                   HStack {
                       Image(systemName: "eyedropper")
                           .foregroundColor(.blue)
                           .font(.system(size: 18))
                       Text("Edit Color")
                           .font(.headline)
                   }
                   
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
               .padding()
               .background(Color(uiColor: .systemGray6))
               .cornerRadius(8)
               .padding(.horizontal, 16)
           }
           .padding(8)
           .background(Color(.systemBackground))
           .cornerRadius(12)
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
