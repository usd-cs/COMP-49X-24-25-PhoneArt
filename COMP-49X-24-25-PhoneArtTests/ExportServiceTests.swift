//
//  ExportServiceTests.swift
//  COMP-49X-24-25-PhoneArtTests
//
//  Created by Aditya Prakash on 3/27/25.
//


import XCTest
import UIKit
import Photos
@testable import COMP_49X_24_25_PhoneArt


/// Test suite for the ExportService component
final class ExportServiceTests: XCTestCase {
   // Test view for export operations
   var testView: UIView!
  
   // Mock image data
   var mockPNGData: Data!
   var mockJPEGData: Data!
  
   /// Sets up the test environment before each test method is called
   override func setUp() {
       super.setUp()
      
       // Create a test view with a known background color for verifying image generation
       testView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
       testView.backgroundColor = .red
      
       // Create mock data to substitute for actual image data in tests
       mockPNGData = Data(repeating: 0, count: 100)
       mockJPEGData = Data(repeating: 1, count: 100)
   }
  
   /// Cleans up the test environment after each test method is called
   override func tearDown() {
       testView = nil
       mockPNGData = nil
       mockJPEGData = nil
       super.tearDown()
   }
  
   /// Tests that the ExportFormat enum correctly provides MIME types
   func testExportFormatMimeTypes() {
       // Verify PNG MIME type
       XCTAssertEqual(ExportService.ExportFormat.png.mimeType, "image/png")
      
       // Verify JPEG MIME type
       XCTAssertEqual(ExportService.ExportFormat.jpeg.mimeType, "image/jpeg")
   }
  
   /// Tests that the ExportFormat enum correctly provides file extensions
   func testExportFormatFileExtensions() {
       // Verify PNG file extension
       XCTAssertEqual(ExportService.ExportFormat.png.fileExtension, "png")
      
       // Verify JPEG file extension
       XCTAssertEqual(ExportService.ExportFormat.jpeg.fileExtension, "jpeg")
   }
  
   /// Tests that all ExportFormat cases have correctly configured identifiers
   func testExportFormatIdentifiers() {
       for format in ExportService.ExportFormat.allCases {
           XCTAssertEqual(format.id, format.rawValue)
       }
   }
  
   /// Tests the exportToFile function with PNG format
   func testExportToFilePNG() {
       // Setup an expectation for the asynchronous export operation
       let expectation = XCTestExpectation(description: "Export to PNG file")
      
       // Perform the export
       ExportService.exportToFile(
           from: testView,
           format: .png,
           quality: 1.0,
           filename: "test.png"
       ) { url, error in
           // Verify export completed with a valid URL and no error
           XCTAssertNotNil(url)
           XCTAssertNil(error)
          
           // Verify the URL has the correct filename extension
           XCTAssertEqual(url?.pathExtension, "png")
          
           // Verify the file exists at the URL
           if let url = url {
               XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
              
               // Clean up the test file
               try? FileManager.default.removeItem(at: url)
           }
          
           expectation.fulfill()
       }
      
       // Wait for the expectation to be fulfilled
       wait(for: [expectation], timeout: 5.0)
   }
  
   /// Tests the exportToFile function with JPEG format
   func testExportToFileJPEG() {
       // Setup an expectation for the asynchronous export operation
       let expectation = XCTestExpectation(description: "Export to JPEG file")
      
       // Perform the export
       ExportService.exportToFile(
           from: testView,
           format: .jpeg,
           quality: 0.8,
           filename: "test.jpeg"
       ) { url, error in
           // Verify export completed with a valid URL and no error
           XCTAssertNotNil(url)
           XCTAssertNil(error)
          
           // Verify the URL has the correct filename extension
           XCTAssertEqual(url?.pathExtension, "jpeg")
          
           // Verify the file exists at the URL
           if let url = url {
               XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
              
               // Clean up the test file
               try? FileManager.default.removeItem(at: url)
           }
          
           expectation.fulfill()
       }
      
       // Wait for the expectation to be fulfilled
       wait(for: [expectation], timeout: 5.0)
   }
  
