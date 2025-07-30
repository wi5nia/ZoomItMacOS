import Cocoa
import CoreGraphics

/// Handles screen capture functionality using Core Graphics
class ScreenCapture: ObservableObject {
    
    init() {
        // Initialize screen capture
    }
    
    /// Capture the full screen using Core Graphics
    func captureFullScreen() -> NSImage? {
        return captureFullScreenLegacy()
    }
    
    /// Capture a specific area of the screen around a center point
    func captureArea(at centerPoint: NSPoint, size: NSSize) -> NSImage? {
        guard let screen = NSScreen.main else { 
            print("❌ No main screen found")
            return nil 
        }
        
        let screenHeight = screen.frame.height
        let screenWidth = screen.frame.width
        
        // Calculate top-left corner from center point
        let topLeft = NSPoint(
            x: centerPoint.x - size.width / 2,
            y: centerPoint.y - size.height / 2
        )
        
        // Convert from NSScreen coordinates (origin bottom-left) to CGImage coordinates (origin top-left)
        let cgRect = CGRect(
            x: max(0, min(screenWidth - size.width, topLeft.x)),
            y: max(0, min(screenHeight - size.height, screenHeight - topLeft.y - size.height)),
            width: size.width,
            height: size.height
        )
        
        print("🔍 Screen capture:")
        print("   Center point: \(centerPoint)")
        print("   Capture size: \(size)")
        print("   Screen: \(screenWidth) x \(screenHeight)")
        print("   Final CGRect: \(cgRect)")
        
        return captureRect(cgRect)
    }
    
    /// Capture a rectangle using Core Graphics
    private func captureRect(_ rect: CGRect) -> NSImage? {
        print("🎯 captureRect called with: \(rect)")
        
        // Use CGDisplayCreateImage for better compatibility
        guard let display = CGMainDisplayID() as CGDirectDisplayID? else {
            print("❌ Could not get main display")
            return nil
        }
        
        guard let cgImage = CGDisplayCreateImage(display, rect: rect) else {
            print("❌ Failed to create CGImage from display")
            return nil
        }
        
        print("✅ Successfully captured CGImage - width: \(cgImage.width), height: \(cgImage.height)")
        let nsImage = NSImage(cgImage: cgImage, size: rect.size)
        print("✅ Created NSImage with size: \(nsImage.size)")
        return nsImage
    }
    
    /// Legacy full screen capture using Core Graphics
    private func captureFullScreenLegacy() -> NSImage? {
        guard let screen = NSScreen.main else { return nil }
        let screenRect = screen.frame
        
        // Convert to Core Graphics coordinates (origin at bottom-left)
        let cgRect = CGRect(
            x: screenRect.origin.x,
            y: 0,
            width: screenRect.size.width,
            height: screenRect.size.height
        )
        
        guard let cgImage = CGWindowListCreateImage(
            cgRect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            .bestResolution
        ) else {
            return nil
        }
        
        return NSImage(cgImage: cgImage, size: screenRect.size)
    }
    
    /// Capture a window by ID
    func captureWindow(windowID: CGWindowID) -> NSImage? {
        guard let cgImage = CGWindowListCreateImage(
            .null,
            .optionIncludingWindow,
            windowID,
            [.bestResolution, .boundsIgnoreFraming]
        ) else {
            return nil
        }
        
        let size = CGSize(width: cgImage.width, height: cgImage.height)
        return NSImage(cgImage: cgImage, size: size)
    }
    
    /// Get list of available windows
    func getWindowList() -> [[String: Any]]? {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        return CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]]
    }
    
    /// Get the window under cursor
    func getWindowUnderCursor() -> CGWindowID? {
        let mouseLocation = NSEvent.mouseLocation
        
        // Convert to Core Graphics coordinates
        guard let screen = NSScreen.main else { return nil }
        let _ = CGPoint(
            x: mouseLocation.x,
            y: screen.frame.height - mouseLocation.y
        )
        
        // Get window at point
        let _ = CGWindowListCopyWindowInfo(.optionOnScreenAboveWindow, kCGNullWindowID)
        // Implementation would need to check which window contains the point
        // For now, return null
        return nil
    }
    
    /// Capture area around mouse cursor
    func captureAroundCursor(size: NSSize) -> NSImage? {
        let mouseLocation = NSEvent.mouseLocation
        let point = NSPoint(
            x: mouseLocation.x - size.width / 2,
            y: mouseLocation.y - size.height / 2
        )
        
        return captureArea(at: point, size: size)
    }
    
    /// Start continuous capture for live zoom
    func startLiveCapture(callback: @escaping (NSImage?) -> Void) {
        // Implement timer-based capture for live zoom
        Timer.scheduledTimer(withTimeInterval: 1.0/30.0, repeats: true) { timer in
            let image = self.captureAroundCursor(size: NSSize(width: 200, height: 200))
            callback(image)
        }
    }
}
