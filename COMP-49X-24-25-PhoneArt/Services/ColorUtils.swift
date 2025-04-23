// ColorUtils.swift

import SwiftUI
import UIKit

/// Provides utility functions for generating and adjusting colors consistently.
struct ColorUtils {

    /// Adjusts a color with hue shift and saturation scaling.
    /// IMPORTANT: Hue shift is applied *only* if useDefaultRainbowColors is true.
    /// Saturation scaling is applied *always*.
    /// - Parameters:
    ///   - color: The base color to adjust.
    ///   - hueShift: The amount to shift the hue (-0.5 to 0.5). Applied only if useDefaultRainbowColors is true.
    ///   - saturationScale: The factor to scale saturation (0.0 to 1.0+).
    ///   - useDefaultRainbowColors: Flag indicating if hue shift should be applied.
    /// - Returns: The adjusted color.
    static func adjustColor(_ color: Color, hueShift: Double, saturationScale: Double, useDefaultRainbowColors: Bool) -> Color {
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

            // Always return a fully opaque color from adjustColor.
            // Final opacity is handled later in the drawing code based on shapeAlpha.
            return Color(hue: Double(newHue), saturation: Double(newSaturation), brightness: Double(brightness), opacity: 1.0)
        }

        // Return original color if conversion fails
        return color
    }

    /// Generate a rainbow color based on position (standard dynamic style)
    static func rainbowColor(for position: Int, hueAdjustment: Double, saturationAdjustment: Double) -> Color {
        let scaledPosition = (position * 30) % 360
        let angle = Double(position) * 0.1
        let baseHue = (Double(scaledPosition) / 360.0)
        let hueShift = 0.15 * sin(angle * 0.5)
        let hueOffset = hueAdjustment - 0.5
        let finalHue = (baseHue + hueShift + hueOffset).truncatingRemainder(dividingBy: 1.0)

        // Calculate base saturation and variation *without* adjustment first
        let saturationBase = 0.9
        let saturationVariation = 0.1 * sin(angle * 0.7)
        let calculatedSaturation = min(1.0, max(0.3, saturationBase + saturationVariation))
        // Apply saturationAdjustment as a final scale
        let finalSaturation = min(1.0, max(0.0, calculatedSaturation * saturationAdjustment))

        let brightnessBase = 0.95
        let brightnessVariation = 0.1 * cos(angle * 0.3)
        let brightness = min(1.0, max(0.8, brightnessBase + brightnessVariation))
        return Color(hue: finalHue, saturation: finalSaturation, brightness: brightness)
    }

    /// Generate a cyberpunk-inspired rainbow color based on position
    static func cyberpunkRainbowColor(for position: Int, hueAdjustment: Double, saturationAdjustment: Double) -> Color {
        let scaledPosition = (position * 24) % 360
        let normalizedPosition = Double(position) * 0.05
        let baseHue = (Double(scaledPosition) / 360.0)
        let hueShift1 = 0.2 * sin(normalizedPosition * 1.1)
        let hueShift2 = 0.15 * sin(normalizedPosition * 0.7 + 2.0)
        let hueOffset = hueAdjustment - 0.5
        let finalHue = (baseHue + hueShift1 + hueShift2 + hueOffset).truncatingRemainder(dividingBy: 1.0)

        // Calculate base saturation and variation *without* adjustment first
        let satPhase = sin(normalizedPosition * 0.5)
        let calculatedSaturation = min(1.0, (0.85 + (0.15 * satPhase)))
        // Apply saturationAdjustment as a final scale
        let finalSaturation = min(1.0, max(0.0, calculatedSaturation * saturationAdjustment))

        let brightPhase = 0.5 * sin(normalizedPosition * 1.7) + 0.5 * cos(normalizedPosition * 2.3)
        let brightness = min(1.0, 0.85 + 0.15 * brightPhase)
        return Color(hue: finalHue, saturation: finalSaturation, brightness: brightness)
    }

    /// Generate a half-spectrum rainbow color based on position
    static func halfSpectrumRainbowColor(for position: Int, hueAdjustment: Double, saturationAdjustment: Double) -> Color {
        let scaledPosition = (position * 18) % 180
        let startHue = 0.75
        let hueRange = 0.5
        let angle = Double(position) * 0.05
        let positionInRange = Double(scaledPosition) / 180.0
        let hueOffset = hueAdjustment - 0.5
        let baseHue = startHue + (positionInRange * hueRange) + hueOffset
        let wrappedHue = baseHue.truncatingRemainder(dividingBy: 1.0)
        let hueShift = 0.08 * sin(angle * 0.7)
        let finalHue = (wrappedHue + hueShift).truncatingRemainder(dividingBy: 1.0)

        // Calculate base saturation and variation *without* adjustment first
        let saturationBase = 0.95
        let saturationVariation = 0.05 * sin(angle * 0.9)
        let calculatedSaturation = min(1.0, max(0.3, saturationBase + saturationVariation))
        // Apply saturationAdjustment as a final scale
        let finalSaturation = min(1.0, max(0.0, calculatedSaturation * saturationAdjustment))

        let brightnessBase = 0.95
        let brightnessVariation = 0.05 * cos(angle * 0.5)
        let brightness = min(1.0, max(0.9, brightnessBase + brightnessVariation))
        return Color(hue: finalHue, saturation: finalSaturation, brightness: brightness)
    }
} 