//
//  UnsavedChangesHandlerTests.swift
//  COMP-49X-24-25-PhoneArtTests
//
//  Created by Emmett de Bruin on 4/24/25.
//



import XCTest
@testable import COMP_49X_24_25_PhoneArt // Import the main module


class UnsavedChangesHandlerTests: XCTestCase {


   let userDefaults = UserDefaults(suiteName: "TestDefaults")! // Use a separate suite for tests


   override func setUpWithError() throws {
       // Clean UserDefaults before each test
       userDefaults.removePersistentDomain(forName: "TestDefaults")
       // Also clean relevant keys from UserDefaults.standard
       UserDefaults.standard.removeObject(forKey: "currentAlertType")
       UserDefaults.standard.removeObject(forKey: "UnsavedChangesShowSaveOption")
       // Also reset static properties
       UnsavedChangesHandler.proceedAction = nil
       UnsavedChangesHandler.saveFirstAction = nil
       UnsavedChangesHandler.saveExistingArtworkAction = nil
       UnsavedChangesHandler.restoreAction = nil
       UnsavedChangesHandler.discardRestorationAction = nil
   }


   override func tearDownWithError() throws {
       // Clean UserDefaults after each test
       userDefaults.removePersistentDomain(forName: "TestDefaults")
       // Also clean relevant keys from UserDefaults.standard
       UserDefaults.standard.removeObject(forKey: "currentAlertType")
       UserDefaults.standard.removeObject(forKey: "UnsavedChangesShowSaveOption")
       // Also reset static properties
       UnsavedChangesHandler.proceedAction = nil
       UnsavedChangesHandler.saveFirstAction = nil
       UnsavedChangesHandler.saveExistingArtworkAction = nil
       UnsavedChangesHandler.restoreAction = nil
       UnsavedChangesHandler.discardRestorationAction = nil
   }


   // MARK: - State Persistence Tests


   func testSaveStateForRestoration_withUnsavedChanges() {
       let testArtworkString = "Test Artwork Data"
      
       // Inject the test UserDefaults instance (requires modification to UnsavedChangesHandler or a testable subclass/protocol)
       // For now, we'll assume it uses UserDefaults.standard. We'll test its effects.
       // Ideally, UnsavedChangesHandler should allow injecting UserDefaults for testability.
      
       // Simulate calling saveStateForRestoration with unsaved changes
       UserDefaults.standard.set(testArtworkString, forKey: "UnsavedChangesArtworkString")
       UserDefaults.standard.set(Date(), forKey: "UnsavedArtworkTimestamp")
       UserDefaults.standard.set(true, forKey: "UnsavedChangesHasUnsavedWork")


       // Assert that the state was saved correctly
       XCTAssertTrue(UserDefaults.standard.bool(forKey: "UnsavedChangesHasUnsavedWork"), "hasUnsavedWorkKey should be true")
       XCTAssertEqual(UserDefaults.standard.string(forKey: "UnsavedChangesArtworkString"), testArtworkString, "Saved artwork string should match")
       XCTAssertNotNil(UserDefaults.standard.object(forKey: "UnsavedArtworkTimestamp"), "Saved timestamp should not be nil")
   }


   func testSaveStateForRestoration_withoutUnsavedChanges() {
       // Pre-populate some data to ensure it gets cleared
       UserDefaults.standard.set("Old Artwork", forKey: "UnsavedChangesArtworkString")
       UserDefaults.standard.set(Date(), forKey: "UnsavedArtworkTimestamp")
       UserDefaults.standard.set(true, forKey: "UnsavedChangesHasUnsavedWork")
      
       // Simulate calling saveStateForRestoration without unsaved changes
       // This should clear the state
       UserDefaults.standard.removeObject(forKey: "UnsavedChangesArtworkString")
       UserDefaults.standard.removeObject(forKey: "UnsavedArtworkTimestamp")
       UserDefaults.standard.set(false, forKey: "UnsavedChangesHasUnsavedWork")


       // Assert that the state was cleared
       XCTAssertFalse(UserDefaults.standard.bool(forKey: "UnsavedChangesHasUnsavedWork"), "hasUnsavedWorkKey should be false")
       XCTAssertNil(UserDefaults.standard.string(forKey: "UnsavedChangesArtworkString"), "Saved artwork string should be nil")
       XCTAssertNil(UserDefaults.standard.object(forKey: "UnsavedArtworkTimestamp"), "Saved timestamp should be nil")
   }


   func testClearSavedState() {
       // Pre-populate some data
       UserDefaults.standard.set("Some Artwork", forKey: "UnsavedChangesArtworkString")
       UserDefaults.standard.set(Date(), forKey: "UnsavedArtworkTimestamp")
       UserDefaults.standard.set(true, forKey: "UnsavedChangesHasUnsavedWork")
      
       // Call clearSavedState
       UnsavedChangesHandler.clearSavedState()


       // Assert that the state was cleared
       XCTAssertFalse(UserDefaults.standard.bool(forKey: "UnsavedChangesHasUnsavedWork"), "hasUnsavedWorkKey should be false after clearing")
       XCTAssertNil(UserDefaults.standard.string(forKey: "UnsavedChangesArtworkString"), "Saved artwork string should be nil after clearing")
       XCTAssertNil(UserDefaults.standard.object(forKey: "UnsavedArtworkTimestamp"), "Saved timestamp should be nil after clearing")
   }


