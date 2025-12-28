import SwiftUI

/// A view displaying five color-coded category circles for image categorization.
///
/// Supports multiple category selection with visual feedback.
struct ColorCategoryView: View {
    @Binding var selectedCategories: Set<Int>
    let interactive: Bool
    let size: CGFloat
    
    private let colors: [Color] = [.red, .blue, .green, .yellow, .purple]
    
    init(selectedCategories: Binding<Set<Int>>, interactive: Bool = true, size: CGFloat = 20) {
        self._selectedCategories = selectedCategories
        self.interactive = interactive
        self.size = size
    }
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<5, id: \.self) { index in
                categoryCircle(at: index)
            }
        }
    }
    
    // MARK: - Subviews
    
    /// Creates a category circle for the specified index.
    ///
    /// - Parameter index: The category index (0-4).
    /// - Returns: A view representing the category circle.
    private func categoryCircle(at index: Int) -> some View {
        Circle()
            .fill(colors[index])
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: selectedCategories.contains(index) ? 2 : 0)
            )
            .overlay(
                Circle()
                    .stroke(Color.black.opacity(0.3), lineWidth: 1)
            )
            .opacity(selectedCategories.contains(index) ? 1.0 : 0.5)
            .onTapGesture {
                toggleCategory(at: index)
            }
    }
    
    // MARK: - Actions
    
    /// Toggles the selection state of a category.
    ///
    /// - Parameter index: The category index to toggle.
    private func toggleCategory(at index: Int) {
        guard interactive else { return }
        
        if selectedCategories.contains(index) {
            selectedCategories.remove(index)
        } else {
            selectedCategories.insert(index)
        }
    }
}
