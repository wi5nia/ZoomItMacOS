import SwiftUI
import Cocoa

struct ZoomOverlayView: View {
    let controller: ZoomController
    @State private var mouseLocation: NSPoint = .zero
    @State private var zoomedImage: NSImage?
    @State private var showCrosshair = true
    @State private var timer: Timer?
    
    private let displaySize: CGFloat = 300
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Transparent background that passes clicks through
                Color.clear
                    .ignoresSafeArea()
                    .allowsHitTesting(false) // This allows clicks to pass through the background
                
                // Zoomed content window
                if let image = zoomedImage {
                    VStack {
                        Image(nsImage: image)
                            .resizable()
                            .interpolation(.none)
                            .frame(width: displaySize, height: displaySize)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white, lineWidth: 3)
                            )
                            .shadow(radius: 15)
                        
                        // Controls - just show info, no buttons since window ignores mouse events
                        HStack {
                            Text("Press ESC to Exit")
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(8)
                            
                            Text("Zoom: \(Int(controller.zoomLevel))x")
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.black.opacity(0.8))
                                .cornerRadius(8)
                        }
                        .padding(.top, 8)
                    }
                    .position(
                        x: min(max(mouseLocation.x + 200, displaySize/2 + 50), 
                              geometry.size.width - displaySize/2 - 50),
                        y: min(max(geometry.size.height - mouseLocation.y - 100, displaySize/2 + 50), 
                              geometry.size.height - displaySize/2 - 100)
                    )
                }
                
                // Simple crosshair at mouse position
                if showCrosshair {
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 2, height: 20)
                        .position(x: mouseLocation.x, y: geometry.size.height - mouseLocation.y)
                    
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 20, height: 2)
                        .position(x: mouseLocation.x, y: geometry.size.height - mouseLocation.y)
                }
            }
        }
        .onAppear {
            setupSimpleTracking()
        }
        .onDisappear {
            cleanup()
        }
    }
    
    private func setupSimpleTracking() {
        print("🎯 Setting up simple tracking")
        
        // Start a timer to update mouse position and capture screen
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/30.0, repeats: true) { _ in
            let currentMouse = NSEvent.mouseLocation
            DispatchQueue.main.async {
                self.mouseLocation = currentMouse
                self.captureScreenAtMouse()
            }
            
            // Also check for ESC key in the timer (polling approach)
            let escPressed = CGEventSource.keyState(.hidSystemState, key: CGKeyCode(53))
            if escPressed {
                print("🔥 ESC detected via polling - exiting zoom")
                DispatchQueue.main.async {
                    self.controller.stopZoom()
                }
            }
        }
        
        // ESC Key handling - simple and direct approach
        print("🎯 Setting up ESC key monitoring")
        
        // Simple global monitor focused only on ESC
        NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { event in
            print("🎹 Key pressed: \(event.keyCode)")
            if event.keyCode == 53 { // ESC key
                print("🔥 ESC detected - stopping zoom")
                DispatchQueue.main.async {
                    self.controller.stopZoom()
                }
            }
        }
        
        print("✅ ESC key monitoring setup complete")
        
        // Scroll wheel for zoom - global monitor since window ignores mouse events
        NSEvent.addGlobalMonitorForEvents(matching: [.scrollWheel]) { event in
            let delta = event.scrollingDeltaY
            let newZoom = self.controller.zoomLevel + (delta > 0 ? 0.5 : -0.5)
            DispatchQueue.main.async {
                self.controller.changeZoomLevel(newZoom)
            }
        }
        
        print("✅ Simple tracking setup complete")
    }
    
    private func captureScreenAtMouse() {
        // Calculate capture area around mouse
        let captureSize: CGFloat = 150 / controller.zoomLevel
        
        // Use the controller's capture method
        if let captured = controller.captureScreenArea(
            at: mouseLocation,
            size: NSSize(width: captureSize, height: captureSize)
        ) {
            self.zoomedImage = captured
        }
    }
    
    private func cleanup() {
        timer?.invalidate()
        timer = nil
    }
}

// Keep the existing live zoom view for later
struct LiveZoomView: View {
    let controller: ZoomController
    @State private var liveImage: NSImage?
    @State private var timer: Timer?
    
    var body: some View {
        VStack {
            if let image = liveImage {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.none)
                    .frame(width: 400, height: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(radius: 10)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 400, height: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            HStack {
                Text("Live Zoom: \(Int(controller.zoomLevel))x")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Button("Close") {
                    controller.stopZoom()
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .onAppear {
            startLiveCapture()
        }
        .onDisappear {
            stopLiveCapture()
        }
    }
    
    private func startLiveCapture() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/30.0, repeats: true) { _ in
            updateLiveImage()
        }
    }
    
    private func stopLiveCapture() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateLiveImage() {
        let captureSize: CGFloat = 200 / controller.zoomLevel
        
        if let captured = controller.captureScreenArea(
            at: NSEvent.mouseLocation,
            size: NSSize(width: captureSize, height: captureSize)
        ) {
            DispatchQueue.main.async {
                liveImage = captured
            }
        }
    }
}
