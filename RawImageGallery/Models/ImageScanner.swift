import Foundation
import UniformTypeIdentifiers
import ImageIO

/// Scans directories for image files and manages the image collection.
///
/// Supports both standard image formats (JPEG, PNG, HEIC) and RAW formats from various cameras.
/// When both RAW and JPEG versions exist, prefers the RAW file.
class ImageScanner: ObservableObject {
    @Published var images: [ImageFile] = []
    @Published var isScanning = false
    @Published var progress: Double = 0.0
    @Published var currentFolder: URL?
    
    private let imageExtensions = ["jpg", "jpeg", "png", "heic", "heif", "tif", "tiff"]
    private let rawExtensions = [
        "cr2", "cr3", "nef", "arw", "dng", "raf", "orf", "rw2",
        "pef", "srw", "nrw", "raw", "rwl", "iiq", "3fr", "fff",
        "dcr", "kdc", "erf", "mef", "mos", "mrw", "ptx", "r3d"
    ]
    
    // MARK: - Public Methods
    
    /// Scans a directory recursively for image files.
    ///
    /// - Parameter url: The directory URL to scan.
    func scanDirectory(_ url: URL) async {
        await MainActor.run {
            isScanning = true
            progress = 0.0
            images = []
            currentFolder = url
        }
        
        let foundFiles = findImageFiles(in: url)
        let fileGroups = groupFilesByBaseName(foundFiles)
        let processedImages = selectPreferredFiles(from: fileGroups)
        let sortedImages = sortByModificationDate(processedImages)
        
        await MainActor.run {
            self.images = sortedImages
            self.isScanning = false
            self.progress = 1.0
        }
    }
    
    // MARK: - Private Methods
    
    /// Finds all image files in a directory recursively.
    ///
    /// - Parameter url: The directory URL to search.
    /// - Returns: An array of image file URLs.
    private func findImageFiles(in url: URL) -> [URL] {
        var foundFiles: [URL] = []
        
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey, .typeIdentifierKey],
            options: [.skipsHiddenFiles]
        ) else {
            return foundFiles
        }
        
        for case let fileURL as URL in enumerator {
            let ext = fileURL.pathExtension.lowercased()
            if imageExtensions.contains(ext) || rawExtensions.contains(ext) {
                foundFiles.append(fileURL)
            }
        }
        
        return foundFiles
    }
    
    /// Groups files by their base name (without extension).
    ///
    /// - Parameter files: The array of file URLs.
    /// - Returns: A dictionary mapping base names to file URL arrays.
    private func groupFilesByBaseName(_ files: [URL]) -> [String: [URL]] {
        var fileGroups: [String: [URL]] = [:]
        
        for fileURL in files {
            let baseName = fileURL.deletingPathExtension().lastPathComponent
            let directory = fileURL.deletingLastPathComponent().path
            let key = "\(directory)/\(baseName)"
            fileGroups[key, default: []].append(fileURL)
        }
        
        return fileGroups
    }
    
    /// Selects the preferred file from each group (RAW over JPEG).
    ///
    /// - Parameter groups: The file groups dictionary.
    /// - Returns: An array of ImageFile objects.
    private func selectPreferredFiles(from groups: [String: [URL]]) -> [ImageFile] {
        var processedImages: [ImageFile] = []
        
        for (_, urls) in groups {
            let rawFile = urls.first { url in
                rawExtensions.contains(url.pathExtension.lowercased())
            }
            
            let selectedURL = rawFile ?? urls.first!
            processedImages.append(ImageFile(url: selectedURL))
        }
        
        return processedImages
    }
    
    /// Sorts images by modification date (newest first).
    ///
    /// - Parameter images: The array of images to sort.
    /// - Returns: A sorted array of images.
    private func sortByModificationDate(_ images: [ImageFile]) -> [ImageFile] {
        images.sorted { file1, file2 in
            guard let date1 = getModificationDate(for: file1.url),
                  let date2 = getModificationDate(for: file2.url) else {
                return false
            }
            return date1 > date2
        }
    }
    
    /// Gets the modification date for a file URL.
    ///
    /// - Parameter url: The file URL.
    /// - Returns: The modification date, or nil if unavailable.
    private func getModificationDate(for url: URL) -> Date? {
        try? FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate] as? Date
    }
}
