import UIKit
import Foundation

/// Manages image storage to filesystem to prevent memory crashes
/// Images are compressed, resized, and stored in Documents directory
class ImageManager {
    
    static let shared = ImageManager()
    
    private let fileManager = FileManager.default
    private let imagesDirectory: URL
    
    private init() {
        // Create Images directory in Documents
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        imagesDirectory = documentsPath.appendingPathComponent("ClothingImages", isDirectory: true)
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: imagesDirectory.path) {
            try? fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - Save Image
    
    /// Saves an image to disk with compression and resizing
    /// - Parameter image: UIImage to save
    /// - Returns: Filename (UUID string) or nil if failed
    func saveImage(_ image: UIImage) -> String? {
        // Generate unique filename
        let filename = UUID().uuidString + ".jpg"
        let fileURL = imagesDirectory.appendingPathComponent(filename)
        
        // Resize image to max 1024px on longest side
        let resizedImage = resizeImage(image, maxDimension: 1024)
        
        // Compress to JPEG with 0.7 quality (~200KB target)
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.7) else {
            print("❌ Failed to compress image")
            return nil
        }
        
        // Write to disk
        do {
            try imageData.write(to: fileURL)
            print("✅ Saved image: \(filename) (\(imageData.count / 1024)KB)")
            return filename
        } catch {
            print("❌ Failed to save image: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Load Image
    
    /// Loads an image from disk
    /// - Parameter filename: The filename to load
    /// - Returns: UIImage or nil if not found
    func loadImage(filename: String) -> UIImage? {
        let fileURL = imagesDirectory.appendingPathComponent(filename)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("⚠️ Image not found: \(filename)")
            return nil
        }
        
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            print("❌ Failed to load image: \(filename)")
            return nil
        }
        
        return image
    }
    
    // MARK: - Delete Image
    
    /// Deletes an image from disk
    /// - Parameter filename: The filename to delete
    func deleteImage(filename: String) {
        let fileURL = imagesDirectory.appendingPathComponent(filename)
        
        if fileManager.fileExists(atPath: fileURL.path) {
            try? fileManager.removeItem(at: fileURL)
            print("🗑️ Deleted image: \(filename)")
        }
    }
    
    // MARK: - Helper: Resize Image
    
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        
        // If already smaller, return original
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        let aspectRatio = size.width / size.height
        var newSize: CGSize
        
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        // Render resized image
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    // MARK: - Migration: Convert Data to File
    
    /// Migrates existing Data to filesystem
    /// - Parameter imageData: Raw image Data
    /// - Returns: Filename or nil if failed
    func migrateDataToFile(_ imageData: Data) -> String? {
        guard let image = UIImage(data: imageData) else {
            print("❌ Failed to create UIImage from Data")
            return nil
        }
        
        return saveImage(image)
    }
    
    // MARK: - Debug: Get Storage Info
    
    func getStorageInfo() -> (count: Int, totalSizeKB: Int) {
        guard let files = try? fileManager.contentsOfDirectory(at: imagesDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return (0, 0)
        }
        
        let totalSize = files.compactMap { url -> Int? in
            try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize
        }.reduce(0, +)
        
        return (count: files.count, totalSizeKB: totalSize / 1024)
    }
}
