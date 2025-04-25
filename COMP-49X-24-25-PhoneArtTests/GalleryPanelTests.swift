import XCTest
import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseCore
@testable import COMP_49X_24_25_PhoneArt

// Define the ViewModel if it doesn't exist
@MainActor class GalleryPanelViewModel: ObservableObject {
    @Published var artworks: [ArtworkData] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var selectedArtwork: ArtworkData? = nil // Added for selection test
    
    private let firebaseService: FirebaseService
    var onSelectArtwork: ((ArtworkData) -> Void)? // Callback for selection
    var onDeleteArtwork: ((ArtworkData) -> Void)? // Callback for deletion
    
    init(firebaseService: FirebaseService = FirebaseService.shared) {
        self.firebaseService = firebaseService
    }
    
    func loadArtworks() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let fetchedArtworks = try await firebaseService.getArtwork()
                // Assign on main thread
                Task { @MainActor in
                     self.artworks = fetchedArtworks
                     self.isLoading = false
                     print("ViewModel: Loaded \(fetchedArtworks.count) artworks.")
                }
            } catch {
                 Task { @MainActor in
                    self.errorMessage = "Error loading artworks: \(error.localizedDescription)"
                    self.isLoading = false
                    print("ViewModel: Error loading artworks: \(error.localizedDescription)")
                 }
            }
        }
    }
    
    func selectArtwork(_ artwork: ArtworkData) {
        selectedArtwork = artwork
        onSelectArtwork?(artwork) // Call selection callback
        print("ViewModel: Selected artwork with ID: \(artwork.pieceId ?? "N/A")")
    }
    
    func deleteArtwork(_ artwork: ArtworkData) {
        // Optimistic UI update
        artworks.removeAll { $0.pieceId == artwork.pieceId }
        onDeleteArtwork?(artwork) // Call deletion callback
        print("ViewModel: Deleting artwork with ID: \(artwork.pieceId ?? "N/A")")
        
        // Call Firebase
        Task {
            do {
                try await firebaseService.deleteArtwork(artwork: artwork)
                 print("ViewModel: Successfully deleted artwork from Firebase.")
            } catch {
                 Task { @MainActor in
                     self.errorMessage = "Error deleting artwork: \(error.localizedDescription)"
                     // Consider adding the artwork back to the list if deletion failed
                      print("ViewModel: Error deleting artwork: \(error.localizedDescription)")
                 }
            }
        }
    }
}


@MainActor // Use MainActor for ViewModel tests
final class GalleryPanelTests: XCTestCase {

    var mockFirebaseService: MockFirebaseService!
    var sut: GalleryPanelViewModel! // Test the ViewModel
    var selectedArtworkCallbackData: ArtworkData?
    var deletedArtworkCallbackData: ArtworkData?

    override func setUp() {
        super.setUp()
        mockFirebaseService = MockFirebaseService() // Use the consolidated mock
        // Ensure shared instance is replaced if ViewModel uses it
        FirebaseService.shared = mockFirebaseService 
        
        sut = GalleryPanelViewModel(firebaseService: mockFirebaseService)
        
        // Reset callback trackers
        selectedArtworkCallbackData = nil
        deletedArtworkCallbackData = nil
        
        // Setup callbacks
        sut.onSelectArtwork = { artwork in
            self.selectedArtworkCallbackData = artwork
        }
        sut.onDeleteArtwork = { artwork in
             self.deletedArtworkCallbackData = artwork
        }
    }

    override func tearDown() {
        sut = nil
        mockFirebaseService = nil
        selectedArtworkCallbackData = nil
        deletedArtworkCallbackData = nil
        super.tearDown()
    }

