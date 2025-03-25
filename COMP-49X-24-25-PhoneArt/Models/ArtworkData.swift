import Foundation
import SwiftUI


struct ArtworkData: Codable {
   let deviceId: String
   let artworkString: String
   let timestamp: Date
   let title: String?
  
   // Validation ranges for artwork parameters
   private struct ValidationRanges {
       static let rotation = 0.0...360.0
       static let scale = 0.5...2.0
       static let layer = 0.0...360.0
       static let skew = 0.0...100.0
       static let spread = 0.0...100.0
       static let horizontal = -300.0...300.0
       static let vertical = -300.0...300.0
       static let primitive = 1.0...6.0
   }
  
   // Validate and clamp values to acceptable ranges
   private static func validate(_ value: Double, in range: ClosedRange<Double>) -> Double {
       return min(max(value, range.lowerBound), range.upperBound)
   }
  
   // Enhanced Color extensions for reliable hex conversion
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
  
   private static func hexToColor(_ hex: String) -> Color? {
       var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
       hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
      
       var rgb: UInt64 = 0
       guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
      
       let red = Double((rgb & 0xFF0000) >> 16) / 255.0
       let green = Double((rgb & 0x00FF00) >> 8) / 255.0
       let blue = Double(rgb & 0x0000FF) / 255.0
      
       return Color(.sRGB, red: red, green: green, blue: blue, opacity: 1)
   }
  
   // This will compress all the canvas data into a string with validation
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
       backgroundColor: Color
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
           "background": colorToHex(backgroundColor)
       ]
      
       return validatedData.map { "\($0.key):\($0.value)" }.joined(separator: ";")
   }
  
   // Decode string back into artwork data with validation
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
  
   // Helper method to reconstruct Color array from hex string
   static func reconstructColors(from hexString: String) -> [Color] {
       return hexString.components(separatedBy: ",")
           .compactMap { hexToColor($0) }
   }
}

