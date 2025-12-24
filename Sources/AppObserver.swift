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
            kAXValueChangedNotification, // Detects content/text changes
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
        let now = Date()
        
        // --- 1. Title Changes (Navigating Tabs, Directories) ---
        if name == kAXTitleChangedNotification as String {
             var value: AnyObject?
             let result = AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &value)
             
             if result == .success, let newTitle = value as? String {
                 if newTitle == lastKnownTitle { return }
                 if now.timeIntervalSince(lastTitleChangeTime) < 0.1 { return }
                 
                 Logger.monitor.debug("Title: '\(newTitle, privacy: .public)'")
                 lastKnownTitle = newTitle
                 lastTitleChangeTime = now
                 
                 SoundManager.shared.play(event: "app_activity")
             }
        }
        
        // --- 2. Content Changes (Terminal Output, Loading Indicators) ---
        if name == kAXValueChangedNotification as String {
            // A. Get The Element Role (What is it?)
            var roleRef: AnyObject?
            _ = AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef)
            let role = roleRef as? String ?? "Unknown"
            
            // B. Filter Noise (ScrollBars, Layouts, etc.)
            if shouldIgnore(role: role) { return }

            // C. Throttle
            if now.timeIntervalSince(lastTitleChangeTime) < 0.25 { return }
            lastTitleChangeTime = now 
            
            // D. Optional: Check Value (Content)
            // var valueRef: AnyObject?
            // _ = AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &valueRef)
            // let value = valueRef as? String ?? ""
            if role.contains("Unknown") { return } // Ignore empty updates?
            
            Logger.monitor.debug("UI Change: [\(role)]")
            SoundManager.shared.play(event: "app_activity")
        }
        
        // --- 3. Window Lifecycle ---
        if name == kAXWindowCreatedNotification as String {
            SoundManager.shared.play(event: "window_open")
        }
    }

    private func shouldIgnore(role: String) -> Bool {
        // Ignored Roles (Noise & Structure)
        let ignored: Set<String> = [
            // Structural / Layout
            "AXSplitGroup", "AXSplitter",
            "AXGroup", "AXBox", "AXDrawer", "AXGrowArea", "AXMatte",
            "AXRuler", "AXRulerMarker", "AXGrid", "AXColumn", "AXRow", 
            
            // Web / Browser
            "AXWebArea", "AXLink", "AXList",
            "AXTextField", "AXTextArea", // Prevent double-typing sounds
            
            // Menus & Chrome
            "AXToolbar", "AXMenu", "AXMenuItem", "AXMenuBar", "AXMenuBarItem",
            "AXPopover", "AXHelpTag", "AXSystemWide",
            
            // Controls that trigger often but aren't "Content" updates
            // "AXButton", // Maybe keep buttons?
            "AXCheckBox", "AXRadioButton", "AXRadioGroup", "AXDisclosureTriangle",
            "AXSlider", // 60fps updates, too noisy
            "AXValueIndicator", "AXRelevanceIndicator", "AXBusyIndicator", // Spinner noise
            "AXUnknown",
        ]
        
        return ignored.contains(role)
    }
}
