//
//  UnsavedChangesHandler.swift
//  COMP-49X-24-25-PhoneArt
//
//  Created by Aditya Prakash on 12/15/24.
//

import SwiftUI

/// A utility struct to handle unsaved changes warnings and prompts
struct UnsavedChangesHandler {
    // MARK: - UserDefaults Keys
    private static let unsavedArtworkStringKey = "UnsavedChangesArtworkString"
    private static let unsavedArtworkTimestampKey = "UnsavedArtworkTimestamp"
    private static let hasUnsavedWorkKey = "UnsavedChangesHasUnsavedWork"
    private static let showSaveOptionKey = "UnsavedChangesShowSaveOption"
    
    /// Enum representing possible actions that might discard unsaved changes
    enum PotentialDataLossAction: String {
        case newArtwork
        case importArtwork
        case shareArtwork
        case shareModifiedArtwork
        case restorePreviousWork
        
        var alertTitle: String {
            switch self {
            case .newArtwork:
                return "Create New Artwork - Unsaved Changes"
            case .importArtwork:
                return "Import Artwork Code - Unsaved Changes"
            case .shareArtwork:
                return "Share Artwork"
            case .shareModifiedArtwork:
                return "Share Modified Artwork"
            case .restorePreviousWork:
                return "Restore Previous Work"
            }
        }
        
        var alertMessage: String {
            switch self {
            case .newArtwork:
                return "You have unsaved changes. Creating a new artwork will discard these changes."
            case .importArtwork:
                return "You have unsaved changes. Importing a different artwork code will discard these changes."
            case .shareArtwork:
                return "To share this artwork, you need to save it first. Would you like to save now?"
            case .shareModifiedArtwork:
                return "You have unsaved changes. Would you like to save these changes before sharing, or share the previous version?"
            case .restorePreviousWork:
                return "We found unsaved work from your previous session. Would you like to restore it?"
            }
        }
    }
    
    /// Shows a confirmation alert if there are unsaved changes
    /// - Parameters:
    ///   - hasUnsavedChanges: Boolean flag indicating if there are unsaved changes
    ///   - action: The action that might cause data loss
    ///   - showAlert: Binding to control alert visibility
    ///   - alertTitle: Binding for alert title
    ///   - alertMessage: Binding for alert message
    ///   - onProceed: Closure to execute if user confirms proceeding
    ///   - onSaveFirst: Optional closure to execute if user wants to save first
    /// - Returns: Whether the action should proceed immediately (true) or an alert is shown (false)
    static func checkUnsavedChanges(
        hasUnsavedChanges: Bool,
        action: PotentialDataLossAction,
        showAlert: Binding<Bool>,
        alertTitle: Binding<String>,
        alertMessage: Binding<String>,
        onProceed: @escaping () -> Void,
        onSaveFirst: (() -> Void)? = nil
    ) -> Bool {
        // If no unsaved changes, proceed immediately
        if !hasUnsavedChanges {
            return true
        }
        
        // Otherwise, prepare alert and return false to indicate alert is shown
        alertTitle.wrappedValue = action.alertTitle
        alertMessage.wrappedValue = action.alertMessage
        
        // Store action type for button customization
        UserDefaults.standard.set(action.rawValue, forKey: "currentAlertType")
        
        // Store closures in UserDefaults (not best practice but works for now)
        // In a real app, you'd use a more robust state management approach
        UserDefaults.standard.set(onSaveFirst != nil, forKey: showSaveOptionKey)
        
        // Set the action closures in a static property for the alert to access
        UnsavedChangesHandler.proceedAction = onProceed
        UnsavedChangesHandler.saveFirstAction = onSaveFirst
        
        // Show the alert
        showAlert.wrappedValue = true
        return false
    }
    
    // Static properties to store action closures
    // Not ideal but necessary for SwiftUI alert buttons to access
    static var proceedAction: (() -> Void)?
    static var saveFirstAction: (() -> Void)?
    static var saveExistingArtworkAction: (() -> Void)?
    static var restoreAction: (() -> Void)?
    static var discardRestorationAction: (() -> Void)?
    
