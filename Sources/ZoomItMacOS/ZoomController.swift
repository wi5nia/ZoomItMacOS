import SwiftUI
import Cocoa
import CoreGraphics
import AVFoundation

/// Main controller for zoom functionality
class ZoomController: ObservableObject {
    @Published var isActive = false
    @Published var zoomLevel: CGFloat = 2.0
    @Published var currentMode: ZoomMode = .none
    
    private var zoomWindow: NSWindow?
    private var overlayWindow: NSWindow?
    private var liveZoomWindow: NSWindow?
    private var screenCapture: ScreenCapture?
    private var drawingController: DrawingController?
    private var textController: TextController?
    private var escapeTimer: Timer?
    
    enum ZoomMode {
        case none
        case zoom
        case liveZoom
        case draw
        case type
        case breakTimer
    }
    
    init() {
        setupScreenCapture()
        setupEventMonitoring()
    }
    
    private func setupScreenCapture() {
        screenCapture = ScreenCapture()
    }
    
    private func setupEventMonitoring() {
        // Simplified event monitoring - main ESC handling is in ZoomOverlayView
        print("🎮 ZoomController event monitoring setup")
    }
    
    // MARK: - Zoom Functions
    
    func startZoom() {
        guard !isActive else { return }
        
        currentMode = .zoom
        isActive = true
        
        createZoomOverlay()
        hideOtherWindows()
    }
    
    func startLiveZoom() {
        guard !isActive else { return }
        
        currentMode = .liveZoom
        isActive = true
        
        createLiveZoomWindow()
    }
    
    func startDrawMode() {
        guard !isActive else { return }
        
        currentMode = .draw
        isActive = true
        
        createDrawingOverlay()
        hideOtherWindows()
    }
    
    func startTypeMode() {
        guard !isActive else { return }
        
        currentMode = .type
        isActive = true
        
        createTextOverlay()
        hideOtherWindows()
    }
    
    func stopZoom() {
        print("🛑 stopZoom called - current mode: \(currentMode)")
        isActive = false
        currentMode = .none
        
        cleanupWindows()
        showOtherWindows()
        print("🛑 stopZoom completed")
    }
    
    func changeZoomLevel(_ newLevel: CGFloat) {
        zoomLevel = max(1.0, min(16.0, newLevel))
        updateZoomDisplay()
    }
    
    // MARK: - Window Management
    
    private func createZoomOverlay() {
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let screenFrame = screen.frame
        
        overlayWindow = NSWindow(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        overlayWindow?.level = .screenSaver
        overlayWindow?.backgroundColor = .clear
        overlayWindow?.isOpaque = false
        overlayWindow?.hasShadow = false
        overlayWindow?.ignoresMouseEvents = true  // RESTORE: Ignore all mouse events for click-through
        overlayWindow?.acceptsMouseMovedEvents = false
        overlayWindow?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        let zoomView = ZoomOverlayView(controller: self)
        overlayWindow?.contentView = NSHostingView(rootView: zoomView)
        overlayWindow?.makeKeyAndOrderFront(nil)
    }
    
    private func createLiveZoomWindow() {
        let initialFrame = NSRect(x: 100, y: 100, width: 300, height: 300)
        
        liveZoomWindow = NSWindow(
            contentRect: initialFrame,
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        liveZoomWindow?.title = "Live Zoom"
        liveZoomWindow?.level = .floating
        liveZoomWindow?.collectionBehavior = [.canJoinAllSpaces]
        
        let liveZoomView = LiveZoomView(controller: self)
        liveZoomWindow?.contentView = NSHostingView(rootView: liveZoomView)
        liveZoomWindow?.makeKeyAndOrderFront(nil)
    }
    
    private func createDrawingOverlay() {
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let screenFrame = screen.frame
        
        overlayWindow = NSWindow(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        overlayWindow?.level = .screenSaver
        overlayWindow?.backgroundColor = .clear
        overlayWindow?.isOpaque = false
        overlayWindow?.hasShadow = false
        overlayWindow?.ignoresMouseEvents = false
        overlayWindow?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        drawingController = DrawingController()
        let drawingView = DrawingOverlayView(drawingController: drawingController!)
        overlayWindow?.contentView = NSHostingView(rootView: drawingView)
        overlayWindow?.makeKeyAndOrderFront(nil)
    }
    
    private func createTextOverlay() {
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let screenFrame = screen.frame
        
        overlayWindow = NSWindow(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        overlayWindow?.level = .screenSaver
        overlayWindow?.backgroundColor = .clear
        overlayWindow?.isOpaque = false
        overlayWindow?.hasShadow = false
        overlayWindow?.ignoresMouseEvents = false
        overlayWindow?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        textController = TextController()
        let textView = TextOverlayView(textController: textController!)
        overlayWindow?.contentView = NSHostingView(rootView: textView)
        overlayWindow?.makeKeyAndOrderFront(nil)
    }
    
    private func cleanupWindows() {
        print("🧹 cleanupWindows called")
        overlayWindow?.orderOut(nil)
        overlayWindow = nil
        
        liveZoomWindow?.orderOut(nil)
        liveZoomWindow = nil
        
        drawingController = nil
        textController = nil
        print("🧹 cleanupWindows completed")
    }
    
    private func hideOtherWindows() {
        // Hide all other application windows
        for window in NSApp.windows {
            if window != overlayWindow && window != liveZoomWindow {
                window.orderOut(nil)
            }
        }
    }
    
    private func showOtherWindows() {
        // Show hidden windows
        for window in NSApp.windows {
            if window != overlayWindow && window != liveZoomWindow {
                window.orderFront(nil)
            }
        }
    }
    
    private func updateZoomDisplay() {
        // The new ZoomOverlayView updates automatically via timer
        // No manual update needed
    }
    
    // MARK: - Screen Capture
    
    func captureScreenArea(at centerPoint: NSPoint, size: NSSize) -> NSImage? {
        return screenCapture?.captureArea(at: centerPoint, size: size)
    }
    
    func captureFullScreen() -> NSImage? {
        return screenCapture?.captureFullScreen()
    }
}
