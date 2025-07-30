import Cocoa
import Carbon
import SwiftUI

/// Manages global hotkeys for ZoomIt functionality
class HotKeyManager: ObservableObject {
    @Published var isEnabled = true
    
    private var hotKeys: [Int32: EventHotKeyRef] = [:]
    private var hotKeyToAction: [Int32: HotKeyAction] = [:]
    private var eventHandler: EventHandlerRef?
    private var hotKeyTarget: EventTargetRef?
    
    enum HotKeyAction {
        case zoom
        case liveZoom
        case draw
        case type
        case breakTimer
        case escape
    }
    
    // Default hotkey combinations
    private let defaultHotKeys: [HotKeyAction: (keyCode: Int32, modifiers: UInt32)] = [
        .zoom: (6, UInt32(cmdKey)), // Cmd+Z
        .liveZoom: (37, UInt32(cmdKey)), // Cmd+L
        .draw: (2, UInt32(cmdKey)), // Cmd+D
        .type: (17, UInt32(cmdKey)), // Cmd+T
        .breakTimer: (11, UInt32(cmdKey)), // Cmd+B
        .escape: (53, 0) // ESC
    ]
    
    init() {
        setupGlobalHotKeys()
    }
    
    deinit {
        cleanup()
    }
    
    private func setupGlobalHotKeys() {
        // Check if accessibility permissions are granted
        guard AXIsProcessTrusted() else {
            print("Accessibility permissions not granted")
            return
        }
        
        // Set up event target
        hotKeyTarget = GetEventDispatcherTarget()
        
        // Install event handler
        var eventHandler: EventHandlerRef?
        let eventTypes = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        ]
        
        let status = InstallEventHandler(
            hotKeyTarget,
            { (nextHandler, event, userData) -> OSStatus in
                return HotKeyManager.hotKeyHandler(nextHandler: nextHandler, event: event, userData: userData)
            },
            1,
            eventTypes,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )
        
        if status != noErr {
            print("Failed to install event handler: \(status)")
            return
        }
        
        self.eventHandler = eventHandler
        
        // Register default hotkeys
        registerDefaultHotKeys()
    }
    
    private func registerDefaultHotKeys() {
        for (action, hotKey) in defaultHotKeys {
            registerHotKey(action: action, keyCode: hotKey.keyCode, modifiers: hotKey.modifiers)
        }
    }
    
    private func registerHotKey(action: HotKeyAction, keyCode: Int32, modifiers: UInt32) {
        let hotKeyID = Int32(getHotKeyID(for: action))
        var hotKeyRef: EventHotKeyRef?
        
        let status = RegisterEventHotKey(
            UInt32(keyCode),
            modifiers,
            EventHotKeyID(signature: OSType(0x5A6D4974), id: UInt32(hotKeyID)), // 'ZmIt'
            hotKeyTarget,
            0,
            &hotKeyRef
        )
        
        if status == noErr, let hotKeyRef = hotKeyRef {
            hotKeys[hotKeyID] = hotKeyRef
            hotKeyToAction[hotKeyID] = action
            print("Registered hotkey for \(action): keyCode=\(keyCode), modifiers=\(modifiers)")
        } else {
            print("Failed to register hotkey for \(action): \(status)")
        }
    }
    
    private func getHotKeyID(for action: HotKeyAction) -> Int {
        switch action {
        case .zoom: return 1
        case .liveZoom: return 2
        case .draw: return 3
        case .type: return 4
        case .breakTimer: return 5
        case .escape: return 6
        }
    }
    
    private static func hotKeyHandler(nextHandler: EventHandlerCallRef?, event: EventRef?, userData: UnsafeMutableRawPointer?) -> OSStatus {
        guard let userData = userData else { return OSStatus(eventNotHandledErr) }
        let hotKeyManager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
        
        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )
        
        if status == noErr {
            hotKeyManager.handleHotKey(id: Int32(hotKeyID.id))
            return noErr
        }
        
        return OSStatus(eventNotHandledErr)
    }
    
    private func handleHotKey(id: Int32) {
        guard isEnabled, let action = hotKeyToAction[id] else { return }
        
        DispatchQueue.main.async {
            self.executeAction(action)
        }
    }
    
    private func executeAction(_ action: HotKeyAction) {
        // Get the zoom controller from the app
        // guard let app = NSApp.delegate as? AppDelegate else { return }
        
        switch action {
        case .zoom:
            print("Hotkey: Start Zoom")
            // app.startZoom()
        case .liveZoom:
            print("Hotkey: Start Live Zoom")
            // app.startLiveZoom()
        case .draw:
            print("Hotkey: Start Draw Mode")
            // app.startDrawMode()
        case .type:
            print("Hotkey: Start Type Mode")
            // app.startTypeMode()
        case .breakTimer:
            print("Hotkey: Start Break Timer")
            // TODO: Implement break timer
        case .escape:
            print("Hotkey: Escape")
            // Handle escape - this should be handled by zoom controller
        }
    }
    
    func unregisterHotKey(action: HotKeyAction) {
        let hotKeyID = Int32(getHotKeyID(for: action))
        
        if let hotKeyRef = hotKeys[hotKeyID] {
            UnregisterEventHotKey(hotKeyRef)
            hotKeys.removeValue(forKey: hotKeyID)
            hotKeyToAction.removeValue(forKey: hotKeyID)
        }
    }
    
    func updateHotKey(action: HotKeyAction, keyCode: Int32, modifiers: UInt32) {
        unregisterHotKey(action: action)
        registerHotKey(action: action, keyCode: keyCode, modifiers: modifiers)
    }
    
    func toggleEnabled() {
        isEnabled.toggle()
    }
    
    private func cleanup() {
        // Unregister all hotkeys
        for (_, hotKeyRef) in hotKeys {
            UnregisterEventHotKey(hotKeyRef)
        }
        hotKeys.removeAll()
        hotKeyToAction.removeAll()
        
        // Remove event handler
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }
}