    /// Creates a set of alert buttons for the unsaved changes alert
    /// - Returns: Alert button views
    static func alertButtons() -> some View {
        Group {
            let currentAction = UserDefaults.standard.string(forKey: "currentAlertType")
            
            // For shareArtwork case, use Yes/No buttons
            if currentAction == "shareArtwork" {
                Button("No", role: .cancel) {
                    // Do nothing, just dismiss the alert
                }
                
                Button("Yes") {
                    if let saveAction = saveFirstAction {
                        saveAction()
                    }
                }
            }
            // For shareModifiedArtwork case, use custom buttons
            else if currentAction == "shareModifiedArtwork" {
                Button("Share Previous Version", role: .destructive) {
                    proceedAction?()
                }
                
                Button("Save Changes & Share") {
                    if let saveAction = saveFirstAction {
                        saveAction()
                    }
                }
                
                Button("Cancel", role: .cancel) {
                    // Do nothing, just dismiss the alert
                }
            }
            // For other cases, use the standard buttons
            else {
                Button("Cancel", role: .cancel) {
                    // Do nothing, just dismiss the alert
                }
                
                Button("Proceed without Saving", role: .destructive) {
                    proceedAction?()
                }
                
                if UserDefaults.standard.bool(forKey: showSaveOptionKey) {
                    if (saveExistingArtworkAction != nil) {
                        // If we have an existing artwork action, use it
                        Button("Save") {
                            saveExistingArtworkAction?()
                        }
                    } else {
                        // Otherwise use the standard save first action (with prompt)
                        Button("Save First") {
                            saveFirstAction?()
                        }
                    }
                }
            }
        }
    }
    
    /// Creates alert buttons for the restoration dialog
    /// - Returns: Alert button views for restoration
    static func restorationAlertButtons() -> some View {
        Group {
            Button("Start Fresh", role: .cancel) {
                discardRestorationAction?()
                // Clear the saved state since user explicitly chose not to restore
                clearSavedState()
            }
            
            Button("Restore Previous Work") {
                restoreAction?()
            }
        }
    }
    
    /// Saves the current artwork state to UserDefaults for potential restoration
    /// - Parameters:
    ///   - artworkString: The string representation of the current artwork
    ///   - hasUnsavedChanges: Whether there are unsaved changes to persist
    static func saveStateForRestoration(artworkString: String, hasUnsavedChanges: Bool) {
        guard hasUnsavedChanges else {
            // If no unsaved changes, clear any previously saved state
            clearSavedState()
            return
        }
        
        UserDefaults.standard.set(artworkString, forKey: unsavedArtworkStringKey)
        UserDefaults.standard.set(Date(), forKey: unsavedArtworkTimestampKey)
        UserDefaults.standard.set(true, forKey: hasUnsavedWorkKey)
    }
    
    /// Clears any saved state from UserDefaults
    static func clearSavedState() {
        UserDefaults.standard.removeObject(forKey: unsavedArtworkStringKey)
        UserDefaults.standard.removeObject(forKey: unsavedArtworkTimestampKey)
        UserDefaults.standard.set(false, forKey: hasUnsavedWorkKey)
    }
    
    /// Checks if there is saved state that can be restored
    /// - Returns: Boolean indicating if there is saved state
    static func hasSavedState() -> Bool {
        return UserDefaults.standard.bool(forKey: hasUnsavedWorkKey) && 
               UserDefaults.standard.string(forKey: unsavedArtworkStringKey) != nil
    }
    
    /// Gets the saved artwork string if available
    /// - Returns: The saved artwork string, or nil if none exists
    static func getSavedArtworkString() -> String? {
        return UserDefaults.standard.string(forKey: unsavedArtworkStringKey)
    }
    
    /// Gets the timestamp of when the artwork was saved
    /// - Returns: The timestamp when the artwork was saved, or nil if not available
    static func getSavedTimestamp() -> Date? {
        return UserDefaults.standard.object(forKey: unsavedArtworkTimestampKey) as? Date
    }
    
    /// Shows restoration dialog if unsaved work exists from previous session
    /// - Parameters:
    ///   - showAlert: Binding to control alert visibility
    ///   - alertTitle: Binding for alert title
    ///   - alertMessage: Binding for alert message
    ///   - onRestore: Closure to execute if user wants to restore previous work
    ///   - onDiscard: Closure to execute if user wants to start fresh
    /// - Returns: Whether restoration dialog is shown (true) or not (false)
    static func checkForPreviousSession(
        showAlert: Binding<Bool>,
        alertTitle: Binding<String>,
        alertMessage: Binding<String>,
        onRestore: @escaping () -> Void,
        onDiscard: @escaping () -> Void
    ) -> Bool {
        guard hasSavedState() else {
            return false
        }
        
        // Calculate how old the saved state is
        let timestamp = getSavedTimestamp() ?? Date()
        let timeSinceLastSave = Date().timeIntervalSince(timestamp)
        
        // Only show restoration dialog if saved within last 24 hours (86400 seconds)
        // This prevents very old work from being restored unexpectedly
        if timeSinceLastSave > 86400 {
            clearSavedState()
            return false
        }
        
        // Configure the alert
        alertTitle.wrappedValue = PotentialDataLossAction.restorePreviousWork.alertTitle
        alertMessage.wrappedValue = PotentialDataLossAction.restorePreviousWork.alertMessage
        
        // Store the callbacks
        restoreAction = onRestore
        discardRestorationAction = onDiscard
        
        // Show the alert
        showAlert.wrappedValue = true
        return true
    }
} 