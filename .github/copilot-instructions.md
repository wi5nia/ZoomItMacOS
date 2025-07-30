<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# ZoomIt macOS Development Instructions

This is a macOS application project written in Swift using SwiftUI for creating a screen magnification and annotation tool similar to ZoomIt for Windows.

## Project Guidelines

- Use Swift 5.9+ and target macOS 14.0+ (Apple Silicon optimized)
- Follow SwiftUI best practices for UI development
- Use Core Graphics for drawing and annotations
- Implement proper memory management with ARC
- Follow Apple's Human Interface Guidelines
- Use native macOS APIs for screen capture and system integration
- Implement proper sandboxing and privacy permissions

## Key Features to Implement

1. Screen magnification with multiple zoom levels
2. Live zoom window functionality
3. Drawing and annotation tools
4. Text overlay system
5. Global hotkey support
6. Break timer functionality
7. Screen recording capabilities

## Dependencies

- SwiftUI for UI
- Core Graphics for drawing
- AVFoundation for screen recording
- Carbon for global hotkeys
- Core Animation for smooth transitions
- ScreenCaptureKit for modern screen capture (macOS 12.3+)

## Code Style

- Use descriptive variable and function names
- Follow Swift naming conventions
- Document public APIs with Swift DocC comments
- Use proper error handling with Result types
- Implement accessibility features
