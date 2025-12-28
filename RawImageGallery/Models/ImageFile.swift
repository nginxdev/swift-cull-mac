import Foundation

/// Represents an image file with metadata.
struct ImageFile: Identifiable, Equatable, Hashable {
    let id = UUID()
    let url: URL
    let fileName: String
    let type: ImageType
    let fileSize: Int64?
    
    enum ImageType: String {
        case raw = "RAW"
        case jpeg = "JPEG"
        case png = "PNG"
        case heic = "HEIC"
        case tiff = "TIFF"
        case other = "OTHER"
    }
    
    /// Creates an image file from a URL.
    ///
    /// - Parameter url: The file URL.
    init(url: URL) {
        self.url = url
        self.fileName = url.lastPathComponent
        self.type = Self.detectImageType(from: url)
        self.fileSize = Self.getFileSize(for: url)
    }
    
    // MARK: - Helper Methods
    
    /// Detects the image type from a file URL.
    ///
    /// - Parameter url: The file URL.
    /// - Returns: The detected image type.
    private static func detectImageType(from url: URL) -> ImageType {
        let ext = url.pathExtension.lowercased()
        
        switch ext {
        case "cr2", "cr3", "nef", "arw", "dng", "raf", "orf", "rw2", "raw":
            return .raw
        case "jpg", "jpeg":
            return .jpeg
        case "png":
            return .png
        case "heic", "heif":
            return .heic
        case "tif", "tiff":
            return .tiff
        default:
            return .other
        }
    }
    
    /// Gets the file size for a URL.
    ///
    /// - Parameter url: The file URL.
    /// - Returns: The file size in bytes, or nil if unavailable.
    private static func getFileSize(for url: URL) -> Int64? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? Int64 else {
            return nil
        }
        return size
    }
    
    // MARK: - Equatable
    
    static func == (lhs: ImageFile, rhs: ImageFile) -> Bool {
        lhs.url == rhs.url
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
}
