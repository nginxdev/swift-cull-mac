import SwiftUI

/// A grid view displaying thumbnail images with rating and category overlays.
///
/// Supports keyboard navigation, single-click selection, and double-click to open detail view.
struct GalleryView: View {
    @ObservedObject var scanner: ImageScanner
    @EnvironmentObject var ratingStore: RatingStore
    @EnvironmentObject var categoryStore: CategoryStore
    @Binding var selectedImage: ImageFile?
    @State private var selectedIndex: Int?
    let showRatings: Bool
    let showCategories: Bool
    @FocusState private var isFocused: Bool
    
    private let columns = [
        GridItem(.adaptive(minimum: 200, maximum: 200), spacing: 16)
    ]
    
    private var columnsPerRow: Int { 4 }
    
    var body: some View {
        ScrollView {
            if scanner.images.isEmpty {
                emptyStateView
            } else {
                imageGrid
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .focusable()
        .focused($isFocused)
        .onAppear {
            isFocused = true
        }
        .onKeyPress(.upArrow) { moveSelection(by: -columnsPerRow) }
        .onKeyPress(.downArrow) { moveSelection(by: columnsPerRow) }
        .onKeyPress(.leftArrow) { moveSelection(by: -1) }
        .onKeyPress(.rightArrow) { moveSelection(by: 1) }
        .onKeyPress("0") { setRatingForSelected(0) }
        .onKeyPress("1") { setRatingForSelected(1) }
        .onKeyPress("2") { setRatingForSelected(2) }
        .onKeyPress("3") { setRatingForSelected(3) }
        .onKeyPress("4") { setRatingForSelected(4) }
        .onKeyPress("5") { setRatingForSelected(5) }
        .onKeyPress(.space) {
            if let index = selectedIndex {
                selectedImage = scanner.images[index]
            }
            return .handled
        }
    }
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            Text("No images found")
                .font(.title2)
                .foregroundColor(.secondary)
            Text("Select a folder to view images")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    private var imageGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(Array(scanner.images.enumerated()), id: \.element.id) { index, imageFile in
                ImageCell(
                    imageFile: imageFile,
                    rating: Binding(
                        get: { ratingStore.getRating(for: imageFile.url) },
                        set: { ratingStore.setRating($0, for: imageFile.url) }
                    ),
                    categories: Binding(
                        get: { categoryStore.getCategories(for: imageFile.url) },
                        set: { categoryStore.setCategories($0, for: imageFile.url) }
                    ),
                    isSelected: selectedIndex == index,
                    showRatings: showRatings,
                    showCategories: showCategories
                )
                .simultaneousGesture(
                    TapGesture(count: 2)
                        .onEnded {
                            selectedImage = imageFile
                        }
                )
                .simultaneousGesture(
                    TapGesture(count: 1)
                        .onEnded {
                            selectedIndex = index
                        }
                )
            }
        }
        .padding(16)
    }
    
    // MARK: - Actions
    
    /// Moves the selection by the specified offset.
    ///
    /// - Parameter offset: The number of positions to move (negative for backwards).
    /// - Returns: A key press result indicating the key was handled.
    private func moveSelection(by offset: Int) -> KeyPress.Result {
        guard !scanner.images.isEmpty else { return .handled }
        
        if let current = selectedIndex {
            let newIndex = max(0, min(scanner.images.count - 1, current + offset))
            selectedIndex = newIndex
        } else {
            selectedIndex = 0
        }
        return .handled
    }
    
    /// Sets the rating for the currently selected image.
    ///
    /// - Parameter rating: The rating value to set (0-5).
    /// - Returns: A key press result indicating the key was handled.
    private func setRatingForSelected(_ rating: Int) -> KeyPress.Result {
        guard let index = selectedIndex else { return .handled }
        let imageFile = scanner.images[index]
        ratingStore.setRating(rating, for: imageFile.url)
        return .handled
    }
}
