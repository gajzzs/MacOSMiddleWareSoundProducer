import Cocoa
import ApplicationServices
import os

class AppObserver {
    static let shared = AppObserver()
    
    private var currentObserver: AXObserver?
    private var currentPid: pid_t?
    
    private init() {
        // Listen for App Switching
        NSWorkspace.shared.notificationCenter.addObserver(self, 
                                                        selector: #selector(appActivated(_:)), 
                                                        name: NSWorkspace.didActivateApplicationNotification, 
                                                        object: nil)
    }
    
    func start() {
        if let front = NSWorkspace.shared.frontmostApplication {
            watchApp(app: front)
        }
    }
    
    @objc private func appActivated(_ notification: Notification) {
        if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
            watchApp(app: app)
        }
    }
    
    private func watchApp(app: NSRunningApplication) {
        let pid = app.processIdentifier
        if pid == currentPid { return }
        
        // Clean up old observer
        if let oldObserver = currentObserver {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(oldObserver), .defaultMode)
            currentObserver = nil
        }
        
        currentPid = pid
        Logger.monitor.info("Monitoring App: \(app.localizedName ?? "Unknown") (PID: \(pid))")
        
        // Update Network Monitor
        NetworkMonitor.shared.updateTarget(pid: pid)
        
        // Create new observer
        var observer: AXObserver?
        let error = AXObserverCreate(pid, { (observer, element, notification, refcon) in
            // Callback: Handle Notification
            AppObserver.shared.handleNotification(notification: notification, element: element)
        }, &observer)
        
        guard error == .success, let axObserver = observer else {
            Logger.monitor.error("Failed to create AXObserver for PID \(pid) (Error: \(error.rawValue))")
            return
        }
        
        self.currentObserver = axObserver
        
        // Add Notifications to Observe
        // kAXTitleChangedNotification: Good for terminal commands, browser tabs
        // kAXFocusedUIElementChangedNotification: Good for navigation, but maybe too spammy?
        // kAXWindowCreatedNotification: Good for popups
        
        let notifications = [
            kAXTitleChangedNotification,
            kAXWindowCreatedNotification,
            kAXUIElementDestroyedNotification
        ]
        
        let selfPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        for notif in notifications {
            AXObserverAddNotification(axObserver, AXUIElementCreateApplication(pid), notif as CFString, selfPtr)
        }
        
        // Add to RunLoop
        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(axObserver), .defaultMode)
    }
    
    private var lastKnownTitle: String = ""
    private var lastTitleChangeTime: Date = Date.distantPast
    
    private func handleNotification(notification: CFString, element: AXUIElement) {
        let name = notification as String
        // print("🔔 Activity: \(name)")
        
        if name == kAXTitleChangedNotification as String {
             // Extract Title
             var value: AnyObject?
             let result = AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &value)
             
             if result == .success, let newTitle = value as? String {
                 // 1. Filter Duplicates ("No actual change")
                 if newTitle == lastKnownTitle { return }
                 
                 // 2. Filter Rapid Flapping (optional, e.g. progress bars)
                 let now = Date()
                 if now.timeIntervalSince(lastTitleChangeTime) < 0.1 { return }
                 
                 // 3. Filter Minor Status Changes (e.g. dirty bit "*")
                 // If the only difference is a leading/trailing " *" or " - ", maybe ignore?
                 // For now, strict inequality is better than blind firing.
                 
                 Logger.monitor.debug("Title Changed: '\(self.lastKnownTitle, privacy: .public)' -> '\(newTitle, privacy: .public)'")
                 lastKnownTitle = newTitle
                 lastTitleChangeTime = now
                 
                 SoundManager.shared.play(event: "app_activity")
             }
        }
        
        if name == kAXWindowCreatedNotification as String {
            SoundManager.shared.play(event: "window_open")
        }
    }
}
