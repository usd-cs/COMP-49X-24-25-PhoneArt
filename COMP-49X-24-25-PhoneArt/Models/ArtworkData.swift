import Foundation
import SwiftUI


/// A model representing artwork data that can be encoded/decoded for storage and transmission
/// Contains the artwork string representation, device ID, timestamp and optional title
struct ArtworkData: Codable, Identifiable, Equatable {
  var id: String { pieceId ?? artworkString }

  let deviceId: String
  let artworkString: String
  let timestamp: Date
  let title: String?
  var pieceId: String? // Firestore document ID (optional, as it doesn't exist until saved)

  enum CodingKeys: String, CodingKey {
      case deviceId
      case artworkString
      case timestamp
      case title
      case pieceId // Ensure this matches the field name added in FirebaseService.saveArtwork
  }

  /// Constants defining valid ranges for different artwork parameters
  private struct ValidationRanges {
      static let rotation = 0.0...360.0    // Rotation angle in degrees
      static let scale = 0.5...2.0         // Scale factor
      static let layer = 0.0...72.0       // Layer ordering
      static let skew = 0.0...100.0        // Skew percentage
      static let spread = 0.0...100.0      // Element spread percentage
      static let horizontal = -300.0...300.0 // Horizontal position
      static let vertical = -300.0...300.0   // Vertical position 
      static let primitive = 1.0...6.0     // Primitive shape type
  }
   /// Validates and clamps a numeric value to ensure it falls within an acceptable range
  /// - Parameters:
  ///   - value: The value to validate
  ///   - range: The acceptable range for the value
  /// - Returns: The validated and clamped value
  private static func validate(_ value: Double, in range: ClosedRange<Double>) -> Double {
      return min(max(value, range.lowerBound), range.upperBound)
  }
   /// Converts a SwiftUI Color to its hexadecimal string representation
  /// - Parameter color: The Color to convert
  /// - Returns: A hex color string in the format "#RRGGBB"
  private static func colorToHex(_ color: Color) -> String {
      let uiColor = UIColor(color)
      var red: CGFloat = 0
      var green: CGFloat = 0
      var blue: CGFloat = 0
      var alpha: CGFloat = 0
    
      uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    
      let rgb = Int(red * 255) << 16 | Int(green * 255) << 8 | Int(blue * 255) << 0
      return String(format: "#%06X", rgb)
  }
   /// Converts a hexadecimal color string to a SwiftUI Color
  /// - Parameter hex: The hex color string to convert
  /// - Returns: A SwiftUI Color if conversion succeeds, nil otherwise
  static func hexToColor(_ hex: String) -> Color? {
      var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
      hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
    
      var rgb: UInt64 = 0
      guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
    
      let red = Double((rgb & 0xFF0000) >> 16) / 255.0
      let green = Double((rgb & 0x00FF00) >> 8) / 255.0
      let blue = Double(rgb & 0x0000FF) / 255.0
    
      return Color(.sRGB, red: red, green: green, blue: blue, opacity: 1)
  }
   /// Creates a string representation of artwork with all its parameters
  /// - Parameters:
  ///   - shapeType: The type of shape to create
  ///   - rotation: Rotation angle in degrees
  ///   - scale: Scale factor for the shape
  ///   - layer: Layer ordering value
  ///   - skewX: Horizontal skew percentage
  ///   - skewY: Vertical skew percentage
  ///   - spread: Element spread percentage
  ///   - horizontal: Horizontal position
  ///   - vertical: Vertical position
  ///   - primitive: Primitive shape type value
  ///   - colorPresets: Array of colors used in the artwork
  ///   - backgroundColor: Background color of the artwork
  ///   - useDefaultRainbowColors: Flag indicating whether to use default rainbow colors
  ///   - rainbowStyle: Rainbow style
  ///   - hueAdjustment: Hue adjustment
  ///   - saturationAdjustment: Saturation adjustment
  ///   - numberOfVisiblePresets: Number of visible presets
  ///   - strokeColor: Stroke color of the artwork
  ///   - strokeWidth: Stroke width of the artwork
  ///   - shapeAlpha: Alpha value of the artwork
  /// - Returns: A semicolon-separated string containing all validated artwork parameters
  static func createArtworkString(
      shapeType: ShapesPanel.ShapeType,
      rotation: Double,
      scale: Double,
      layer: Double,
      skewX: Double,
      skewY: Double,
      spread: Double,
      horizontal: Double,
      vertical: Double,
      primitive: Double,
      colorPresets: [Color],
      backgroundColor: Color,
      useDefaultRainbowColors: Bool,
      rainbowStyle: Int,
      hueAdjustment: Double,
      saturationAdjustment: Double,
      numberOfVisiblePresets: Int,
      strokeColor: Color,
      strokeWidth: Double,
      shapeAlpha: Double
  ) -> String {
      // Validate all numeric inputs
      let validatedData = [
          "shape": shapeType.rawValue,
          "rotation": String(validate(rotation, in: ValidationRanges.rotation)),
          "scale": String(validate(scale, in: ValidationRanges.scale)),
          "layer": String(validate(layer, in: ValidationRanges.layer)),
          "skewX": String(validate(skewX, in: ValidationRanges.skew)),
          "skewY": String(validate(skewY, in: ValidationRanges.skew)),
          "spread": String(validate(spread, in: ValidationRanges.spread)),
          "horizontal": String(validate(horizontal, in: ValidationRanges.horizontal)),
          "vertical": String(validate(vertical, in: ValidationRanges.vertical)),
          "primitive": String(validate(primitive, in: ValidationRanges.primitive)),
          "colors": colorPresets.map { colorToHex($0) }.joined(separator: ","),
          "background": colorToHex(backgroundColor),
          "useRainbow": String(useDefaultRainbowColors),
          "rainbowStyle": String(rainbowStyle),
          "hueAdj": String(hueAdjustment),
          "satAdj": String(saturationAdjustment),
          "presetCount": String(numberOfVisiblePresets),
          "strokeColor": colorToHex(strokeColor),
          "strokeWidth": String(strokeWidth),
          "alpha": String(shapeAlpha)
      ]
    
      return validatedData.map { "\($0.key):\($0.value)" }.joined(separator: ";")
  }
   /// Decodes an artwork string back into a dictionary of parameters with validation
  /// - Parameter string: The artwork string to decode
  /// - Returns: A dictionary containing the decoded and validated artwork parameters
  static func decode(from string: String) -> [String: String] {
      let pairs = string.components(separatedBy: ";")
      var result: [String: String] = [:]
    
      for pair in pairs {
          let keyValue = pair.components(separatedBy: ":")
          if keyValue.count == 2 {
              let key = keyValue[0]
              var value = keyValue[1]
            
              // Validate numeric values if applicable
              if let doubleValue = Double(value) {
                  value = String(
                      validate(doubleValue, in: {
                          switch key {
                          case "rotation": return ValidationRanges.rotation
                          case "scale": return ValidationRanges.scale
                          case "layer": return ValidationRanges.layer
                          case "skewX", "skewY": return ValidationRanges.skew
                          case "spread": return ValidationRanges.spread
                          case "horizontal": return ValidationRanges.horizontal
                          case "vertical": return ValidationRanges.vertical
                          case "primitive": return ValidationRanges.primitive
                          default: return 0.0...Double.infinity
                          }
                      }())
                  )
              }
            
              result[key] = value
          }
      }
    
      return result
  }
   /// Reconstructs an array of Colors from a comma-separated hex color string
  /// - Parameter hexString: The comma-separated string of hex color values
  /// - Returns: An array of SwiftUI Colors
  static func reconstructColors(from hexString: String) -> [Color] {
      return hexString.components(separatedBy: ",")
          .compactMap { hexToColor($0) }
  }
}




