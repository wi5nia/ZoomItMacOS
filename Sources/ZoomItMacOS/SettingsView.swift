import SwiftUI
import Cocoa

struct SettingsView: View {
    @EnvironmentObject var zoomController: ZoomController
    @EnvironmentObject var hotKeyManager: HotKeyManager
    @State private var selectedTab: SettingsTab = .general
    
    enum SettingsTab: String, CaseIterable {
        case general = "General"
        case hotkeys = "Hotkeys"
        case zoom = "Zoom"
        case drawing = "Drawing"
        case about = "About"
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("General")
                }
                .tag(SettingsTab.general)
            
            HotkeySettingsView()
                .environmentObject(hotKeyManager)
                .tabItem {
                    Image(systemName: "keyboard")
                    Text("Hotkeys")
                }
                .tag(SettingsTab.hotkeys)
            
            ZoomSettingsView()
                .environmentObject(zoomController)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Zoom")
                }
                .tag(SettingsTab.zoom)
            
            DrawingSettingsView()
                .tabItem {
                    Image(systemName: "pencil.tip")
                    Text("Drawing")
                }
                .tag(SettingsTab.drawing)
            
            AboutView()
                .tabItem {
                    Image(systemName: "info.circle")
                    Text("About")
                }
                .tag(SettingsTab.about)
        }
        .frame(width: 500, height: 400)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showInMenuBar") private var showInMenuBar = true
    @AppStorage("showInDock") private var showInDock = false
    @AppStorage("hideMainWindowOnStart") private var hideMainWindowOnStart = true
    
    var body: some View {
        Form {
            Section("Application") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        setLaunchAtLogin(newValue)
                    }
                
                Toggle("Show in menu bar", isOn: $showInMenuBar)
                    .onChange(of: showInMenuBar) { newValue in
                        updateMenuBarVisibility(newValue)
                    }
                
                Toggle("Show in Dock", isOn: $showInDock)
                    .onChange(of: showInDock) { newValue in
                        updateDockVisibility(newValue)
                    }
                
                Toggle("Hide main window on startup", isOn: $hideMainWindowOnStart)
            }
            
            Section("Permissions") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: checkScreenRecordingPermission() ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(checkScreenRecordingPermission() ? .green : .red)
                        Text("Screen Recording")
                        Spacer()
                        if !checkScreenRecordingPermission() {
                            Button("Grant") {
                                requestScreenRecordingPermission()
                            }
                        }
                    }
                    
                    HStack {
                        Image(systemName: checkAccessibilityPermission() ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(checkAccessibilityPermission() ? .green : .red)
                        Text("Accessibility (for global hotkeys)")
                        Spacer()
                        if !checkAccessibilityPermission() {
                            Button("Grant") {
                                requestAccessibilityPermission()
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    private func setLaunchAtLogin(_ enabled: Bool) {
        // Implementation would use LaunchAtLogin framework or similar
        print("Launch at login: \(enabled)")
    }
    
    private func updateMenuBarVisibility(_ show: Bool) {
        // if let appDelegate = NSApp.delegate as? AppDelegate {
        if show {
            // appDelegate.setupStatusBar()
            print("Would show menu bar")
        } else {
            // appDelegate.statusBarItem = nil
            print("Would hide menu bar")
        }
        // }
    }
    
    private func updateDockVisibility(_ show: Bool) {
        NSApp.setActivationPolicy(show ? .regular : .accessory)
    }
    
    private func checkScreenRecordingPermission() -> Bool {
        return CGPreflightScreenCaptureAccess()
    }
    
    private func checkAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }
    
    private func requestScreenRecordingPermission() {
        CGRequestScreenCaptureAccess()
    }
    
    private func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options)
    }
}

struct HotkeySettingsView: View {
    @EnvironmentObject var hotKeyManager: HotKeyManager
    @State private var selectedAction: HotKeyManager.HotKeyAction?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Configure global hotkeys for ZoomIt functions")
                .font(.headline)
            
            VStack(spacing: 12) {
                HotkeyRow(action: .zoom, title: "Start Zoom", description: "Begin screen magnification")
                HotkeyRow(action: .liveZoom, title: "Live Zoom", description: "Open live zoom window")
                HotkeyRow(action: .draw, title: "Draw Mode", description: "Start drawing on screen")
                HotkeyRow(action: .type, title: "Type Mode", description: "Add text overlays")
                HotkeyRow(action: .breakTimer, title: "Break Timer", description: "Start presentation break")
            }
            
