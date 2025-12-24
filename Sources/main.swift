import Foundation
import Cocoa
import os

// MARK: - Configuration
let app = NSApplication.shared
let args = CommandLine.arguments
let env = ProcessInfo.processInfo.environment

// Check Mode
// 1. Foreground Mode: "MacOSMiddleWareForeground=1" env
let isForegroundRequest = env["MacOSMiddleWareForeground"] == "1"

// 2. Child Daemon Mode: Internal flag indicating we are the background worker
let isChildDaemon = args.contains("--child-daemon")

// MARK: - Logic Flow

if isForegroundRequest || isChildDaemon {
    // === RUNNING THE APP (Foreground or Background Worker) ===
    
    class AppDelegate: NSObject, NSApplicationDelegate {
        func applicationDidFinishLaunching(_ notification: Notification) {
            let mode = isForegroundRequest ? "Foreground" : "Background Daemon"
            Logger.app.info("MacOSMiddleWareSoundProducer Running [\(mode)]...")
            
            // 1. Check Permissions
            _ = PermissionsManager.checkAccessibility()
            
            // 2. Load Config
            let config = ConfigLoader.shared.loadConfig()
            if let config = config {
                Logger.app.info("Events Configured: \(config.events.keys.joined(separator: ", "))")
                SoundManager.shared.configure(with: config)
            } else {
                Logger.app.error("No config.json found.")
            }
            
            // 3. Start Helpers
            EventTapManager.shared.start()
            FileMonitor.shared.startMonitoring()
            WindowManager.shared.startMonitoring()
            AppObserver.shared.start()
            
            // 4. Setup Menu Bar (Requested for Background, useful for Foreground too)
            MenuBarManager.shared.setup()
        }
    }
    
    let delegate = AppDelegate()
    app.delegate = delegate
    
    // Always use Accessory mode (Menu Bar only, No Dock)
    // Even in foreground, we don't need a Dock icon for a middleware tool.
    app.setActivationPolicy(.accessory)
    
    app.run()
    
} else {
    // === LAUNCHER MODE (Default) ===
    // Spawn ourselves in the background and exit
    
    let executableUrl = URL(fileURLWithPath: args[0])
    let daemonArgs = ["--child-daemon"]
    
    print("MacOSMiddleWare Sound Producer")
    print("   - Launching in background...")
    
    do {
        let process = Process()
        process.executableURL = executableUrl
        process.arguments = daemonArgs
        
        // Detach?
        // To truly detach, we shouldn't pipe output unless requested.
        // But for debugging, maybe we let it go to system logs.
        // process.standardOutput = FileHandle.nullDevice
        // process.standardError = FileHandle.nullDevice
        
        try process.run()
        
        print("Background Process Started (PID: \(process.processIdentifier))")
        print("   - Menu Bar Icon should appear.")
        print("   - Use 'MacOSMiddleWareForeground=1 swift run' to run in this terminal.")
        
        exit(0)
    } catch {
        print("Failed to launch daemon: \(error)")
        exit(1)
    }
}