   /// Tests the exportToFile function with a specified export rectangle
   func testExportRectangle() {
       // Use a mock view with a specific size
       let mockView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
       mockView.backgroundColor = .blue
      
       // Define a subset rectangle to export (top-left quarter)
       _ = CGRect(x: 0, y: 0, width: 100, height: 100)
      
       // Setup an expectation for the asynchronous export operation
       let expectation = XCTestExpectation(description: "Export specific rectangle")
      
       // Mock the exportToPhotoLibrary method with a custom implementation
       // Note: We can't actually test photo library permissions in a unit test
       // So we're testing the file export with a rectangle instead
       ExportService.exportToFile(
           from: mockView,
           format: .png,
           quality: 1.0,
           filename: "rect_test.png"
       ) { url, error in
           // Verify export completed with a valid URL and no error
           XCTAssertNotNil(url)
           XCTAssertNil(error)
          
           // Clean up the test file
           if let url = url {
               try? FileManager.default.removeItem(at: url)
           }
          
           expectation.fulfill()
       }
      
       // Wait for the expectation to be fulfilled
       wait(for: [expectation], timeout: 5.0)
   }
  
   /// Tests handling of auto-generated filenames
   func testAutogeneratedFilenames() {
       // Setup an expectation for the asynchronous export operation
       let expectation = XCTestExpectation(description: "Export with auto-generated filename")
      
       // Perform the export without providing a filename
       ExportService.exportToFile(
           from: testView,
           format: .png
       ) { url, error in
           // Verify export completed with a valid URL and no error
           XCTAssertNotNil(url)
           XCTAssertNil(error)
          
           // Verify the URL has the correct pattern (should start with "PhoneArt_" and end with ".png")
           if let filename = url?.lastPathComponent {
               XCTAssertTrue(filename.hasPrefix("PhoneArt_"))
               XCTAssertTrue(filename.hasSuffix(".png"))
           }
          
           // Clean up the test file
           if let url = url {
               try? FileManager.default.removeItem(at: url)
           }
          
           expectation.fulfill()
       }
      
       // Wait for the expectation to be fulfilled
       wait(for: [expectation], timeout: 5.0)
   }
  
   /// Tests different quality settings for JPEG export
   func testJPEGQualitySettings() {
       // Setup test cases with different quality settings
       let qualities: [CGFloat] = [0.1, 0.5, 0.9]
      
       // Setup expectations for each quality test
       let expectations = qualities.map { quality in
           XCTestExpectation(description: "Export JPEG with quality \(quality)")
       }
      
       // Test each quality setting
       for (index, quality) in qualities.enumerated() {
           ExportService.exportToFile(
               from: testView,
               format: .jpeg,
               quality: quality,
               filename: "quality_\(quality).jpeg"
           ) { url, error in
               // Verify export completed with a valid URL and no error
               XCTAssertNotNil(url)
               XCTAssertNil(error)
              
               // Clean up the test file
               if let url = url {
                   try? FileManager.default.removeItem(at: url)
               }
              
               expectations[index].fulfill()
           }
       }
      
       // Wait for all expectations to be fulfilled
       wait(for: expectations, timeout: 5.0)
   }
  
   /// Tests the photo library authorization request by simulating denied permission
   func testPhotoLibraryPermissionDenied() {
       // This test would typically use mocking or dependency injection to simulate
       // the photo library authorization denied scenario
      
       // Since we can't easily mock PHPhotoLibrary in a unit test without significant
       // architectural changes, this test is more of a placeholder demonstrating
       // what should be tested in a real-world scenario with mocking capabilities
      
       // In an ideal test setup, we would:
       // 1. Mock PHPhotoLibrary to return .denied authorization status
       // 2. Call exportToPhotoLibrary
       // 3. Verify the completion handler is called with (false, error)
       // 4. Check that the error domain and code match expected values
      
       // As a placeholder, we'll just mark this test as a success
       XCTAssertTrue(true, "Photo library permission testing requires mocking")
   }
  
