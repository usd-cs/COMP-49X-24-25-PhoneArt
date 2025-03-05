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
        // Ensure we only use the number of visible presets
        let visibleColors = Array(colorPresets.prefix(min(numberOfVisiblePresets, colorPresets.count)))
        
        // If there are no colors visible, return a default color
        guard !visibleColors.isEmpty else { return .black }
        
        // Use modulo to cycle through the visible colors based on position
        let colorIndex = position % visibleColors.count
        
        // Log the color selection for debugging
        print("Position \(position) using color \(colorIndex) of \(visibleColors.count) visible colors")
        
        return visibleColors[colorIndex]
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
                // Header with icon and label
                HStack(spacing: 10) {
                    Image(systemName: "paintpalette")
                        .font(.title3)
                    
                    Text("Preset Colors")
                        .foregroundColor(Color(uiColor: .label))
                        .font(.body)
                }
                .padding(.bottom, 10)
                
                // Slider for number of presets that matches rotation slider style
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
                .padding(.vertical, 10)
                
                // Preset color slots - clean design without border
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
                .padding(.bottom, 8)
                
                // Color picker section with consistent styling
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
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .padding(16)
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