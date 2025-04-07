//
//  ImportArtworkView.swift
//  COMP-49X-24-25-PhoneArt
//
//  Created by Assistant on 4/30/25.
//

import SwiftUI
import UIKit // Added UIKit for UIPasteboard

/// A view that allows users to enter an artwork ID to import saved artwork
struct ImportArtworkView: View {
    @State private var artworkIdText = ""
    @State private var isProcessing = false
    @State private var importResult: ImportResult?
    @Environment(\.dismiss) private var dismiss
    
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

            // Close button (using dismiss)
            Button("Close") {
                dismiss()
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
            }
        }
    }
    
    private func importArtwork() {
        // Reset previous results
        importResult = nil
        isProcessing = true
        
        // Get the trimmed artwork ID
        let id = artworkIdText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Simulate processing
        // In a real implementation, this would call the Firebase service to retrieve the artwork
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Placeholder for actual implementation
            if !id.isEmpty {
                // Simulate success for now
                print("Simulating successful import for ID: \(id)")
                // In a real scenario, you'd fetch data here
                // Let's assume fetch is successful:
                self.importResult = .success(message: "Artwork imported successfully!")
                // Consider dismissing the view on success:
                // dismiss()
            } else {
                self.importResult = .failure(message: "Please enter a valid artwork ID")
            }
            self.isProcessing = false
        }
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
    ImportArtworkView()
} 