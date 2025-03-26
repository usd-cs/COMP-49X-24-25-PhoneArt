//
//  ExportService.swift
//  COMP-49X-24-25-PhoneArt
//
//  Created by Noah Huang on 3/25/25.
//


//
//  ExportService.swift
//  COMP-49X-24-25-PhoneArt
//
//  Created by Noah Huang on 3/25/25.
//

import UIKit
import Photos
import CoreGraphics


/// Service for exporting artwork with different format options and quality settings
class ExportService {
  
   /// Supported export formats
   enum ExportFormat: String, CaseIterable, Identifiable {
       case png
       case jpeg
      
       var id: String { self.rawValue }
      
       var mimeType: String {
           switch self {
           case .png:
               return "image/png"
           case .jpeg:
               return "image/jpeg"
           }
       }
      
       var fileExtension: String {
           self.rawValue
       }
   }
  
   /// Export artwork as an image to the device's photo library
   /// - Parameters:
   ///   - view: The view to export as an image
   ///   - exportRect: Optional specific rectangle to export (nil means use the entire view bounds)
   ///   - format: Export format (PNG, JPEG)
   ///   - quality: Image quality (0.0 to 1.0, only applicable for JPEG)
   ///   - filename: Optional filename for the exported image
   ///   - includeBorder: Whether to include the border in the exported image
   ///   - completion: Completion handler with success flag and optional error
   static func exportToPhotoLibrary(
       from view: UIView,
       exportRect: CGRect? = nil,
       format: ExportFormat = .png,
       quality: CGFloat = 0.9,
       filename: String? = nil,
       includeBorder: Bool = true,
       completion: @escaping (Bool, Error?) -> Void
   ) {
       // Ensure we're on the main thread to check permissions
       if !Thread.isMainThread {
           DispatchQueue.main.async {
               self.exportToPhotoLibrary(from: view, exportRect: exportRect, format: format, quality: quality, filename: filename, includeBorder: includeBorder, completion: completion)
           }
           return
       }
      
       // Check photo library permission
       let status = PHPhotoLibrary.authorizationStatus()
      
       switch status {
       case .notDetermined:
           PHPhotoLibrary.requestAuthorization { newStatus in
               if newStatus == .authorized {
                   // We're already on the main thread here
                   self.performExport(from: view, exportRect: exportRect, format: format, quality: quality, filename: filename, includeBorder: includeBorder, completion: completion)
               } else {
                   DispatchQueue.main.async {
                       completion(false, NSError(domain: "com.phoneart.export", code: 403, userInfo: [NSLocalizedDescriptionKey: "Photo library access denied"]))
                   }
               }
           }
       case .authorized:
           // We're already on the main thread here
           self.performExport(from: view, exportRect: exportRect, format: format, quality: quality, filename: filename, includeBorder: includeBorder, completion: completion)
       default:
           completion(false, NSError(domain: "com.phoneart.export", code: 403, userInfo: [NSLocalizedDescriptionKey: "Photo library access denied"]))
       }
   }
  
   /// Performs the actual export
   private static func performExport(
       from view: UIView,
       exportRect: CGRect? = nil,
       format: ExportFormat = .png,
       quality: CGFloat = 0.9,
       filename: String? = nil,
       includeBorder: Bool = true,
       completion: @escaping (Bool, Error?) -> Void
   ) {
       // We need to ensure all UIKit operations occur on the main thread
       if !Thread.isMainThread {
           DispatchQueue.main.async {
               self.performExport(from: view, exportRect: exportRect, format: format, quality: quality, filename: filename, includeBorder: includeBorder, completion: completion)
           }
           return
       }
      
       // Now we're definitely on the main thread for UIKit operations
      
       // Determine the bounds to render
       let renderBounds = exportRect ?? view.bounds
      
       // Create a renderer with the specified bounds
       let renderer = UIGraphicsImageRenderer(bounds: renderBounds)
      
       // Create the image (we're now on the main thread)
       let image = renderer.image { ctx in
           // If we're capturing a specific rect, we need to adjust the context
           if exportRect != nil {
               // Translate the context to the origin of the exportRect
               ctx.cgContext.translateBy(x: -renderBounds.origin.x, y: -renderBounds.origin.y)
           }
          
           // Draw the view hierarchy, optionally excluding the border
           if !includeBorder {
               // Clip to the specified bounds
               ctx.cgContext.addRect(renderBounds)
               ctx.cgContext.clip()
           }
          
           view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
       }
      
       // Convert to data
       var data: Data?
       var metadata: [String: Any]?
      
       switch format {
       case .png:
           data = image.pngData()
       case .jpeg:
           data = image.jpegData(compressionQuality: quality)
           metadata = [kCGImagePropertyExifDictionary as String: [kCGImagePropertyExifUserComment as String: "Created with PhoneArt"]]
       }
      
       guard let imageData = data else {
           completion(false, NSError(domain: "com.phoneart.export", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to create image data"]))
           return
       }
      
       // Save to photo library (this can run on a background thread)
       PHPhotoLibrary.shared().performChanges {
           let creationRequest = PHAssetCreationRequest.forAsset()
          
           let options = PHAssetResourceCreationOptions()
           if metadata != nil {
               options.uniformTypeIdentifier = format == .png ? "public.png" : "public.jpeg"
               options.originalFilename = filename ?? "PhoneArt_\(Date().timeIntervalSince1970).\(format.fileExtension)"
               creationRequest.addResource(with: .photo, data: imageData, options: options)
           } else {
               creationRequest.addResource(with: .photo, data: imageData, options: options)
           }
       } completionHandler: { success, error in
           DispatchQueue.main.async {
               completion(success, error)
           }
       }
   }
  
   /// Export artwork as an image to a file
   /// - Parameters:
   ///   - view: The view to export as an image
   ///   - format: Export format (PNG, JPEG)
   ///   - quality: Image quality (0.0 to 1.0, only applicable for JPEG)
   ///   - filename: Optional filename for the exported image
   ///   - completion: Completion handler with URL to the saved file or error
   static func exportToFile(
       from view: UIView,
       format: ExportFormat = .png,
       quality: CGFloat = 0.9,
       filename: String? = nil,
       completion: @escaping (URL?, Error?) -> Void
   ) {
       // Create a renderer with the view's bounds
       let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
      
       // Create the image
       let image = renderer.image { ctx in
           view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
       }
      
       // Convert to data
       var data: Data?
      
       switch format {
       case .png:
           data = image.pngData()
       case .jpeg:
           data = image.jpegData(compressionQuality: quality)
       }
      
       guard let imageData = data else {
           completion(nil, NSError(domain: "com.phoneart.export", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to create image data"]))
           return
       }
      
       // Get the documents directory
       guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
           completion(nil, NSError(domain: "com.phoneart.export", code: 500, userInfo: [NSLocalizedDescriptionKey: "Could not access documents directory"]))
           return
       }
      
       // Create a file URL
       let fileURL = documentsDirectory.appendingPathComponent(
           filename ?? "PhoneArt_\(Date().timeIntervalSince1970).\(format.fileExtension)"
       )
      
       // Write to file
       do {
           try imageData.write(to: fileURL)
           completion(fileURL, nil)
       } catch {
           completion(nil, error)
       }
   }
}
