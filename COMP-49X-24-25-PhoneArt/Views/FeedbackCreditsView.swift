//
//  FeedbackCreditsView.swift
//  COMP-49X-24-25-PhoneArt
//
//  Created by Zachary Letcher on 2025-05-14.
//

import SwiftUI
// Removed UIKit import as it's causing issues and we'll use SwiftUI equivalents

@MainActor class FeedbackCreditsViewModel: ObservableObject {
    // Properties for managing feedback text, etc.
    @Published var feedbackText: String = ""
    @Published var showingCredits: Bool = false // To toggle between feedback and credits

    var onSendFeedback: ((String) -> Void)?
    var onCancel: (() -> Void)?

    init() {
        // Initialization
    }

    func sendFeedback() {
        // Logic to send feedback
        // For now, just print and call the closure
        print("Feedback to send: \(feedbackText)")
        onSendFeedback?(feedbackText)
    }

    func cancel() {
        onCancel?()
    }
}

struct FeedbackCreditsView: View {
    @ObservedObject var viewModel: FeedbackCreditsViewModel
    @State private var selectedSection: Section = .feedback // Default to feedback
    @Environment(\.openURL) var openURL // Re-add the openURL environment value

    enum Section {
        case feedback
        case credits
    }

    // Updated list from user, now named 'developers'
    let developers = [
        "Zachary Letcher",
        "Aditya Prakash",
        "Noah Huang",
        "Emmett DeBruin",
    ]

    // New list for other contributors
    let additionalContributors = [
        "Paul Phillips",
        "Odesma Dalrymple",
        "Perla Myers",
        "Jacob's Institute of Technology",
        "STEAM Academy",
    ]

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "info.circle.fill") // Using an info icon
                .font(.system(size: 50))
                .foregroundColor(.blue)
                .padding(.top, 25)

            Text("Feedback & Credits")
                .font(.headline)
                .multilineTextAlignment(.center)

            Picker("Section", selection: $selectedSection) {
                Text("Feedback").tag(Section.feedback)
                Text("Credits").tag(Section.credits)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 30)

            if selectedSection == .feedback {
                feedbackSection
            } else {
                creditsSection
            }
        }
        .frame(width: 350)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
        .overlay(
            Button(action: {
                viewModel.cancel()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color.gray.opacity(0.7))
            }
            .padding(16),
            alignment: .topTrailing
        )
        .padding(30)
    }

    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Rate Our App!")
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 5)

            Text("If you enjoy using MathArt Playground, please take a moment to rate it on the App Store. Your support helps us a lot!")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)

            Button {
                if let url = URL(string: "https://apps.apple.com/us/app/mathart-playground/id6745572126") {
                    openURL(url)
                }
            } label: {
                HStack {
                    Image(systemName: "star.fill")
                    Text("Rate on App Store")
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 25)
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            Spacer() // Add spacer to push content to the top if the frame is tall
        }
        .padding(.horizontal, 30)
        .frame(minHeight: 200) // Adjust minHeight as needed
    }

    private var creditsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) { // Outer VStack for sections
                    Text("Contributors:")
                        .font(.title3.bold())
                        .padding(.bottom, 2)

                    ForEach(additionalContributors, id: \.self) { name in
                        Text(name)
                            .font(.body)
                    }
                    .padding(.bottom, 10) // Add some space after the contributors list

                    Text("Developers:")
                        .font(.title3.bold())
                        .padding(.bottom, 2)

                    ForEach(developers, id: \.self) { name in
                        Text(name)
                            .font(.body)
                    }
                }
            }
        }
        .padding(.horizontal, 30)
        .frame(height: 400) // Increased height for credits section to fit all names
    }
}

struct FeedbackCreditsView_Previews: PreviewProvider {
    static var previews: some View {
        FeedbackCreditsView(viewModel: FeedbackCreditsViewModel())
    }
} 