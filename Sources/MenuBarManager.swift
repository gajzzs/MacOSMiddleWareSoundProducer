import Cocoa

class MenuBarManager: NSObject {
    static let shared = MenuBarManager()
    
    private var statusItem: NSStatusItem!
    private var isMuted: Bool = false
    
    func setup() {
        // Create Status Item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // Use a system symbol (Speaker or similar)
            button.image = NSImage(systemSymbolName: "waveform.circle", accessibilityDescription: "Sound Middleware")
        }
        
        // Create Menu
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Sound Middleware", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        let muteItem = NSMenuItem(title: "Mute", action: #selector(toggleMute), keyEquivalent: "m")
        muteItem.target = self
        menu.addItem(muteItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
    }
    
    @objc func toggleMute(_ sender: NSMenuItem) {
        isMuted.toggle()
        sender.title = isMuted ? "Unmute" : "Mute"
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: isMuted ? "speaker.slash" : "waveform.circle", accessibilityDescription: nil)
        }
        
        // Impl mute logic
        SoundManager.shared.setMuted(isMuted)
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}
