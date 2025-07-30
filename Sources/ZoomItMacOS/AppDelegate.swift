import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem?
    var zoomController: ZoomController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("Application did finish launching")
        zoomController = ZoomController()
        setupStatusBar()
        requestPermissions()
        
        // Show main window after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showMainWindow()
        }
    }
    
    func setupStatusBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusBarItem?.button {
            button.image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: "ZoomIt")
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        }
        
        setupStatusBarMenu()
        print("Status bar setup complete")
    }
    
    private func setupStatusBarMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Show ZoomIt", action: #selector(showMainWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Start Zoom", action: #selector(startZoom), keyEquivalent: "z"))
        menu.addItem(NSMenuItem(title: "Live Zoom", action: #selector(startLiveZoom), keyEquivalent: "l"))
        menu.addItem(NSMenuItem(title: "Draw Mode", action: #selector(startDrawMode), keyEquivalent: "d"))
        menu.addItem(NSMenuItem(title: "Type Mode", action: #selector(startTypeMode), keyEquivalent: "t"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit ZoomIt", action: #selector(quit), keyEquivalent: "q"))
        
        statusBarItem?.menu = menu
    }
    
    private func requestPermissions() {
        // Request screen recording permission
        if !CGPreflightScreenCaptureAccess() {
            print("Requesting screen recording permission")
            CGRequestScreenCaptureAccess()
        } else {
            print("Screen recording permission already granted")
        }
        
        // Request accessibility permission for global hotkeys
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        let isAccessibilityTrusted = AXIsProcessTrustedWithOptions(options)
        print("Accessibility permission: \(isAccessibilityTrusted)")
    }
    
    @objc private func statusBarButtonClicked() {
        print("Status bar button clicked")
        showMainWindow()
    }
    
    @objc func showMainWindow() {
        print("Showing main window")
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
            window.center()
        }
    }
    
    @objc func startZoom() {
        print("Starting zoom mode")
        zoomController?.startZoom()
    }
    
    @objc func startLiveZoom() {
        print("Starting live zoom mode")
        zoomController?.startLiveZoom()
    }
    
    @objc func startDrawMode() {
        print("Starting draw mode")
        zoomController?.startDrawMode()
    }
    
    @objc func startTypeMode() {
        print("Starting type mode")
        zoomController?.startTypeMode()
    }
    
    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}