# SwiftCull

A fast, elegant macOS application for culling and organizing photo collections. Built with SwiftUI and optimized for photographers who need to quickly review, rate, and categorize large batches of images.

## Features

### 🎯 Efficient Photo Culling
- **Keyboard-First Workflow** - Navigate and rate images without touching the mouse
- **RAW Format Support** - Native support for CR2, CR3, NEF, ARW, DNG, and 20+ RAW formats
- **Smart File Handling** - Automatically prefers RAW over JPEG when both exist

### ⭐ Rating System
- **5-Star Ratings** - Quick image quality assessment
- **Keyboard Shortcuts** - Press 0-5 to rate instantly
- **Persistent Storage** - Ratings saved in local SQLite database

### 🎨 Color Categories
- **5 Color Categories** - Organize images by type, subject, or workflow
- **Multiple Selection** - Assign multiple categories per image
- **Visual Indicators** - Quick visual feedback with color-coded circles

### ⚡ Performance
- **Thumbnail Caching** - Fast scrolling through large collections
- **Async Loading** - Non-blocking image processing
- **Optimized Rendering** - Smooth 60fps interface

### 🎨 Modern UI
- **Finder-Like Experience** - Single-click select, double-click open
- **Full-Screen Preview** - Distraction-free image viewing
- **Frosted Glass Design** - Beautiful, native macOS aesthetics

## Keyboard Shortcuts

### Gallery View
- **Arrow Keys** - Navigate selection (Finder-style grid navigation)
- **0-5** - Rate selected image
- **Space/Enter** - Open preview
- **Double-Click** - Open preview

### Preview Mode
- **←→** - Navigate between images
- **0-5** - Rate current image
- **Escape** - Close preview
- **Swipe** - Navigate with trackpad

## Requirements

- macOS 14.0 (Sonoma) or later
- Swift 5.9+

## Installation

### Build from Source

```bash
git clone https://github.com/yourusername/swift-cull-mac.git
cd swift-cull-mac
swift build -c release
.build/release/SwiftCull
```

## Usage

1. **Select a Folder** - Click the folder button to choose your image directory
2. **Review Images** - Use arrow keys to navigate through thumbnails
3. **Rate & Categorize** - Press 0-5 for ratings, click color circles for categories
4. **Preview** - Double-click or press Space/Enter for full-screen view

## Architecture

SwiftCull follows Apple's coding standards and best practices:

- **SwiftUI** - Modern declarative UI framework
- **Async/Await** - Concurrent image loading
- **SQLite** - Persistent local storage
- **Core Graphics** - Native RAW image decoding
- **MVVM Pattern** - Clean separation of concerns

### Project Structure

```
RawImageGallery/
├── Models/          # Data models and stores
│   ├── ImageFile.swift
│   ├── ImageScanner.swift
│   ├── RatingStore.swift
│   └── CategoryStore.swift
├── Views/           # SwiftUI views
│   ├── ContentView.swift
│   ├── GalleryView.swift
│   ├── ImageDetailView.swift
│   ├── ImageCell.swift
│   ├── ColorCategoryView.swift
│   └── StarRatingView.swift
└── Services/        # Utilities
    └── RawImageLoader.swift
```

## Supported Formats

### Standard Formats
- JPEG (.jpg, .jpeg)
- PNG (.png)
- HEIC/HEIF (.heic, .heif)
- TIFF (.tif, .tiff)

### RAW Formats
- Canon (.cr2, .cr3)
- Nikon (.nef)
- Sony (.arw)
- Adobe (.dng)
- Fujifilm (.raf)
- Olympus (.orf)
- Panasonic (.rw2)
- And 15+ more camera formats

## License

MIT License - See LICENSE file for details

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Author

Built with ❤️ for photographers who value speed and efficiency.
