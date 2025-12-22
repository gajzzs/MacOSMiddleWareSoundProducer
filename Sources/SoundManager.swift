import Cocoa
import AVFoundation
import os

class SoundManager {
    static let shared = SoundManager()
    
    private var eventSoundPaths: [String: String] = [:]
    private var keySoundPaths: [Int: String] = [:] // Map KeyCode -> FilePath
    private var activePlayers: [String: AVAudioPlayer] = [:] // For continuous events
    private var oneShotPlayers: [AVAudioPlayer] = [] // Keep ref for cleanup
    private var lastPlayed: [String: Date] = [:] // For throttling discrete events
    
    // Concurrent queue for safe reading/writing of lastPlayed if needed, 
    // but simple dispatch to main for playback is safer for audio logic.
    private let queue = DispatchQueue(label: "com.middleware.sound", qos: .userInteractive)
    
    private var isMuted = false
    
    private init() {}
    
    func setMuted(_ muted: Bool) {
        self.isMuted = muted
        // Stop any continuous sounds immediately if muted
        if muted {
            for (_, player) in activePlayers {
                player.stop()
            }
            activePlayers.removeAll()
        }
    }
    
    func configure(with config: SoundConfig) {
        self.eventSoundPaths = config.events
        
        // Load manual key mappings from config
        if let keys = config.keys {
            for (k, v) in keys {
                if let code = Int(k) {
                    keySoundPaths[code] = v
                }
            }
        }
        
        Logger.sound.info("🔊 SoundManager configured with \(config.events.count) events and \(self.keySoundPaths.count, privacy: .public) key sounds.")
    }
    
    func playKey(keycode: Int64) {
        let macCode = Int(keycode)
        
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // Throttle specific key
            let now = Date()
            let throttleKey = "key_\(macCode)" 
            
            // Note: lastPlayed is accessed on 'queue'. Safe as long as only this queue touches it.
            // Check per-key throttle
            if let last = self.lastPlayed[throttleKey], now.timeIntervalSince(last) < 0.05 {
                return
            }
            self.lastPlayed[throttleKey] = now
            
            // Direct Lookup (Config is now MacOS Code -> Path)
            if let path = self.keySoundPaths[macCode] {
                self.playSound(path: path, event: throttleKey, loop: false)
            } else {
                // Fallback to generic "key_down" from config.json
                if let path = self.eventSoundPaths["key_down"] {
                   self.playSound(path: path, event: "key_down", loop: false) 
                }
            }
        }
    }
    
    func play(event: String) {
        guard let path = eventSoundPaths[event] else { return }
        
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // Throttle
            let now = Date()
            let threshold = (event == "key_down") ? 0.05 : 0.1
            
            if let last = self.lastPlayed[event], now.timeIntervalSince(last) < threshold {
                return
            }
            self.lastPlayed[event] = now
            
            self.playSound(path: path, event: event, loop: false)
        }
    }
    
    func startContinuous(event: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // If already playing this event, do nothing
            if self.activePlayers[event]?.isPlaying == true { return }
            
            guard let path = self.eventSoundPaths[event] else { return }
            self.playSoundOnMain(path: path, event: event, loop: true)
        }
    }
    
    func stopContinuous(event: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let player = self.activePlayers[event] {
                if player.isPlaying {
                    player.setVolume(0, fadeDuration: 0.2) 
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                        player.stop()
                        self?.activePlayers.removeValue(forKey: event)
                    }
                } else {
                    self.activePlayers.removeValue(forKey: event)
                }
            }
        }
    }

    private func playSound(path: String, event: String, loop: Bool) {
        // Dispatch to Main Thread for AVAudioPlayer interactions
        DispatchQueue.main.async { [weak self] in
            self?.playSoundOnMain(path: path, event: event, loop: loop)
        }
    }
    
    // Must be called on Main Thread
    private func playSoundOnMain(path: String, event: String, loop: Bool) {
        if isMuted { return }
        
        if !FileManager.default.fileExists(atPath: path) {
            Logger.sound.warning("Sound file not found: \(path, privacy: .public)")
            return
        }
        
        let url = URL(fileURLWithPath: path)
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            
            if loop {
                player.numberOfLoops = -1 // Infinite loop
                player.volume = 1.0
                activePlayers[event] = player
                player.play()
            } else {
                player.numberOfLoops = 0
                player.volume = 1.0
                player.play()
                
                oneShotPlayers.append(player)
                
                // Cleanup after duration
                DispatchQueue.main.asyncAfter(deadline: .now() + player.duration + 0.5) { [weak self] in
                    self?.oneShotPlayers.removeAll(where: { $0 == player })
                }
            }
        } catch {
            Logger.sound.error("Failed to create AVAudioPlayer for: \(path, privacy: .public) | \(error, privacy: .public)")
        }
    }
    
    func playSystemBeep() {
        DispatchQueue.main.async {
            NSSound.beep()
        }
    }
}
