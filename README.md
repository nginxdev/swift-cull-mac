# SwiftCull

A lightning-fast, native macOS application for culling and rating photos. Built with SwiftUI for photographers who need to quickly sort through thousands of RAW captured images.

![macOS](https://img.shields.io/badge/macOS-14.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

---

## 📸 App
![SwiftCull App](resources/app-screenshot.png)

---

## ✨ Features

### 🚀 **High Performance**
- **RAW Support**: Native support for 25+ RAW formats (ARW, CR2, NEF, RAF, etc.)
- **Instant Preview**: Fast loading of high-resolution embedded previews
- **Zero Latency**: Keyboard-driven workflow designed for speed
- **Efficient**: Multi-threaded image processing and caching

### 🔍 **Smart Filtering**
- **Rating System**: Industry-standard 0-5 star rating workflow
- **Color Labels**: Organize with 5 color-coded categories
- **Advanced Filters**: View only images matching specific ratings or labels
- **Filter Overlay**: Quick access to active filter controls

### 💎 **Modern Experience**
- **Native UI**: Built with SwiftUI for a seamless macOS experience
- **Dark Mode**: Optimized dark interface for photo viewing
- **Keyboard First**: Every action has a keyboard shortcut
- **Gesture Support**: Trackpad navigation and interactions

---

## 🛠️ System Requirements
- **macOS**: 14.0 (Sonoma) or later
- **Architecture**: Apple Silicon (M1/M2/M3) or Intel
- **Disk Space**: ~20 MB

---

## 📦 Installation

### ⚡ Quick Install (Recommended)
**Download the pre-built app and start using it immediately:**

1. **Download the latest release**
   - Go to the [**Releases**](https://github.com/nginxdev/swift-cull-mac/releases) page
   - Download `SwiftCull-v1.0.1.zip` from the latest release

2. **Install the app**
   - Unzip the downloaded file
   - Drag `SwiftCull.app` to your **Applications** folder

3. **First launch**
   - Open **Applications** folder
   - Right-click on `SwiftCull.app` and select **Open**
   - Click **Open** in the security dialog (required for first launch only)

> **Note**: This app is not notarized yet. You will need to right-click and open to bypass Gatekeeper on the first run.

---

### 🔨 Build from Source

```bash
# Clone the repository
git clone https://github.com/nginxdev/swift-cull-mac.git
cd swift-cull-mac

# Build the release version
./build_app.sh

# The app bundle will be created in the current directory as SwiftCull.app
open SwiftCull.app
```

---

## 🎯 How to Use

### 1️⃣ **Select Folder**
Click the folder icon or button in the toolbar to choose a directory containing your images. The app will automatically scan for supported image files.

### 2️⃣ **Review & Rate**
Use keyboard shortcuts to fly through your images:

**Navigation:**
- `Arrow Keys`: Navigate grid or move to next/previous image
- `Space` / `Enter`: Open selected image in full screen

**Rating:**
- `1` - `5`: Set Star Rating
- `0`: Clear Rating

**Filtering:**
- Click the **Filter** button in the top right to show only specific ratings or categories.

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

Built with ❤️ by **nginxdev**.