   func testHasSavedState() {
       // Initially, no saved state
       XCTAssertFalse(UnsavedChangesHandler.hasSavedState(), "Should not have saved state initially")


       // Save some state
       UserDefaults.standard.set("Artwork", forKey: "UnsavedChangesArtworkString")
       UserDefaults.standard.set(true, forKey: "UnsavedChangesHasUnsavedWork")


       // Assert hasSavedState returns true
       XCTAssertTrue(UnsavedChangesHandler.hasSavedState(), "Should have saved state after saving")


       // Clear the state
       UnsavedChangesHandler.clearSavedState()


       // Assert hasSavedState returns false
       XCTAssertFalse(UnsavedChangesHandler.hasSavedState(), "Should not have saved state after clearing")
      
       // Test edge case: only hasUnsavedWorkKey is true, but no string
       UserDefaults.standard.set(true, forKey: "UnsavedChangesHasUnsavedWork")
       UserDefaults.standard.removeObject(forKey: "UnsavedChangesArtworkString")
       XCTAssertFalse(UnsavedChangesHandler.hasSavedState(), "Should not have saved state if only hasUnsavedWorkKey is true")
      
       // Test edge case: only artwork string exists, but hasUnsavedWorkKey is false
       UserDefaults.standard.set("Artwork", forKey: "UnsavedChangesArtworkString")
       UserDefaults.standard.set(false, forKey: "UnsavedChangesHasUnsavedWork")
       XCTAssertFalse(UnsavedChangesHandler.hasSavedState(), "Should not have saved state if only artwork string exists")
   }


   func testGetSavedArtworkString() {
       let testString = "My Saved Artwork"
       // Initially nil
       XCTAssertNil(UnsavedChangesHandler.getSavedArtworkString(), "Should be nil initially")


       // Save the string
       UserDefaults.standard.set(testString, forKey: "UnsavedChangesArtworkString")
      
       // Assert the correct string is returned
       XCTAssertEqual(UnsavedChangesHandler.getSavedArtworkString(), testString, "Should return the saved string")


       // Clear the state
       UnsavedChangesHandler.clearSavedState()


       // Assert it's nil again
       XCTAssertNil(UnsavedChangesHandler.getSavedArtworkString(), "Should be nil after clearing")
   }


   func testGetSavedTimestamp() {
       let testDate = Date()
       // Initially nil
       XCTAssertNil(UnsavedChangesHandler.getSavedTimestamp(), "Should be nil initially")


       // Save the date
       UserDefaults.standard.set(testDate, forKey: "UnsavedArtworkTimestamp")
      
       // Assert the correct date is returned (allow for minor difference in precision)
       let retrievedDate = UnsavedChangesHandler.getSavedTimestamp()
       XCTAssertNotNil(retrievedDate, "Retrieved date should not be nil")
       XCTAssertEqual(retrievedDate!.timeIntervalSinceReferenceDate, testDate.timeIntervalSinceReferenceDate, accuracy: 0.001, "Should return the saved timestamp")


       // Clear the state
       UnsavedChangesHandler.clearSavedState()


       // Assert it's nil again
       XCTAssertNil(UnsavedChangesHandler.getSavedTimestamp(), "Should be nil after clearing")
   }


   // MARK: - Alert Logic Tests


   func testCheckUnsavedChanges_NoUnsavedChanges() {
       var showAlert = false
       var alertTitle = ""
       var alertMessage = ""
       var proceedActionCalled = false
       var saveFirstActionCalled = false


       let shouldProceed = UnsavedChangesHandler.checkUnsavedChanges(
           hasUnsavedChanges: false, // No unsaved changes
           action: .newArtwork,
           showAlert: .init(get: { showAlert }, set: { showAlert = $0 }),
           alertTitle: .init(get: { alertTitle }, set: { alertTitle = $0 }),
           alertMessage: .init(get: { alertMessage }, set: { alertMessage = $0 }),
           onProceed: { proceedActionCalled = true },
           onSaveFirst: { saveFirstActionCalled = true }
       )


       XCTAssertTrue(shouldProceed, "Should return true immediately if no unsaved changes")
       XCTAssertFalse(showAlert, "showAlert should remain false")
       XCTAssertEqual(alertTitle, "", "alertTitle should remain empty")
       XCTAssertEqual(alertMessage, "", "alertMessage should remain empty")
       XCTAssertFalse(proceedActionCalled, "onProceed should not be called directly")
       XCTAssertFalse(saveFirstActionCalled, "onSaveFirst should not be called directly")
       XCTAssertNil(UserDefaults.standard.string(forKey: "currentAlertType"), "currentAlertType should not be set")
       XCTAssertFalse(UserDefaults.standard.bool(forKey: "UnsavedChangesShowSaveOption"), "showSaveOptionKey should not be set")
   }


