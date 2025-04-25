//
//  ImportArtworkView.swift
//  COMP-49X-24-25-PhoneArt
//
//  Created by Zachary Letcher on 04/06/25.
//


import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseCore


@MainActor class ImportArtworkViewModel: ObservableObject {
   @Published var artworkIdText: String = ""
   @Published var showError: Bool = false
   @Published var errorMessage: String = ""
   @Published var isLoading: Bool = false // Added for loading state
  
   var onImportSuccess: ((String) -> Void)? // Closure to pass artwork string on success
   var onCancel: (() -> Void)?
   var onError: ((String) -> Void)?
  
   private let firebaseService: FirebaseService
  
   // Allow dependency injection for testing
   init(firebaseService: FirebaseService = FirebaseService.shared) {
       self.firebaseService = firebaseService
       print("ImportArtworkViewModel initialized with service: \(type(of: firebaseService))")
   }
  
   func importArtwork() {
       let trimmedId = artworkIdText.trimmingCharacters(in: .whitespacesAndNewlines)
       guard !trimmedId.isEmpty else {
           handleError("Artwork ID cannot be empty.")
           return
       }
      
       isLoading = true
       errorMessage = "" // Clear previous errors
       showError = false
      
       Task {
           defer { isLoading = false } // Ensure loading stops
           do {
               print("ViewModel: Calling firebaseService.getArtworkPiece with ID: \(trimmedId)")
               if let artworkData = try await firebaseService.getArtworkPiece(pieceId: trimmedId) {
                   // Safely handle the optional artworkString
                   let artworkString = artworkData.artworkString ?? ""
                   if !artworkString.isEmpty {
                       print("ViewModel: Artwork found, calling onImportSuccess.")
                       // Use Task to ensure UI updates happen on main thread if needed
                       await MainActor.run {
                           onImportSuccess?(artworkString)
                       }
                   } else {
                       handleError("Imported artwork data is missing the artwork string.")
                   }
               } else {
                   handleError("Artwork with ID '\(trimmedId)' not found.")
               }
           } catch {
               handleError("Error fetching artwork: \(error.localizedDescription)")
           }
       }
   }
  
   func cancelImport() {
       print("ViewModel: cancelImport called, triggering onCancel.")
       onCancel?()
   }
  
   private func handleError(_ message: String) {
       print("ViewModel: Handling error: \(message)")
       Task { @MainActor in // Ensure UI updates are on main thread
           self.errorMessage = message
           self.showError = true
           self.onError?(message) // Call error callback
       }
   }
}
/* // End of actual ViewModel definition
*/

struct ImportArtworkView: View {
   @ObservedObject var viewModel: ImportArtworkViewModel
   @FocusState private var isIdFieldFocused: Bool
  
   var body: some View {
       VStack(spacing: 20) {
           Text("Import Artwork")
               .font(.headline)
               .padding(.top)
          
           Text("Enter the artwork ID to import:")
               .font(.subheadline)
               .foregroundColor(.secondary)
          
           TextField("Artwork ID", text: $viewModel.artworkIdText)
               .textFieldStyle(RoundedBorderTextFieldStyle())
               .padding(.horizontal)
               .focused($isIdFieldFocused)
               .onAppear {
                   // Focus the text field when view appears
                   DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                       isIdFieldFocused = true
                   }
               }
          
           if viewModel.showError {
               Text(viewModel.errorMessage)
                   .foregroundColor(.red)
                   .font(.caption)
                   .padding(.horizontal)
                   .transition(.opacity)
           }
          
           HStack(spacing: 20) {
               Button("Cancel") {
                   viewModel.cancelImport()
               }
               .buttonStyle(.bordered)
              
               Button("Import") {
                   viewModel.importArtwork()
               }
               .buttonStyle(.borderedProminent)
               .disabled(viewModel.artworkIdText.isEmpty || viewModel.isLoading)
           }
           .padding(.bottom)
          
           if viewModel.isLoading {
               ProgressView()
                   .padding()
           }
       }
       .frame(width: 350, height: 250)
       .background(Color(.systemBackground))
       .cornerRadius(12)
       .shadow(radius: 10)
   }
}