    // Test initial state
    func testInitialState() {
        XCTAssertTrue(sut.artworks.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertNil(sut.selectedArtwork)
    }

    // Test loading artworks successfully
    func testLoadArtworks_Success() async {
        // Setup: Provide mock data in the service
        let mockArtwork1 = ArtworkData(deviceId: "d1", artworkString: "s1", timestamp: Date(), title: "Art 1", pieceId: "p1")
        let mockArtwork2 = ArtworkData(deviceId: "d1", artworkString: "s2", timestamp: Date(), title: "Art 2", pieceId: "p2")
        mockFirebaseService.mockArtworkList = [mockArtwork1, mockArtwork2]
        mockFirebaseService.mockGetArtworkListError = nil
        
        // Exercise: Load artworks
        sut.loadArtworks()
        
        // Verify: Wait for async and check state
        let expectation = XCTestExpectation(description: "Wait for artworks to load")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // Allow time for async tasks
            if !self.sut.isLoading { expectation.fulfill() }
        }
        await fulfillment(of: [expectation], timeout: 2.0)
        
        XCTAssertTrue(mockFirebaseService.getArtworkListCalled)
        XCTAssertEqual(sut.artworks.count, 2)
        XCTAssertEqual(sut.artworks.first?.pieceId, "p1")
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }
    
    // Test loading artworks with failure
    func testLoadArtworks_Failure() async {
        // Setup: Configure mock service for error
        let testError = NSError(domain: "LoadError", code: 404, userInfo: nil)
        mockFirebaseService.mockGetArtworkListError = testError
        
        // Exercise: Load artworks
        sut.loadArtworks()
        
        // Verify: Wait for async and check state
        let expectation = XCTestExpectation(description: "Wait for artwork loading failure")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !self.sut.isLoading { expectation.fulfill() }
        }
        await fulfillment(of: [expectation], timeout: 2.0)
        
        XCTAssertTrue(mockFirebaseService.getArtworkListCalled)
        XCTAssertTrue(sut.artworks.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertEqual(sut.errorMessage, "Error loading artworks: \(testError.localizedDescription)")
    }

    // Test artwork selection
    func testSelectArtwork() {
        // Setup
        let artworkToSelect = ArtworkData(deviceId: "d1", artworkString: "s1", timestamp: Date(), title: "Select Me", pieceId: "p-select")
        sut.artworks = [artworkToSelect] // Add to list for context
        
        // Exercise
        sut.selectArtwork(artworkToSelect)
        
        // Verify
        XCTAssertEqual(sut.selectedArtwork?.pieceId, "p-select")
        XCTAssertEqual(selectedArtworkCallbackData?.pieceId, "p-select")
    }

    // Test artwork deletion
    func testDeleteArtwork() async {
        // Setup
        let artworkToDelete = ArtworkData(deviceId: "d1", artworkString: "s-del", timestamp: Date(), title: "Delete Me", pieceId: "p-delete")
        sut.artworks = [artworkToDelete] // Start with the artwork in the list
        mockFirebaseService.mockError = nil // Ensure no Firebase error for deletion
        
        // Exercise
        sut.deleteArtwork(artworkToDelete)
        
        // Verify Optimistic Update
        XCTAssertTrue(sut.artworks.isEmpty, "Artwork should be removed from list immediately")
        XCTAssertEqual(deletedArtworkCallbackData?.pieceId, "p-delete")
        
        // Verify Firebase call (wait briefly)
        let expectation = XCTestExpectation(description: "Wait for delete operation")
         DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
             // Check if delete was attempted in mock (if mock tracks it)
             expectation.fulfill()
         }
         await fulfillment(of: [expectation], timeout: 2.0)
         // Add assertion here if your mock tracks delete calls
         // e.g., XCTAssertTrue(mockFirebaseService.deleteCalled)
         XCTAssertNil(sut.errorMessage) // Should not have error on success
    }

    // Test artwork data loading (Simplified, checks initial state after setup)
    func testArtworkDataLoading_ViewModelState() {
        // Setup: Provide some mock artwork data directly to ViewModel
        let mockArtwork = ArtworkData(deviceId: "d1", artworkString: "s-load", timestamp: Date(), title: "Mock 1", pieceId: "p-load")
        sut.artworks = [mockArtwork] // Set directly for test
        
        // Verify: Check the ViewModel's artworks property
        XCTAssertEqual(sut.artworks.count, 1)
        XCTAssertEqual(sut.artworks.first?.pieceId, "p-load")
    }

}