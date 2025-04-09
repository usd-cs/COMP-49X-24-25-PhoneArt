import SwiftUI
import UIKit

/// A view that shows confirmation of a saved artwork with the ability to copy the ID
struct SaveConfirmationView: View {
    let artworkId: String
    @State private var isCopied = false
    let dismissAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
                .padding(.top, 30)
            
            Text("Artwork Saved Successfully!")
                .font(.headline)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("Save Confirmation Text")
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Artwork ID:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(artworkId)
                        .font(.system(.body, design: .monospaced))
                        .padding(10)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(8)
                        .accessibilityIdentifier("Saved Artwork ID Text")
                    
                    Button(action: {
                        UIPasteboard.general.string = artworkId
                        withAnimation {
                            isCopied = true
                        }
                        
                        // Reset the copied state after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            isCopied = false
                        }
                    }) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                            .foregroundColor(isCopied ? .green : Color(uiColor: .systemBlue))
                            .padding(8)
                            .background(Color(uiColor: .tertiarySystemBackground))
                            .cornerRadius(8)
                    }
                    .accessibilityIdentifier("Copy ID Button")
                }
            }
            .padding(.horizontal, 20)
            
            Text("Share this ID with friends so they can view your artwork!")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Button("Done") {
                dismissAction()
            }
            .accessibilityIdentifier("Save Confirmation Done Button")
            .padding(.vertical, 12)
            .padding(.horizontal, 30)
            .background(Color(uiColor: .systemBlue))
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.top, 20)
            .padding(.bottom, 30)
        }
        .accessibilityIdentifier("Save Confirmation View")
        .frame(width: 350)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
        .padding()
    }
}

#Preview {
    SaveConfirmationView(artworkId: "preview-artwork-id-123", dismissAction: { print("Dismissed") })
} 