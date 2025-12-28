import SwiftUI

/// A full-screen view for displaying and interacting with a single image.
///
/// Provides navigation controls, rating and category assignment, and keyboard shortcuts
/// for efficient image management.
struct ImageDetailView: View {
    let imageFile: ImageFile
    @Binding var rating: Int
    @Binding var categories: Set<Int>
    @Binding var isPresented: Bool
    let showRatings: Bool
    let showCategories: Bool
    let onNavigate: (Direction) -> Void
    
    @State private var fullImage: NSImage?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @FocusState private var isFocused: Bool
    
    enum Direction {
        case previous, next
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95)
                .ignoresSafeArea()
                .onTapGesture {
                    isFocused = true
                }
            
            VStack(spacing: 0) {
                topToolbar
                imageViewer
                bottomToolbar
            }
        }
        .focusable()
        .focused($isFocused)
        .task {
            await loadFullImage()
            restoreFocus(after: 0.2)
        }
        .onChange(of: imageFile.url) { _, _ in
            Task {
                await loadFullImage()
                restoreFocus(after: 0.2)
            }
        }
        .onAppear {
            restoreFocus(after: 0.1)
        }
        .onKeyPress(.escape) {
            isPresented = false
            return .handled
        }
        .onKeyPress(.leftArrow) {
            navigateAndRestoreFocus(.previous)
            return .handled
        }
        .onKeyPress(.rightArrow) {
            navigateAndRestoreFocus(.next)
            return .handled
        }
        .onKeyPress("0") { setRating(0) }
        .onKeyPress("1") { setRating(1) }
        .onKeyPress("2") { setRating(2) }
        .onKeyPress("3") { setRating(3) }
        .onKeyPress("4") { setRating(4) }
        .onKeyPress("5") { setRating(5) }
    }
    
    // MARK: - Subviews
    
    private var topToolbar: some View {
        HStack {
            Text(imageFile.fileName)
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            if let fileSize = imageFile.fileSize {
                Text(formatFileSize(fileSize))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(.ultraThinMaterial.opacity(0.5))
    }
    
    private var imageViewer: some View {
        ZStack {
            if let fullImage = fullImage {
                Image(nsImage: fullImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if isLoading {
                loadingView
            } else if let error = errorMessage {
                errorView(message: error)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.width > 0 {
                        navigateAndRestoreFocus(.previous)
                    } else if value.translation.width < 0 {
                        navigateAndRestoreFocus(.next)
                    }
                }
        )
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            Text("Loading image...")
                .foregroundColor(.white)
                .font(.caption)
        }
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.yellow)
            Text("Failed to load image")
                .font(.headline)
                .foregroundColor(.white)
            Text(message)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    private var bottomToolbar: some View {
        HStack {
            navigationButton(direction: .previous, icon: "chevron.left.circle.fill")
            Spacer()
            controlsSection
            Spacer()
            navigationButton(direction: .next, icon: "chevron.right.circle.fill")
        }
        .padding()
        .background(.ultraThinMaterial.opacity(0.5))
    }
    
    private var controlsSection: some View {
        HStack(spacing: 16) {
            if showRatings {
                ratingControl
            }
            if showCategories {
                categoryControl
            }
        }
    }
    
    private var ratingControl: some View {
        HStack(spacing: 12) {
            StarRatingView(rating: $rating, interactive: true, size: 28)
            
            if rating > 0 {
                Button(action: { rating = 0 }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help("Clear rating")
            }
        }
        .frame(height: 56)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
    
    private var categoryControl: some View {
        HStack(spacing: 12) {
            ColorCategoryView(selectedCategories: $categories, interactive: true, size: 28)
            
            if !categories.isEmpty {
                Button(action: { categories.removeAll() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help("Clear categories")
            }
        }
        .frame(height: 56)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
    
    private func navigationButton(direction: Direction, icon: String) -> some View {
        Button(action: {
            navigateAndRestoreFocus(direction)
        }) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundColor(.white.opacity(0.8))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Actions
    
    /// Loads the full-resolution image asynchronously.
    private func loadFullImage() async {
        isLoading = true
        errorMessage = nil
        fullImage = nil
        
        guard FileManager.default.fileExists(atPath: imageFile.url.path) else {
            errorMessage = "File not found: \(imageFile.url.path)"
            isLoading = false
            return
        }
        
        fullImage = await RawImageLoader.shared.loadFullImage(for: imageFile.url)
        
        if fullImage == nil {
            errorMessage = "Unable to decode image. Format may not be supported."
        }
        
        isLoading = false
    }
    
    /// Navigates to the specified direction and restores keyboard focus.
    ///
    /// - Parameter direction: The direction to navigate (previous or next).
    private func navigateAndRestoreFocus(_ direction: Direction) {
        onNavigate(direction)
        isFocused = false
        restoreFocus(after: 0.05)
    }
    
    /// Restores keyboard focus after a delay.
    ///
    /// - Parameter delay: The delay in seconds before restoring focus.
    private func restoreFocus(after delay: Double) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            isFocused = true
        }
    }
    
    /// Sets the rating and returns the appropriate key press result.
    ///
    /// - Parameter value: The rating value to set (0-5).
    /// - Returns: A key press result indicating the key was handled.
    private func setRating(_ value: Int) -> KeyPress.Result {
        rating = value
        return .handled
    }
    
    /// Formats a file size in bytes to a human-readable string.
    ///
    /// - Parameter bytes: The file size in bytes.
    /// - Returns: A formatted string (e.g., "2.5 MB").
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
