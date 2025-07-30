import SwiftUI

@main
struct ZoomItMacOSApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 500, height: 400)
        .defaultPosition(.center)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
