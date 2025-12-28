import SwiftUI
import UniformTypeIdentifiers

/// The main view of the RAW Image Gallery application.
///
/// Displays a toolbar with folder selection, toggle controls for ratings and categories,
/// and a gallery grid of images. Supports full-screen detail view for individual images.
struct ContentView: View {
    @StateObject private var scanner = ImageScanner()
    @EnvironmentObject var ratingStore: RatingStore
    @EnvironmentObject var categoryStore: CategoryStore
    
    @State private var selectedFolder: URL?
    @State private var selectedImage: ImageFile?
    @State private var showingDetailView = false
    @State private var currentImageIndex: Int?
    @State private var showRatings = true
    @State private var showCategories = true
    @State private var showClearRatingsAlert = false
    @State private var showClearCategoriesAlert = false
    
    // Filter State
    @State private var isFilterPresented = false
    @State private var filterRating: Int = 0
    @State private var filterCategories: Set<Int> = []
    
    // Export State
    @State private var isExportPresented = false
    
    // Filtered Images
    private var filteredImages: [ImageFile] {
        if filterRating == 0 && filterCategories.isEmpty {
            return scanner.images
        }
        
        return scanner.images.filter { image in
            // Filter by Rating (Exact match)
            let ratingMatch = filterRating == 0 || ratingStore.getRating(for: image.url) == filterRating
            
            // Filter by Categories (Match ANY selected)
            let imageCategories = categoryStore.getCategories(for: image.url)
            let categoryMatch = filterCategories.isEmpty || !filterCategories.isDisjoint(with: imageCategories)
            
            return ratingMatch && categoryMatch
        }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                toolbar
                Divider()
                // Gallery view
                GalleryView(
                    images: filteredImages,
                    selectedImage: $selectedImage,
                    showRatings: showRatings,
                    showCategories: showCategories
                )
                .focusEffectDisabled()
            }
            
