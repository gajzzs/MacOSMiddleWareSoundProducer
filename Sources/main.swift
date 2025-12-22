import Foundation
import Cocoa
import os

// Main Entry Point
let app = NSApplication.shared

// Helper AppDelegate since we are not using swiftUI App protocol
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        Logger.app.info("MacOSMiddleWareSoundProducer Running...")
        
        // 1. Check Permissions
        _ = PermissionsManager.checkAccessibility()
        
        // 2. Load Config
        let config = ConfigLoader.shared.loadConfig()
        if let config = config {
            Logger.app.info("Events Configured: \(config.events.keys.joined(separator: ", "))")
            SoundManager.shared.configure(with: config)
        } else {
            Logger.app.error("No config.json found. Please ensure config.json is present.")
        }
        
        // 3. Start Event Tap
        EventTapManager.shared.start()
        
        // 4. Start File Monitor
        FileMonitor.shared.startMonitoring()
        
        // 5. Start Window Monitor
        WindowManager.shared.startMonitoring()
        
        // 6. Start active App Observer
        AppObserver.shared.start()
        
        // 7. Setup Menu Bar
        MenuBarManager.shared.setup()
    }
}

let delegate = AppDelegate()
app.delegate = delegate

// Hide Dock Icon (Background Mode) by default
// Users can still see it in Activity Monitor
app.setActivationPolicy(.accessory)

app.run()
