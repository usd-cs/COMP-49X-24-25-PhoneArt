//
//  ContentView.swift
//  COMP-49X-24-25-PhoneArt
//
//  Created by Aditya Prakash on 11/21/24.
//

import SwiftUI

/// The root view of the application that serves as the main container.
/// This view embeds the CanvasView which provides the core drawing functionality.
/// The CanvasView is automatically centered and fills the available space.
struct ContentView: View {
    var firebaseService : FirebaseService
    
    var body: some View {
        CanvasView(firebaseService: firebaseService)
    }
}

/// Preview provider for ContentView
#Preview {
    ContentView(firebaseService: FirebaseService())
}
