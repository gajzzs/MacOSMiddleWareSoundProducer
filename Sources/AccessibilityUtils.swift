import Cocoa
import ApplicationServices
import os

enum WindowControlEvent: String {
    case close = "window_close"
    case minimize = "window_min"
    case zoom = "window_zoom"
}

class AccessibilityUtils {
    static let shared = AccessibilityUtils()
    
    private let systemWideElement = AXUIElementCreateSystemWide()
    
    private init() {}
    
    func checkElement(at point: CGPoint) -> WindowControlEvent? {
        var element: AXUIElement?
        // Hit test to find the element at cursor
        let error = AXUIElementCopyElementAtPosition(systemWideElement, Float(point.x), Float(point.y), &element)
        
        guard error == .success, let targetElement = element else {
            return nil
        }
        
        // Debug Information
        var role: AnyObject?
        AXUIElementCopyAttributeValue(targetElement, kAXRoleAttribute as CFString, &role)
        
        var subrole: AnyObject?
        AXUIElementCopyAttributeValue(targetElement, kAXSubroleAttribute as CFString, &subrole)
        
        let roleStr = role as? String ?? "UnknownRole"
        let subroleStr = subrole as? String ?? "UnknownSubrole"
        
        Logger.access.debug("Clicked Element -> Role: \(roleStr, privacy: .public), Subrole: \(subroleStr, privacy: .public)")
        
        // Check Subrole first (Standard macOS buttons)
        if isWindowControl(subrole: subroleStr) {
             return mapSubrole(subroleStr)
        }
        
        // PARENT TRAVERSAL:
        // Sometimes valid buttons contain icons/images that intercept the click.
        // We walk up the tree (max 3 levels) to find a Button role.
        var currentElement = targetElement
        for _ in 0..<3 {
            var parent: AnyObject?
            AXUIElementCopyAttributeValue(currentElement, kAXParentAttribute as CFString, &parent)
            
            guard let parentElement = parent else { break }
            currentElement = parentElement as! AXUIElement
            
            var pRole: AnyObject?
            var pSubrole: AnyObject?
            AXUIElementCopyAttributeValue(currentElement, kAXRoleAttribute as CFString, &pRole)
            AXUIElementCopyAttributeValue(currentElement, kAXSubroleAttribute as CFString, &pSubrole)
            
            let pRoleStr = pRole as? String ?? ""
            let pSubroleStr = pSubrole as? String ?? ""
            
            Logger.access.debug("Parent -> Role: \(pRoleStr, privacy: .public), Subrole: \(pSubroleStr, privacy: .public)")
            
            if isWindowControl(subrole: pSubroleStr) {
                return mapSubrole(pSubroleStr)
            }
        }
        
        // Fallback: Check Description/Title for non-standard apps (e.g. "Close")
        return checkAttributes(element: targetElement)
    }
    
    private func isWindowControl(subrole: String) -> Bool {
        return subrole == kAXCloseButtonSubrole ||
               subrole == kAXMinimizeButtonSubrole ||
               subrole == kAXZoomButtonSubrole
    }
    
    private func mapSubrole(_ subrole: String) -> WindowControlEvent? {
        switch subrole {
        case kAXCloseButtonSubrole: return .close
        case kAXMinimizeButtonSubrole: return .minimize
        case kAXZoomButtonSubrole: return .zoom
        default: return nil
        }
    }
    
    private func checkAttributes(element: AXUIElement) -> WindowControlEvent? {
        // Check Title
        var title: AnyObject?
        AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &title)
        if let titleStr = title as? String {
            if titleStr.lowercased().contains("close") { return .close }
            if titleStr.lowercased().contains("minimize") { return .minimize }
            if titleStr.lowercased().contains("zoom") || titleStr.lowercased().contains("fullscreen") { return .zoom }
        }
        
        // Check Description
        var desc: AnyObject?
        AXUIElementCopyAttributeValue(element, kAXDescriptionAttribute as CFString, &desc)
        if let descStr = desc as? String {
            if descStr.lowercased().contains("close") { return .close }
            if descStr.lowercased().contains("minimize") { return .minimize }
            if descStr.lowercased().contains("zoom") { return .zoom }
        }
        
        return nil
    }
}
