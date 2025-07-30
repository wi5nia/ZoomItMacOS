# Changelog

All notable changes to ZoomIt macOS will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Core screen magnification functionality with real-time mouse tracking
- Scroll wheel zoom control (zoom in/out with mouse wheel)
- Click-through functionality allowing interaction with underlying applications
- Live zoom window that follows mouse cursor
- Proper coordinate system handling for screen capture
- SwiftUI-based user interface with overlay window management
- Global event monitoring for mouse and scroll wheel events
- Basic project structure with Swift Package Manager

### Working
- ✅ Screen capture and magnification display
- ✅ Mouse wheel zoom control
- ✅ Click-through to underlying applications
- ✅ Real-time mouse tracking and window positioning
- ✅ Proper coordinate conversion between screen and image coordinates

### In Progress
- 🚧 ESC key exit functionality (under development)
- 🚧 Drawing and annotation tools
- 🚧 Text overlay system
- 🚧 Global hotkey support beyond current implementation
- 🚧 Settings and preferences interface

### Technical Details
- Built with Swift 5.9+ and SwiftUI
- Targets macOS 14.0+ (Apple Silicon optimized)
- Uses Core Graphics for screen capture
- Implements NSEvent monitoring for global input handling
- Window management with screen saver level overlay

## [0.1.0] - 2025-07-30

### Added
- Initial project setup and basic structure
- Core zoom functionality implementation
- Mouse tracking and screen capture capabilities