            HStack {
                Toggle("Enable global hotkeys", isOn: $hotKeyManager.isEnabled)
                Spacer()
                Button("Reset to Defaults") {
                    resetToDefaults()
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func resetToDefaults() {
        // Reset hotkeys to default values
        print("Reset hotkeys to defaults")
    }
}

struct HotkeyRow: View {
    let action: HotKeyManager.HotKeyAction
    let title: String
    let description: String
    @State private var isRecording = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(isRecording ? "Press keys..." : "⌘\(getKeyForAction())") {
                isRecording.toggle()
            }
            .foregroundColor(isRecording ? .red : .primary)
            .frame(minWidth: 100)
        }
        .padding(.vertical, 4)
    }
    
    private func getKeyForAction() -> String {
        switch action {
        case .zoom: return "Z"
        case .liveZoom: return "L"
        case .draw: return "D"
        case .type: return "T"
        case .breakTimer: return "B"
        case .escape: return "ESC"
        }
    }
}

struct ZoomSettingsView: View {
    @EnvironmentObject var zoomController: ZoomController
    @AppStorage("defaultZoomLevel") private var defaultZoomLevel: Double = 2.0
    @AppStorage("maxZoomLevel") private var maxZoomLevel: Double = 16.0
    @AppStorage("zoomIncrement") private var zoomIncrement: Double = 0.5
    @AppStorage("smoothZoom") private var smoothZoom = true
    @AppStorage("showCrosshair") private var showCrosshair = true
    
    var body: some View {
        Form {
            Section("Zoom Behavior") {
                HStack {
                    Text("Default zoom level:")
                    Spacer()
                    Slider(value: $defaultZoomLevel, in: 1.0...8.0, step: 0.5)
                        .frame(width: 150)
                    Text("\(defaultZoomLevel, specifier: "%.1f")x")
                        .frame(width: 40)
                }
                
                HStack {
                    Text("Maximum zoom level:")
                    Spacer()
                    Slider(value: $maxZoomLevel, in: 4.0...32.0, step: 1.0)
                        .frame(width: 150)
                    Text("\(maxZoomLevel, specifier: "%.0f")x")
                        .frame(width: 40)
                }
                
                HStack {
                    Text("Zoom increment:")
                    Spacer()
                    Slider(value: $zoomIncrement, in: 0.1...2.0, step: 0.1)
                        .frame(width: 150)
                    Text("\(zoomIncrement, specifier: "%.1f")x")
                        .frame(width: 40)
                }
                
                Toggle("Smooth zoom transitions", isOn: $smoothZoom)
                Toggle("Show crosshair", isOn: $showCrosshair)
            }
        }
        .padding()
    }
}

struct DrawingSettingsView: View {
    @AppStorage("defaultDrawingColor") private var defaultDrawingColor = "red"
    @AppStorage("defaultStrokeWidth") private var defaultStrokeWidth: Double = 3.0
    @AppStorage("antiAliasing") private var antiAliasing = true
    @AppStorage("pressureSensitive") private var pressureSensitive = false
    
    var body: some View {
        Form {
            Section("Drawing Tools") {
                HStack {
                    Text("Default stroke width:")
                    Spacer()
                    Slider(value: $defaultStrokeWidth, in: 1.0...20.0, step: 1.0)
                        .frame(width: 150)
                    Text("\(Int(defaultStrokeWidth))px")
                        .frame(width: 40)
                }
                
                Toggle("Anti-aliasing", isOn: $antiAliasing)
                Toggle("Pressure sensitive (if supported)", isOn: $pressureSensitive)
            }
            
            Section("Colors") {
                Text("Default drawing colors and presets can be configured here")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
            
            Text("ZoomIt for macOS")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Version 1.0.0")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("A screen magnification and annotation tool for macOS, inspired by the Windows ZoomIt utility.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                Text("Features:")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Screen magnification with multiple zoom levels")
                    Text("• Live zoom window")
                    Text("• Drawing and annotation tools")
                    Text("• Text overlay functionality")
                    Text("• Global hotkey support")
                    Text("• Break timer for presentations")
                }
                .font(.body)
            }
            
            Spacer()
            
            Text("Built with Swift and SwiftUI for Apple Silicon Macs")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
