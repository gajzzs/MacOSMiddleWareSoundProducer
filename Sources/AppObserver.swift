//
//  AppObserver.swift
//  MacOSMiddleWareSoundProducer
//
//  Created by User on 2024-12-25.
//  Summary: Monitors active applications and accessibility events to trigger sound effects.
//  Changes:
//  - Added environment variable support for dynamic role filtering.
//  - MW_IGNORE_ROLES: Add additional roles to ignore.
//  - MW_INCLUDE_ROLES: Remove roles from the ignore list (allow them).
//  - Default ignored roles preserved as requested.
//

import Cocoa
import ApplicationServices
import os

class AppObserver {
    static let shared = AppObserver()
    
    private var currentObserver: AXObserver?
    private var currentPid: pid_t?
    
    // --- Role Groups ---
    private static let rolesStructural: Set<String> = [
        "AXSplitGroup", "AXSplitter", "AXGroup", "AXBox", "AXDrawer", 
        "AXGrowArea", "AXMatte", "AXRuler", "AXRulerMarker", "AXGrid", "AXColumn", "AXRow"
    ]
    
    private static let rolesWeb: Set<String> = [
        "AXWebArea", "AXLink", "AXList"
    ]
    
    // Prevent double-typing sounds (using text field changes for feedback instead)
    private static let rolesInput: Set<String> = [
        "AXTextField", "AXTextArea"
    ]
    
    private static let rolesMenus: Set<String> = [
        "AXToolbar", "AXMenu", "AXMenuItem", "AXMenuBar", "AXMenuBarItem",
        "AXPopover", "AXHelpTag", "AXSystemWide"
    ]
    
    private static let rolesControls: Set<String> = [
        "AXCheckBox", "AXRadioButton", "AXRadioGroup", "AXDisclosureTriangle",
        "AXSlider", "AXValueIndicator", "AXRelevanceIndicator", "AXBusyIndicator",
        "AXButton" // Often too frequent, can be enabled if needed
    ]
    
    private static let rolesUnknown: Set<String> = ["AXUnknown", "Unknown"]
    
    // Default ignored roles (Everything above)
    private let defaultIgnoredRoles: Set<String>
    
    private var effectiveIgnoredRoles: Set<String> = []
    
    private let roleGroups: [String: Set<String>] = [
        "structural": AppObserver.rolesStructural,
        "web": AppObserver.rolesWeb,
        "input": AppObserver.rolesInput,
        "menus": AppObserver.rolesMenus,
        "controls": AppObserver.rolesControls,
        "unknown": AppObserver.rolesUnknown
    ]
    
    private init() {
        // 1. Build Defaults (Union of all groups)
        var defaults: Set<String> = []
        defaults.formUnion(AppObserver.rolesStructural)
        defaults.formUnion(AppObserver.rolesWeb)
        defaults.formUnion(AppObserver.rolesInput)
        defaults.formUnion(AppObserver.rolesMenus)
        defaults.formUnion(AppObserver.rolesControls)
        defaults.formUnion(AppObserver.rolesUnknown)
        self.defaultIgnoredRoles = defaults
        
        // Start with defaults
        self.effectiveIgnoredRoles = defaults
        
        let env = ProcessInfo.processInfo.environment
        
        // 2. Handle Group Enables (MW_ENABLE_GROUP="Structural,Web") -> Removes them from Ignore List
        if let enableGroups = env["MW_ENABLE_GROUP"] {
            let groups = enableGroups.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces).lowercased() }
            for group in groups {
                if let roles = roleGroups[group] {
                    self.effectiveIgnoredRoles.subtract(roles)
                    Logger.monitor.debug("Group Enabled (Un-ignored): \(group.capitalized)")
                }
            }
        }
        
        // 3. Handle Group Disables (MW_DISABLE_GROUP) -> Adds them to Ignore List (Re-enforce defaults or add new ones)
        if let disableGroups = env["MW_DISABLE_GROUP"] {
            let groups = disableGroups.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces).lowercased() }
            for group in groups {
                if let roles = roleGroups[group] {
                    self.effectiveIgnoredRoles.formUnion(roles)
                    Logger.monitor.debug("Group Disabled (Ignored): \(group.capitalized)")
                }
            }
        }
        
        // 4. Handle Specific Role Overrides
        // MW_IGNORE_ROLES: Add specific roles to ignore
        if let ignoreVar = env["MW_IGNORE_ROLES"] {
            let roles = ignoreVar.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
            self.effectiveIgnoredRoles.formUnion(roles)
            Logger.monitor.debug("Ignored specific roles via Env: \(roles)")
        }
        
        // MW_INCLUDE_ROLES: Remove specific roles from ignore list
        if let includeVar = env["MW_INCLUDE_ROLES"] {
            let roles = includeVar.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
            self.effectiveIgnoredRoles.subtract(roles)
            Logger.monitor.debug("Included specific roles via Env: \(roles)")
        }
        
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
        return effectiveIgnoredRoles.contains(role)
    }
}
