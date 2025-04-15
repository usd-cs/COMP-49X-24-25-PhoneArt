//
//  SharedViews.swift
//  COMP-49X-24-25-PhoneArt
//
//  Created by Zachary Letcher on 04/15/25.
//

import SwiftUI

/// A tooltip view that displays information text with consistent styling
/// This is shared across multiple panel components for visual consistency
struct SharedTooltipView: View {
    /// The text to display in the tooltip
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline)
            .fontWeight(.medium)
            .fixedSize(horizontal: false, vertical: true)
            .padding(12)
            .foregroundColor(Color.white)
    }
}

// Add other shared components here in the future