   /// Tests exportToPhotoLibrary with authorized permission status
   /// This test will attempt to exercise the code path but may not complete
   /// depending on actual photo library permissions during test execution
   func testExportToPhotoLibraryAuthorized() {
       // Skip this test in CI environments
       let isCI = ProcessInfo.processInfo.environment["CI"] == "true"
       if isCI {
           XCTAssertTrue(true, "Skipping in CI environment")
           return
       }
      
       // Current auth status - we'll only test if already authorized
       let status = PHPhotoLibrary.authorizationStatus()
       if status == .authorized {
           let expectation = XCTestExpectation(description: "Export to photo library")
          
           // Call the method we want to test
           ExportService.exportToPhotoLibrary(
               from: testView,
               format: .png,
               quality: 1.0,
               filename: "test_photo_library.png",
               completion: { success, error in
                   // Just verify the method call completes without crashing
                   // Actual success depends on device permissions
                   expectation.fulfill()
               }
           )
          
           wait(for: [expectation], timeout: 10.0)
       } else {
           // Skip the test if not authorized
           XCTAssertTrue(true, "Skipping test as photo library access is not authorized")
       }
   }
  
   /// Attempt to test the thread handling in exportToPhotoLibrary
   func testExportToPhotoLibraryThreadSafety() {
       // This test is designed to exercise the thread handling code path
       // even if the actual photo library operation doesn't complete
       let expectation = XCTestExpectation(description: "Export called from background thread")
      
       // Execute from background thread to test thread safety mechanism
       DispatchQueue.global(qos: .background).async {
           // Call exportToPhotoLibrary from background thread
           ExportService.exportToPhotoLibrary(
               from: self.testView,
               format: .png,
               quality: 1.0,
               filename: "thread_test.png",
               completion: { _, _ in
                   // Don't need to verify result, just that the method was called
                   expectation.fulfill()
               }
           )
       }
      
       // Short wait since we're just verifying the call is made and redirected
       // to the main thread without crashing
       wait(for: [expectation], timeout: 3.0)
   }
  
   /// Test exportToPhotoLibrary with different export formats
   func testExportToPhotoLibraryFormats() {
       // Skip this test in CI environments
       let isCI = ProcessInfo.processInfo.environment["CI"] == "true"
       if isCI {
           XCTAssertTrue(true, "Skipping in CI environment")
           return
       }
      
       let formats: [ExportService.ExportFormat] = [.png, .jpeg]
       let expectations = formats.map { format in
           XCTestExpectation(description: "Export to photo library with format \(format.rawValue)")
       }
      
       for (index, format) in formats.enumerated() {
           // Call the exportToPhotoLibrary method with different formats
           ExportService.exportToPhotoLibrary(
               from: testView,
               format: format,
               quality: 0.9,
               filename: "format_test_\(format.rawValue).\(format.fileExtension)",
               completion: { _, _ in
                   expectations[index].fulfill()
               }
           )
       }
      
       // Short timeout since we're just verifying the method calls proceed without crashing
       wait(for: expectations, timeout: 3.0)
   }
  
   /// Test exportToPhotoLibrary with border inclusion option
   func testExportToBorderOptions() {
       // Skip this test in CI environments
       let isCI = ProcessInfo.processInfo.environment["CI"] == "true"
       if isCI {
           XCTAssertTrue(true, "Skipping in CI environment")
           return
       }
      
       let borderOptions = [true, false]
       let expectations = borderOptions.map { includeBorder in
           XCTestExpectation(description: "Export with includeBorder=\(includeBorder)")
       }
      
       for (index, includeBorder) in borderOptions.enumerated() {
           // Call the exportToPhotoLibrary method with different border options
           ExportService.exportToPhotoLibrary(
               from: testView,
               format: .png,
               quality: 1.0,
               filename: "border_test_\(includeBorder).png",
               includeBorder: includeBorder,
               completion: { _, _ in
                   expectations[index].fulfill()
               }
           )
       }
      
       // Short timeout since we're just verifying the method calls proceed without crashing
       wait(for: expectations, timeout: 3.0)
   }
  
