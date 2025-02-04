//
//  ContentView.swift
//  COMP-49X-24-25-PhoneArt
//
//  Created by Aditya Prakash on 11/21/24.
//edit
//

import SwiftUI

/// The root view of the application that serves as the main container.
/// This view embeds the CanvasView which provides the core drawing functionality.
/// The CanvasView is automatically centered and fills the available space.
struct ContentView: View {
    var body: some View {
        CanvasView()
    }
}

/// Preview provider for ContentView
#Preview {
    ContentView()
}