            if showingDetailView, let image = selectedImage, let index = currentImageIndex {
                ImageDetailView(
                    imageFile: image,
                    rating: Binding(
                        get: { ratingStore.getRating(for: image.url) },
                        set: { ratingStore.setRating($0, for: image.url) }
                    ),
                    categories: Binding(
                        get: { categoryStore.getCategories(for: image.url) },
                        set: { categoryStore.setCategories($0, for: image.url) }
                    ),
                    isPresented: $showingDetailView,
                    showRatings: showRatings,
                    showCategories: showCategories,
                    onNavigate: { navigateImage(from: index, direction: $0) }
                )
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .onChange(of: selectedImage) { _, newValue in
            if let image = newValue {
                currentImageIndex = filteredImages.firstIndex(of: image)
                withAnimation(.easeInOut(duration: 0.2)) {
                    showingDetailView = true
                }
            }
        }
        .onChange(of: showingDetailView) { _, isShowing in
            if !isShowing {
                selectedImage = nil
            }
        }
        .alert("Clear All Ratings?", isPresented: $showClearRatingsAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear All", role: .destructive) {
                ratingStore.clearAllRatings()
            }
        } message: {
            Text("This will remove all star ratings from all images. This action cannot be undone.")
        }
        .alert("Clear All Categories?", isPresented: $showClearCategoriesAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear All", role: .destructive) {
                categoryStore.clearAllCategories()
            }
        } message: {
            Text("This will remove all color categories from all images. This action cannot be undone.")
        }
    }
    
    // MARK: - Subviews
    
    private var toolbar: some View {
        HStack(spacing: 16) {
            folderButton
            Spacer()
            toggleButtons
            Spacer()
            actionButtons
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
    
    private var folderButton: some View {
        Button(action: selectFolder) {
            HStack(spacing: 8) {
                Image(systemName: "folder")
                    .font(.title3)
                Text(selectedFolder?.lastPathComponent ?? "Select Folder")
                    .font(.headline)
                    .lineLimit(1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    private var toggleButtons: some View {
        HStack(spacing: 12) {
            ToggleButton(
                title: "Ratings",
                icon: "star",
                isOn: $showRatings,
                accentColor: .blue
            )
            
            ToggleButton(
                title: "Categories",
                icon: "circle",
                isOn: $showCategories,
                accentColor: .purple
            )
        }
    }
    
    private var filterOverlay: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Filter Images")
                .font(.headline)
            
            Divider()
            
            // Rating Filter
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("By Rating")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    if filterRating > 0 {
                        Button("Clear") { filterRating = 0 }
                            .buttonStyle(.link)
                            .font(.caption)
                    }
                }
                
                HStack {
                    StarRatingView(rating: $filterRating, interactive: true, size: 24)
                    if filterRating == 0 {
                        Text("Any")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                    }
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Category Filter
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("By Category")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    if !filterCategories.isEmpty {
                        Button("Clear") { filterCategories.removeAll() }
                            .buttonStyle(.link)
                            .font(.caption)
                    }
                }
                
                HStack {
                    ColorCategoryView(selectedCategories: $filterCategories, interactive: true, size: 24)
                    if filterCategories.isEmpty {
                        Text("Any")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                    }
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            
            if filterRating > 0 || !filterCategories.isEmpty {
                Divider()
                Button(action: {
                    filterRating = 0
                    filterCategories.removeAll()
                    isFilterPresented = false
                }) {
                    Text("Reset All Filters")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(width: 300)
    }
    
    private var exportOverlay: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Export Data")
                .font(.headline)
            
            Text("Export the current list of \(filteredImages.count) images.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
            
            Button(action: exportCSV) {
                HStack {
                    Image(systemName: "tablecells")
                    VStack(alignment: .leading) {
                        Text("Export CSV")
                            .font(.body)
                        Text("Includes Name, Path, Rating, Categories")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            Button(action: exportFilenames) {
                HStack {
                    Image(systemName: "text.alignleft")
                    VStack(alignment: .leading) {
                        Text("Export Filenames")
                            .font(.body)
                        Text("Comma-separated list of filenames")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .frame(width: 300)
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            
            // Export Button
            Button(action: { isExportPresented.toggle() }) {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export")
                }
            }
            .buttonStyle(.bordered)
            .popover(isPresented: $isExportPresented, arrowEdge: .bottom) {
                exportOverlay
            }
            
            // Filter Button
            Button(action: { isFilterPresented.toggle() }) {
                HStack(spacing: 6) {
                    Image(systemName: "line.3.horizontal.decrease.circle" + (filterRating > 0 || !filterCategories.isEmpty ? ".fill" : ""))
                    Text("Filter")
                }
            }
            .buttonStyle(.bordered)
            .tint(filterRating > 0 || !filterCategories.isEmpty ? .accentColor : nil)
            .popover(isPresented: $isFilterPresented, arrowEdge: .bottom) {
                filterOverlay
            }

            Button(action: { showClearRatingsAlert = true }) {
                Label("Clear Ratings", systemImage: "star.slash")
            }
            .buttonStyle(.bordered)
            .disabled(ratingStore.ratings.isEmpty)
            
            Button(action: { showClearCategoriesAlert = true }) {
                Label("Clear Categories", systemImage: "circle.slash")
            }
            .buttonStyle(.bordered)
            .disabled(categoryStore.categories.isEmpty)
            
            Spacer()
            
            if scanner.isScanning {
                ProgressView()
                    .scaleEffect(0.7)
                Text("Scanning...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if !scanner.images.isEmpty {
                Text("\(filteredImages.count) of \(scanner.images.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Actions
    
    /// Presents a folder selection dialog and scans the selected directory for images.
    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select Folder"
        
        if panel.runModal() == .OK, let url = panel.url {
            selectedFolder = url
            Task {
                await scanner.scanDirectory(url)
            }
        }
    }
    
    /// Navigates to the next or previous image in the detail view.
    ///
    /// - Parameters:
    ///   - currentIndex: The index of the currently displayed image.
    ///   - direction: The direction to navigate (previous or next).
    private func navigateImage(from currentIndex: Int, direction: ImageDetailView.Direction) {
        let newIndex: Int
        switch direction {
        case .previous:
            newIndex = max(0, currentIndex - 1)
        case .next:
            newIndex = min(filteredImages.count - 1, currentIndex + 1)
        }
        
        if newIndex != currentIndex {
            currentImageIndex = newIndex
            if showingDetailView {
                selectedImage = filteredImages[newIndex]
            }
        }
    }
    
    // MARK: - Export Logic
    
    private func exportCSV() {
        isExportPresented = false
        
        let header = "Name,Path,Rating,Categories\n"
        let rows = filteredImages.map { image -> String in
            let name = image.url.lastPathComponent
            // Relative path logic
            let path: String
            if let root = selectedFolder {
                path = image.url.path(percentEncoded: false).replacingOccurrences(of: root.path(percentEncoded: false), with: "")
            } else {
                path = image.url.path(percentEncoded: false)
            }
            
            let rating = ratingStore.getRating(for: image.url)
            
            let categories = categoryStore.getCategories(for: image.url)
            let categoryNames = categories.map { id in
                switch id {
                case 1: return "Red"
                case 2: return "Orange"
                case 3: return "Yellow"
                case 4: return "Green"
                case 5: return "Blue"
                default: return "Unknown"
                }
            }.joined(separator: "|")
            
            // Sanitize for CSV (simple quoting if needed, though simpler formats might not need it for typical filenames)
            // But let's be safe if name has comma
            let safeName = name.contains(",") ? "\"\(name)\"" : name
            let safePath = path.contains(",") ? "\"\(path)\"" : path
            
            return "\(safeName),\(safePath),\(rating),\(categoryNames)"
        }.joined(separator: "\n")
        
        let content = header + rows
        saveFile(content: content, defaultName: "swiftcull-export.csv", type: .commaSeparatedText)
    }
    
    private func exportFilenames() {
        isExportPresented = false
        
        let filenames = filteredImages.map { $0.url.lastPathComponent }.joined(separator: ", ")
        saveFile(content: filenames, defaultName: "filenames.txt", type: .plainText)
    }
    
    private func saveFile(content: String, defaultName: String, type: UTType) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [type]
        savePanel.nameFieldStringValue = defaultName
        savePanel.canCreateDirectories = true
        savePanel.title = "Export Data"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try content.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    print("Error saving file: \(error)")
                    // Ideally show an alert here
                }
            }
        }
    }
}

// MARK: - Supporting Views

/// A custom toggle button with icon and accent color.
private struct ToggleButton: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    let accentColor: Color
    
    var body: some View {
        Button(action: { isOn.toggle() }) {
            HStack(spacing: 6) {
                Image(systemName: isOn ? "\(icon).fill" : icon)
                    .font(.body)
                Text(title)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isOn ? accentColor.opacity(0.2) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isOn ? accentColor : Color.gray.opacity(0.3), lineWidth: 1.5)
            )
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}
