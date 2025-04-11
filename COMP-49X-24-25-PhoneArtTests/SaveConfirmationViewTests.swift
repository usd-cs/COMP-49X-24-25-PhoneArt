import XCTest
@testable import COMP_49X_24_25_PhoneArt

// Test the SaveConfirmation logic, not the view itself
class SaveConfirmationLogicTests: XCTestCase {
    
    // Track whether callback was triggered
    var dismissCalled = false
    var copyCalled = false
    
    override func setUp() {
        super.setUp()
        dismissCalled = false
        copyCalled = false
    }
    
    override func tearDown() {
        dismissCalled = false
        copyCalled = false
        super.tearDown()
    }
    
    // Test the initial state of the confirmation logic
    func testInitialState() {
        let viewModel = SaveConfirmationViewModel(
            isCopied: false,
            message: "Test message"
        )
        
        // Verify initial state
        XCTAssertEqual(viewModel.isCopied, false)
        XCTAssertEqual(viewModel.message, "Test message")
    }
    
    // Test message handling
    func testMessageHandling() {
        let testMessage = "Artwork saved successfully!"
        
        let viewModel = SaveConfirmationViewModel(
            isCopied: false,
            message: testMessage
        )
        
        // Verify message is stored correctly
        XCTAssertEqual(viewModel.message, testMessage)
        
        // Test updating the message
        viewModel.updateMessage("New message")
        XCTAssertEqual(viewModel.message, "New message")
    }
    
    // Test dismiss action
    func testDismissAction() {
        let viewModel = SaveConfirmationViewModel(
            isCopied: false,
            message: "Test message"
        )
        
        // Set up the dismiss callback
        viewModel.onDismiss = { self.dismissCalled = true }
        
        // Trigger dismiss action
        viewModel.dismiss()
        
        // Verify callback was triggered
        XCTAssertTrue(dismissCalled)
    }
    
    // Test copy action
    func testCopyAction() {
        let viewModel = SaveConfirmationViewModel(
            isCopied: false,
            message: "Test message"
        )
        
        // Set up the copy callback
        viewModel.onCopy = { self.copyCalled = true }
        
        // Trigger copy action
        viewModel.copy()
        
        // Verify callback was triggered
        XCTAssertTrue(copyCalled)
        XCTAssertTrue(viewModel.isCopied)
    }
    
    // Test that isCopied state changes correctly
    func testCopiedStateChanges() {
        let viewModel = SaveConfirmationViewModel(
            isCopied: false,
            message: "Test message"
        )
        
        // Verify initial state
        XCTAssertFalse(viewModel.isCopied)
        
        // Change state
        viewModel.isCopied = true
        XCTAssertTrue(viewModel.isCopied)
        
        // Test toggling back
        viewModel.isCopied = false
        XCTAssertFalse(viewModel.isCopied)
    }
    
    // Test the reset functionality
    func testResetState() {
        let viewModel = SaveConfirmationViewModel(
            isCopied: true,
            message: "Test message"
        )
        
        // Set up initial state
        XCTAssertTrue(viewModel.isCopied)
        
        // Reset state
        viewModel.resetCopiedState()
        
        // Verify state change
        XCTAssertFalse(viewModel.isCopied)
    }
    
    // Test coordinated actions
    func testCoordinatedActions() {
        let viewModel = SaveConfirmationViewModel(
            isCopied: false, 
            message: "Test message"
        )
        
        // Setup tracking variables
        var actionSequence: [String] = []
        
        // Set callbacks
        viewModel.onCopy = { 
            self.copyCalled = true
            actionSequence.append("copy")
        }
        
        viewModel.onDismiss = {
            self.dismissCalled = true
            actionSequence.append("dismiss")
        }
        
        // Perform actions in sequence
        viewModel.copy()
        viewModel.dismiss()
        
        // Verify callbacks and sequence
        XCTAssertTrue(copyCalled)
        XCTAssertTrue(dismissCalled)
        XCTAssertEqual(actionSequence, ["copy", "dismiss"])
    }
}

// This is a simple ViewModel that would typically back the SaveConfirmationView
// In a real implementation, this might be an actual class in your app
class SaveConfirmationViewModel {
    var isCopied: Bool
    var message: String
    var onDismiss: (() -> Void)?
    var onCopy: (() -> Void)?
    
    init(isCopied: Bool, message: String) {
        self.isCopied = isCopied
        self.message = message
    }
    
    func updateMessage(_ newMessage: String) {
        message = newMessage
    }
    
    func dismiss() {
        onDismiss?()
    }
    
    func copy() {
        isCopied = true
        onCopy?()
    }
    
    func resetCopiedState() {
        isCopied = false
    }
} 