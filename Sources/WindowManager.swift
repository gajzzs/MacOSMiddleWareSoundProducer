import Cocoa
import CoreGraphics
import os

class WindowManager {
    static let shared = WindowManager()
    
    private var timer: Timer?
    private var previousWindows: [CGWindowID: CGRect] = [:]
    private var isFirstRun = true
    
    // Faster polling for smoother feedback
    func startMonitoring(interval: TimeInterval = 0.1) {
        Logger.monitor.info(" Starting Window Monitor (Poll Interval: \(interval, privacy: .public)s)...")
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.checkWindows()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkWindows() {
        // OptionOnScreenOnly: Visible windows. 
        // Note: Minimized windows are NOT 'OnScreen', so they will "disappear" from this list.
        // OptionAll: Includes off-screen, but might be too noisy.
        // Let's use OptionOnScreenOnly first to detect "Visual Changes".
        guard let windowInfoList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] else {
            return
        }
        
        var currentWindows: [CGWindowID: CGRect] = [:]
        
        for info in windowInfoList {
            // Filter: Standard Window Layer (0) only. Skip MenuBars, Dock, etc.
            guard let layer = info[kCGWindowLayer as String] as? Int, layer == 0 else { continue }
            
            // Filter: Must have a valid ID and Bounds
            guard let id = info[kCGWindowNumber as String] as? CGWindowID,
                  let boundsDict = info[kCGWindowBounds as String] as? [String: Any],
                  let bounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary) else { continue }
            
            // Filter: Ignore small transparent overlays or tooltips (heuristic)
            if bounds.width < 50 || bounds.height < 50 { continue }
            
            currentWindows[id] = bounds
        }
        
        if isFirstRun {
            previousWindows = currentWindows
            isFirstRun = false
            return
        }
        
        // compare current with previous
        
        // 1. Detect Removed (Closed/Minimized/Hidden)
        for (id, _) in previousWindows {
            if currentWindows[id] == nil {
                // Window is no longer on screen
                Logger.monitor.debug("Window Disappeared (Closed/Minimized/Hidden): ID \(id)")
                SoundManager.shared.play(event: "window_close") // Map to close sound for now
            }
        }
        
        // 2. Detect Added (Opened/Restored)
        for (id, _) in currentWindows {
            if previousWindows[id] == nil {
                Logger.monitor.debug("Window Appeared: ID \(id)")
                // SoundManager.shared.play(event: "window_open") 
            }
        }
        
        // 3. Detect Moved/Resized (Continuous)
        var isAnyWindowMoving = false
        var isAnyWindowResizing = false
        
        for (id, currentBounds) in currentWindows {
            if let prevBounds = previousWindows[id] {
                if currentBounds != prevBounds {
                    if currentBounds.size != prevBounds.size {
                        isAnyWindowResizing = true
                    } else {
                        isAnyWindowMoving = true
                    }
                }
            }
        }
        
        // Handle Continuous Audio State
        if isAnyWindowResizing {
            SoundManager.shared.startContinuous(event: "window_resize")
        } else {
            SoundManager.shared.stopContinuous(event: "window_resize")
        }
        
        if isAnyWindowMoving {
            SoundManager.shared.startContinuous(event: "window_move")
        } else {
            SoundManager.shared.stopContinuous(event: "window_move")
        }
        
        previousWindows = currentWindows
    }
}
