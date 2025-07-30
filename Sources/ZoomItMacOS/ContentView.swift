import SwiftUI

struct ContentView: View {
    @StateObject private var zoomController = ZoomController()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("ZoomIt for macOS")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Screen magnification and annotation tool")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 15) {
                Button("Zoom") {
                    if zoomController.isActive && zoomController.currentMode == .zoom {
                        zoomController.stopZoom()
                    } else {
                        zoomController.startZoom()
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut("z", modifiers: .command)
                
                Button("Live Zoom") {
                    if zoomController.isActive && zoomController.currentMode == .liveZoom {
                        zoomController.stopZoom()
                    } else {
                        zoomController.startLiveZoom()
                    }
                }
                .buttonStyle(.bordered)
                .keyboardShortcut("l", modifiers: .command)
                
                Button("Draw") {
                    if zoomController.isActive && zoomController.currentMode == .draw {
                        zoomController.stopZoom()
                    } else {
                        zoomController.startDrawMode()
                    }
                }
                .buttonStyle(.bordered)
                .keyboardShortcut("d", modifiers: .command)
                
                Button("Type") {
                    if zoomController.isActive && zoomController.currentMode == .type {
                        zoomController.stopZoom()
                    } else {
                        zoomController.startTypeMode()
                    }
                }
                .buttonStyle(.bordered)
                .keyboardShortcut("t", modifiers: .command)
            }
            
            if zoomController.isActive {
                VStack(spacing: 10) {
                    Text("Mode: \(zoomController.currentMode.description)")
                        .foregroundColor(.blue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Zoom Level: \(Int(zoomController.zoomLevel))x")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            
            VStack(spacing: 8) {
                Text("Keyboard Shortcuts:")
                    .font(.headline)
                
                Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 4) {
                    GridRow {
                        Text("⌘Z")
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                        Text("Toggle Zoom mode")
                            .font(.caption)
                    }
                    GridRow {
                        Text("⌘L")
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                        Text("Toggle Live Zoom")
                            .font(.caption)
                    }
                    GridRow {
                        Text("⌘D")
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                        Text("Toggle Draw mode")
                            .font(.caption)
                    }
                    GridRow {
                        Text("⌘T")
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                        Text("Toggle Type mode")
                            .font(.caption)
                    }
                    GridRow {
                        Text("ESC")
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                        Text("Exit current mode")
                            .font(.caption)
                    }
                    GridRow {
                        Text("🖱️")
                            .font(.caption)
                        Text("Mouse wheel changes zoom level")
                            .font(.caption)
                    }
                }
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            Text("Status: \(zoomController.isActive ? "Active" : "Ready")")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onKeyPress(.escape) {
            if zoomController.isActive {
                zoomController.stopZoom()
            }
            return .handled
        }
    }
}

extension ZoomController.ZoomMode {
    var description: String {
        switch self {
        case .none: return "None"
        case .zoom: return "Zoom"
        case .liveZoom: return "Live Zoom"
        case .draw: return "Draw"
        case .type: return "Type"
        case .breakTimer: return "Break Timer"
        }
    }
}