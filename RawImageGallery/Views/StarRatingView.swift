import SwiftUI

/// A view displaying a 5-star rating system with optional interactivity.
///
/// Supports both display-only and interactive modes for rating images.
struct StarRatingView: View {
    @Binding var rating: Int
    let interactive: Bool
    let size: CGFloat
    
    init(rating: Binding<Int>, interactive: Bool = true, size: CGFloat = 20) {
        self._rating = rating
        self.interactive = interactive
        self.size = size
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { index in
                star(at: index)
            }
        }
    }
    
    // MARK: - Subviews
    
    /// Creates a star icon for the specified index.
    ///
    /// - Parameter index: The star index (1-5).
    /// - Returns: A view representing the star.
    private func star(at index: Int) -> some View {
        Image(systemName: index <= rating ? "star.fill" : "star")
            .font(.system(size: size))
            .foregroundColor(index <= rating ? .yellow : .gray)
            .onTapGesture {
                if interactive {
                    rating = index
                }
            }
    }
}
