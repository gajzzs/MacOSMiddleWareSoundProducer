import Cocoa
import ApplicationServices
import os

class EventTapManager {
    static let shared = EventTapManager()
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    private init() {}
    
    func start() {
        Logger.eventTap.info("Starting Event Tap...")
        
        let eventMask = (1 << CGEventType.leftMouseDown.rawValue) | (1 << CGEventType.keyDown.rawValue)
        
        // C-Function callback
        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            if type == .tapDisabledByTimeout {
                Logger.eventTap.warning("Event Tap Disabled by Timeout - Re-enabling...")
                if let tap = EventTapManager.shared.eventTap {
                    CGEvent.tapEnable(tap: tap, enable: true)
                }
                return Unmanaged.passUnretained(event)
            }
            
            if type == .leftMouseDown {
                let location = event.location
                
                // Process in background to avoid lag
                DispatchQueue.global(qos: .userInteractive).async {
                    if let eventType = AccessibilityUtils.shared.checkElement(at: location) {
                        Logger.eventTap.debug("Detected UI Event: \(eventType.rawValue, privacy: .public)")
                        SoundManager.shared.play(event: eventType.rawValue)
                    }
                }
            }
            
            if type == .keyDown {
                 let keycode = event.getIntegerValueField(.keyboardEventKeycode)
                 DispatchQueue.global(qos: .userInteractive).async {
                     SoundManager.shared.playKey(keycode: keycode)
                 }
            }
            
            return Unmanaged.passUnretained(event)
        }
        
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly, // ListenOnly does not block events, safest for middleware
            eventsOfInterest: CGEventMask(eventMask),
            callback: callback,
            userInfo: nil
        ) else {
            Logger.eventTap.error("Failed to create Event Tap. Permissions likely needed.")
            return
        }
        
        self.eventTap = tap
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = runLoopSource
        
        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
            Logger.eventTap.info("Event Tap Started")
        }
    }
}
