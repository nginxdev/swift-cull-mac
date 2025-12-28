import Foundation
import AppKit
import ImageIO
import UniformTypeIdentifiers

/// Handles asynchronous loading of images with caching support.
///
/// Provides thumbnail generation and full-resolution image loading for both
/// standard image formats and RAW files using Core Graphics Image I/O.
class RawImageLoader: ObservableObject {
    static let shared = RawImageLoader()
    
    private let thumbnailCache = NSCache<NSURL, NSImage>()
    private let thumbnailSize: CGFloat = 300
    
    init() {
        thumbnailCache.countLimit = 200
        thumbnailCache.totalCostLimit = 100 * 1024 * 1024
    }
    
    // MARK: - Public Methods
    
    /// Loads a thumbnail image asynchronously.
    ///
    /// Thumbnails are cached for performance. The maximum size is 300 pixels.
    ///
    /// - Parameter url: The image file URL.
    /// - Returns: The thumbnail image, or nil if loading failed.
    func loadThumbnail(for url: URL) async -> NSImage? {
        if let cached = thumbnailCache.object(forKey: url as NSURL) {
            return cached
        }
        
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }
        
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: thumbnailSize
        ]
        
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
            return nil
        }
        
        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        thumbnailCache.setObject(nsImage, forKey: url as NSURL)
        
        return nsImage
    }
    
    /// Loads a full-resolution image asynchronously.
    ///
    /// - Parameter url: The image file URL.
    /// - Returns: The full-resolution image, or nil if loading failed.
    func loadFullImage(for url: URL) async -> NSImage? {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }
        
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: true,
            kCGImageSourceShouldAllowFloat: true
        ]
        
        guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, options as CFDictionary) else {
            return nil
        }
        
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }
    
    /// Clears the thumbnail cache.
    func clearCache() {
        thumbnailCache.removeAllObjects()
    }
}