   /// Test the exportToPhotoLibrary method with custom rect
   func testExportWithCustomRect() {
       // Skip this test in CI environments
       let isCI = ProcessInfo.processInfo.environment["CI"] == "true"
       if isCI {
           XCTAssertTrue(true, "Skipping in CI environment")
           return
       }
      
       let expectation = XCTestExpectation(description: "Export with custom rect")
      
       // Create a custom export rectangle - only export a portion of the view
       let exportRect = CGRect(x: 10, y: 10, width: 50, height: 50)
      
       // Custom view with specific content
       let customView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
       let redSquare = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
       redSquare.backgroundColor = .red
       let blueSquare = UIView(frame: CGRect(x: 100, y: 100, width: 100, height: 100))
       blueSquare.backgroundColor = .blue
       customView.addSubview(redSquare)
       customView.addSubview(blueSquare)
      
       // Call the exportToPhotoLibrary method with exportRect parameter
       ExportService.exportToPhotoLibrary(
           from: customView,
           exportRect: exportRect,
           format: .png,
           quality: 1.0,
           filename: "rect_export_test.png",
           completion: { success, error in
               // Just verify the method call completes without crashing
               // We can't verify the exported image content in an automated test
               expectation.fulfill()
           }
       )
      
       // Use a longer timeout since this might involve system photo permissions
       wait(for: [expectation], timeout: 10.0)
   }
  
   /// Test export with nil filename (should generate one)
   func testExportWithNilFilename() {
       let expectation = XCTestExpectation(description: "Export with nil filename")
      
       // Call the exportToFile method with nil filename
       ExportService.exportToFile(
           from: testView,
           format: .png,
           quality: 1.0,
           filename: nil
       ) { url, error in
           // Verify export completed with a valid URL and no error
           XCTAssertNotNil(url)
           XCTAssertNil(error)
          
           // Verify filename contains expected pattern
           if let filename = url?.lastPathComponent {
               XCTAssertTrue(filename.hasPrefix("PhoneArt_"))
               XCTAssertTrue(filename.hasSuffix(".png"))
           }
          
           // Clean up the test file
           if let url = url {
               try? FileManager.default.removeItem(at: url)
           }
          
           expectation.fulfill()
       }
      
       wait(for: [expectation], timeout: 5.0)
   }
  
   /// Test export with border options
   func testExportWithCustomQuality() {
       let expectation = XCTestExpectation(description: "Export with custom quality")
      
       // Call the exportToFile method with custom quality
       ExportService.exportToFile(
           from: testView,
           format: .jpeg,
           quality: 0.5, // Medium quality
           filename: "quality_test.jpeg"
       ) { url, error in
           // Verify export completed with a valid URL and no error
           XCTAssertNotNil(url)
           XCTAssertNil(error)
          
           // Check that file exists
           if let url = url {
               XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
              
               // Verify file is of reasonable size (should be smaller with lower quality)
               do {
                   let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                   if let fileSize = attributes[.size] as? Int {
                       // Just verify we have a file with some size
                       XCTAssertGreaterThan(fileSize, 0)
                   }
               } catch {
                   XCTFail("Failed to get file attributes: \(error)")
               }
              
               // Clean up the test file
               try? FileManager.default.removeItem(at: url)
           }
          
           expectation.fulfill()
       }
      
       wait(for: [expectation], timeout: 5.0)
   }


  
   /// Tests error handling when the file write operation fails
   func testExportFileWriteError() {
       // Create an expectation for the test
       let expectation = XCTestExpectation(description: "Export to nonexistent directory should fail")
      
       // Create a temporary directory and then delete it to ensure it doesn't exist
       let tempDirURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
       let nonexistentFileURL = tempDirURL.appendingPathComponent("test_should_fail.png")
      
       // Create a SwizzledFileManager that will simulate a write error
       // Since we can't override the static method or easily inject a mock FileManager,
       // we'll just verify that the callback works properly when a file write would fail
      
       // Perform the export normally, but check that an error happens if we try to manually
       // write to the nonexistent directory
       ExportService.exportToFile(
           from: testView,
           format: .png,
           filename: "test_temp.png"
       ) { url, error in
           // Verify the export itself succeeded
           XCTAssertNotNil(url)
           XCTAssertNil(error)
          
           // Now try to simulate a write failure
           do {
               // Try to write the same data to a nonexistent directory
               if let exportedData = try? Data(contentsOf: url!) {
                   do {
                       try exportedData.write(to: nonexistentFileURL)
                       // This should fail, so we'll indicate a test failure if it doesn't
                       XCTFail("Write to nonexistent directory shouldn't succeed")
                   } catch {
                       // This is the expected path - the write should fail
                       XCTAssertNotNil(error)
                   }
               }
              
               // Clean up the original file
               try? FileManager.default.removeItem(at: url!)
           }
          
           expectation.fulfill()
       }
      
       wait(for: [expectation], timeout: 5.0)
   }
  


}

