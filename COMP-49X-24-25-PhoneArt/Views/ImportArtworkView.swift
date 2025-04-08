//
//  ImportArtworkView.swift
//  COMP-49X-24-25-PhoneArt
//
//  Created by Zachary Letcher on 04/06/25.
//

import SwiftUI
import UIKit // Added UIKit for UIPasteboard

/// A view that allows users to enter an artwork ID to import saved artwork
struct ImportArtworkView: View {
    @State private var artworkIdText = ""
    @State private var isProcessing = false
    @State private var importResult: ImportResult?
    @Environment(\.dismiss) private var dismiss
    
    // Callback to pass successful import data back
    var onImportSuccess: ((String) -> Void)?
    // Add callback for closing the sheet
    var onClose: (() -> Void)?
    
    // State for showing alerts
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // Simple model for import results
    enum ImportResult: Equatable {
        case success(message: String)
        case failure(message: String)
    }
    
    var body: some View {
        VStack(spacing: 15) {
            // Top Icon
            Image(systemName: "arrow.down.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.blue)
                .padding(.top, 30)

            // Header Text
            Text("Import Artwork")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 5)

            Text("Enter the artwork ID to import")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.bottom, 10)

            // Input field with Paste button
            VStack(alignment: .leading, spacing: 5) {
                Text("Artwork ID")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading)

                HStack {
                    TextField("Paste or enter artwork ID", text: $artworkIdText)
                        .padding(.leading)
                        .disableAutocorrection(true)
                        .accessibilityIdentifier("Artwork ID TextField")

                    Button {
                        // Paste action
                        if let pastedString = UIPasteboard.general.string {
                            artworkIdText = pastedString
                        }
                    } label: {
                        Image(systemName: "doc.on.clipboard")
                            .foregroundColor(.blue)
                    }
                    .padding(.trailing)
                    .accessibilityIdentifier("Paste Button")
                }
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
            .padding(.horizontal, 20)

            Spacer()

            // Import button (Primary Action)
            Button(action: {
                importArtwork()
            }) {
                HStack {
                    Spacer()
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Import")
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 30)
            .background(Color(uiColor: .systemBlue))
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(artworkIdText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
            .fixedSize(horizontal: true, vertical: false)
            .accessibilityIdentifier("Import Button")

            // Close button (using new onClose callback)
            Button("Close") {
                onClose?() // Call the new callback
            }
            .foregroundColor(.blue)
            .padding(.top, 5)
            .padding(.bottom, 20)
            .accessibilityIdentifier("Close Import Button")

        }
        .frame(width: 350, height: 400)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
        .padding()
        .onChange(of: importResult) { _, newResult in
            if case .success = newResult {
                print("Import Success (handle UI)")
            } else if case .failure(let message) = newResult {
                print("Import Failed: \(message) (handle UI)")
                // Update alert state and show it
                self.alertMessage = message
                self.showingAlert = true
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Import Failed"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private func importArtwork() {
        // Reset previous results
        importResult = nil
        isProcessing = true
        showingAlert = false // Reset alert state
        alertMessage = ""
        
        let id = artworkIdText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Ensure ID is not empty before proceeding
        guard !id.isEmpty else {
            self.importResult = .failure(message: "Please enter a valid artwork ID.")
            self.isProcessing = false
            return
        }
        
        print("Starting import task for ID: \(id)")
        
        Task { // Use Task for async operation
            do {
                // Call the Firebase service to fetch artwork by ID
                let fetchedArtworkData = try await FirebaseService.shared.getArtwork(byPieceId: id)
                
                // Ensure data was found
                guard let artworkData = fetchedArtworkData else {
                    // Handle case where artwork ID was not found in Firestore
                    await MainActor.run { // Update state on main thread
                        self.importResult = .failure(message: "Artwork ID not found. Please check the ID and try again.")
                        self.isProcessing = false
                    }
                    return
                }
                
                // Artwork found, call the success callback
                print("Artwork found and decoded. Calling onImportSuccess.")
                await MainActor.run { // Update state on main thread
                    onImportSuccess?(artworkData.artworkString) // Pass the raw string data
                    self.importResult = .success(message: "Import successful - data passed back.") // Set success state
                    // Dismissal is now handled by the parent view (CanvasView) via the callback
                    // dismiss() // Remove direct dismissal from here
                    self.isProcessing = false
                }
                
            } catch let decodingError as DecodingError {
                // Handle errors during decoding (e.g., data format mismatch)
                print("Decoding error during import: \(decodingError)")
                await MainActor.run { // Update state on main thread
                    self.importResult = .failure(message: "Failed to process artwork data. It might be corrupted or in an old format. Error: \(decodingError.localizedDescription)")
                    self.isProcessing = false
                }
            } catch {
                // Handle other errors (network, Firestore unavailable, etc.)
                print("Error during import: \(error)")
                await MainActor.run { // Update state on main thread
                    self.importResult = .failure(message: "An error occurred during import: \(error.localizedDescription)")
                    self.isProcessing = false
                }
            }
        }
        
        // Removed the DispatchQueue.main.asyncAfter simulation block
    }
}

// Helper extension to get icon and color for result type
extension ImportArtworkView.ImportResult {
    var icon: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .failure:
            return "exclamationmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success:
            return .green
        case .failure:
            return .red
        }
    }
    
    var message: String {
        switch self {
        case .success(let message):
            return message
        case .failure(let message):
            return message
        }
    }
}

#Preview {
    // Update preview to provide a dummy onClose action
    ImportArtworkView(onClose: { print("Preview Close Tapped") })
} 
