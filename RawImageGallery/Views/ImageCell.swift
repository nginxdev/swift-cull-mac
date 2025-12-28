import SwiftUI

/// A thumbnail cell displaying an image with optional rating and category overlays.
///
/// Shows a 200x200 thumbnail with a file type badge and selection indicator.
struct ImageCell: View {
    let imageFile: ImageFile
    @Binding var rating: Int
    @Binding var categories: Set<Int>
    let isSelected: Bool
    let showRatings: Bool
    let showCategories: Bool
    @State private var thumbnail: NSImage?
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                thumbnailView
                overlaysView
            }
            .frame(width: 200, height: 200)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
            )
        }
        .task {
            await loadThumbnail()
        }
    }
    
    // MARK: - Subviews
    
    private var thumbnailView: some View {
        ZStack {
            if let thumbnail = thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 200, height: 200)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 200, height: 200)
                    .overlay {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                    }
            }
            
            typeBadge
        }
        .contentShape(Rectangle())
    }
    
    private var typeBadge: some View {
        VStack {
            HStack {
                Text(imageFile.type.rawValue)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.ultraThinMaterial)
                    .cornerRadius(4)
                Spacer()
            }
            Spacer()
        }
        .padding(6)
    }
    
    private var overlaysView: some View {
        VStack(spacing: 4) {
            if showRatings {
                ratingOverlay
            }
            if showCategories {
                categoryOverlay
            }
        }
        .padding(6)
    }
    
    private var ratingOverlay: some View {
        HStack(spacing: 6) {
            StarRatingView(rating: $rating, interactive: true, size: 14)
            
            if rating > 0 {
                Button(action: { rating = 0 }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(6)
    }
    
    private var categoryOverlay: some View {
        HStack(spacing: 6) {
            ColorCategoryView(selectedCategories: $categories, interactive: true, size: 14)
            
            if !categories.isEmpty {
                Button(action: { categories.removeAll() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(6)
    }
    
    // MARK: - Actions
    
    /// Loads the thumbnail image asynchronously.
    private func loadThumbnail() async {
        isLoading = true
        thumbnail = await RawImageLoader.shared.loadThumbnail(for: imageFile.url)
        isLoading = false
    }
}