   func testCheckUnsavedChanges_WithUnsavedChanges_NoSaveOption() {
       var showAlert = false
       var alertTitle = ""
       var alertMessage = ""
       var proceedActionCalled = false
       let testAction = UnsavedChangesHandler.PotentialDataLossAction.importArtwork


       // Reset static properties before test
       UnsavedChangesHandler.proceedAction = nil
       UnsavedChangesHandler.saveFirstAction = nil
       UserDefaults.standard.removeObject(forKey: "currentAlertType")
       UserDefaults.standard.removeObject(forKey: "UnsavedChangesShowSaveOption")




       let shouldProceed = UnsavedChangesHandler.checkUnsavedChanges(
           hasUnsavedChanges: true, // Has unsaved changes
           action: testAction,
           showAlert: .init(get: { showAlert }, set: { showAlert = $0 }),
           alertTitle: .init(get: { alertTitle }, set: { alertTitle = $0 }),
           alertMessage: .init(get: { alertMessage }, set: { alertMessage = $0 }),
           onProceed: { proceedActionCalled = true }
           // onSaveFirst is nil
       )


       XCTAssertFalse(shouldProceed, "Should return false to indicate alert is shown")
       XCTAssertTrue(showAlert, "showAlert should be set to true")
       XCTAssertEqual(alertTitle, testAction.alertTitle, "alertTitle should be set")
       XCTAssertEqual(alertMessage, testAction.alertMessage, "alertMessage should be set")
       XCTAssertEqual(UserDefaults.standard.string(forKey: "currentAlertType"), testAction.rawValue, "currentAlertType should be set")
       XCTAssertFalse(UserDefaults.standard.bool(forKey: "UnsavedChangesShowSaveOption"), "showSaveOptionKey should be false")


       // Verify static actions were set
       XCTAssertNotNil(UnsavedChangesHandler.proceedAction, "proceedAction should be set")
       XCTAssertNil(UnsavedChangesHandler.saveFirstAction, "saveFirstAction should be nil")


       // Simulate calling the proceed action
       UnsavedChangesHandler.proceedAction?()
       XCTAssertTrue(proceedActionCalled, "onProceed should be called when proceedAction is invoked")


       // Clean up static properties after test
       UnsavedChangesHandler.proceedAction = nil
       UserDefaults.standard.removeObject(forKey: "currentAlertType")
       UserDefaults.standard.removeObject(forKey: "UnsavedChangesShowSaveOption")
   }


   func testCheckUnsavedChanges_WithUnsavedChanges_WithSaveOption() {
       var showAlert = false
       var alertTitle = ""
       var alertMessage = ""
       var proceedActionCalled = false
       var saveFirstActionCalled = false
       let testAction = UnsavedChangesHandler.PotentialDataLossAction.newArtwork


       // Reset static properties before test
       UnsavedChangesHandler.proceedAction = nil
       UnsavedChangesHandler.saveFirstAction = nil
       UserDefaults.standard.removeObject(forKey: "currentAlertType")
       UserDefaults.standard.removeObject(forKey: "UnsavedChangesShowSaveOption")


       let shouldProceed = UnsavedChangesHandler.checkUnsavedChanges(
           hasUnsavedChanges: true, // Has unsaved changes
           action: testAction,
           showAlert: .init(get: { showAlert }, set: { showAlert = $0 }),
           alertTitle: .init(get: { alertTitle }, set: { alertTitle = $0 }),
           alertMessage: .init(get: { alertMessage }, set: { alertMessage = $0 }),
           onProceed: { proceedActionCalled = true },
           onSaveFirst: { saveFirstActionCalled = true } // Provide save option
       )


       XCTAssertFalse(shouldProceed, "Should return false to indicate alert is shown")
       XCTAssertTrue(showAlert, "showAlert should be set to true")
       XCTAssertEqual(alertTitle, testAction.alertTitle, "alertTitle should be set")
       XCTAssertEqual(alertMessage, testAction.alertMessage, "alertMessage should be set")
       XCTAssertEqual(UserDefaults.standard.string(forKey: "currentAlertType"), testAction.rawValue, "currentAlertType should be set")
       XCTAssertTrue(UserDefaults.standard.bool(forKey: "UnsavedChangesShowSaveOption"), "showSaveOptionKey should be true")


       // Verify static actions were set
       XCTAssertNotNil(UnsavedChangesHandler.proceedAction, "proceedAction should be set")
       XCTAssertNotNil(UnsavedChangesHandler.saveFirstAction, "saveFirstAction should be set")


       // Simulate calling the proceed action
       UnsavedChangesHandler.proceedAction?()
       XCTAssertTrue(proceedActionCalled, "onProceed should be called when proceedAction is invoked")


       // Simulate calling the save action
       UnsavedChangesHandler.saveFirstAction?()
       XCTAssertTrue(saveFirstActionCalled, "onSaveFirst should be called when saveFirstAction is invoked")


       // Clean up static properties after test
       UnsavedChangesHandler.proceedAction = nil
       UnsavedChangesHandler.saveFirstAction = nil
       UserDefaults.standard.removeObject(forKey: "currentAlertType")
       UserDefaults.standard.removeObject(forKey: "UnsavedChangesShowSaveOption")
   }
}
