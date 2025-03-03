import SwiftUI

struct ColorSelectionPanel: View {
    @State private var selectedPresetIndex: Int = 0
    @State private var colorPresets: [Color] = [
        .purple, .yellow, .pink, .blue, .green
    ]
    @Binding var selectedColor: Color
    @State private var hexValue: String = "#000000"
    
    init(selectedColor: Binding<Color>) {
        self._selectedColor = selectedColor
        self._hexValue = State(initialValue: selectedColor.wrappedValue.toHex() ?? "#000000")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preset:")
                .foregroundColor(.secondary)
            
            // Preset color slots
            HStack(spacing: 8) {
                ForEach(0..<5) { index in
                    ColorPresetButton(
                        color: colorPresets[index],
                        isSelected: selectedPresetIndex == index
                    ) {
                        selectedPresetIndex = index
                        selectedColor = colorPresets[index]
                        hexValue = selectedColor.toHex() ?? "#000000"
                    }
                }
            }
            
            // Color picker section
            VStack(spacing: 8) {
                ColorPicker("", selection: Binding(
                    get: { selectedColor },
                    set: { newColor in
                        selectedColor = newColor
                        colorPresets[selectedPresetIndex] = newColor
                        hexValue = newColor.toHex() ?? "#000000"
                    }
                ))
                .labelsHidden()
                
                // Hex input field
                HStack {
                    TextField("Hex", text: $hexValue)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: hexValue) { oldValue, newValue in
                            if let color = Color(hex: newValue) {
                                selectedColor = color
                                colorPresets[selectedPresetIndex] = color
                            }
                        }
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// Helper view for preset color buttons
struct ColorPresetButton: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 30, height: 30)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
                )
                .shadow(color: isSelected ? .black.opacity(0.3) : .clear, radius: 2)
        }
    }
}

// Color extensions for hex conversion
extension Color {
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