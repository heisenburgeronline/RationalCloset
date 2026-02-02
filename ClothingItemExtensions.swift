import UIKit
import SwiftUI

// MARK: - ClothingItem Image Helpers

extension ClothingItem {
    
    /// Loads images from filesystem (new method)
    /// Returns array of UIImages loaded from disk
    var loadedImages: [UIImage] {
        return imageFilenames.compactMap { filename in
            ImageManager.shared.loadImage(filename: filename)
        }
    }
    
    /// Gets the first image (most common use case)
    var firstImage: UIImage? {
        guard let firstFilename = imageFilenames.first else {
            return nil
        }
        return ImageManager.shared.loadImage(filename: firstFilename)
    }
    
    /// Legacy support: Load from Data if filenames not available (during migration)
    var firstImageData: Data? {
        if !imageFilenames.isEmpty {
            // New method: Load from filesystem
            if let image = firstImage {
                return image.jpegData(compressionQuality: 1.0)
            }
            return nil
        } else {
            // Legacy fallback
            return imagesData.first
        }
    }
    
    /// Check if item has any images
    var hasImages: Bool {
        return !imageFilenames.isEmpty || !imagesData.isEmpty
    }
    
    /// Get image count
    var imageCount: Int {
        return !imageFilenames.isEmpty ? imageFilenames.count : imagesData.count
    }
}
