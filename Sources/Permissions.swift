import Cocoa
import ApplicationServices
import os

class PermissionsManager {
    static func checkAccessibility() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if accessEnabled {
            Logger.app.info("Accessibility Permissions: Granted")
        } else {
            Logger.app.error("Accessibility Permissions: Denied")
            Logger.app.info("Please enable Accessibility for this app in System Settings -> Privacy & Security -> Accessibility")
        }
        
        return accessEnabled
    }
}
