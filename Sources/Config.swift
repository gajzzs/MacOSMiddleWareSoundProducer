import Foundation
import os

struct SoundConfig: Codable {
    let events: [String: String]
    let keys: [String: String]?
}

class ConfigLoader {
    static let shared = ConfigLoader()
    
    private init() {}
    
    func loadConfig() -> SoundConfig? {
        // Paths to search for config.json (Priority Order)
        var pathsToCheck: [String] = []
        
        // 1. Current Working Directory (e.g. where 'swift run' is called)
        pathsToCheck.append(FileManager.default.currentDirectoryPath + "/config.json")
        
        // 2. Executable Directory (useful for binaries)
        if let execPath = Bundle.main.executablePath {
            let execDir = URL(fileURLWithPath: execPath).deletingLastPathComponent().path
            pathsToCheck.append(execDir + "/config.json")
        }
        
        // 3. Documents/MacOSMiddleWareSoundProducer/config.json (Standard User Path)
        if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            pathsToCheck.append(documentsURL.path + "/MacOSMiddleWareSoundProducer/config.json")
        }
        
        Logger.config.debug("Searching for config in: \(pathsToCheck.description, privacy: .public)")
        
        for path in pathsToCheck {
            if FileManager.default.fileExists(atPath: path) {
                do {
                    let data = try Data(contentsOf: URL(fileURLWithPath: path))
                    var config = try JSONDecoder().decode(SoundConfig.self, from: data)
                    Logger.config.info("Loaded config from: \(path, privacy: .public)")
                    
                    // Optional: Resolve relative paths (starts with ./) relative to the config file location
                    config = resolveRelativePaths(config, configPath: path)
                    
                    return config
                } catch {
                    Logger.config.error("Failed to parse config at \(path, privacy: .public): \(error, privacy: .public)")
                }
            }
        }
        
        Logger.config.error("No config.json found in search paths.")
        return nil
    }
    
    private func resolveRelativePaths(_ config: SoundConfig, configPath: String) -> SoundConfig {
        let configDir = URL(fileURLWithPath: configPath).deletingLastPathComponent()
        
        func resolve(_ path: String) -> String {
            if path.hasPrefix("./") || path.hasPrefix("../") {
                // Combine configDir + relativePath
                // Remove the dot? URL(string: path, relativeTo:...) handles it.
                let resolved = configDir.appendingPathComponent(path).standardizedFileURL.path
                return resolved
            }
            return path
        }
        
        var newEvents = config.events
        for (k, v) in newEvents {
            newEvents[k] = resolve(v)
        }
        
        var newKeys: [String: String]? = nil
        if let keys = config.keys {
            newKeys = [:]
            for (k, v) in keys {
                newKeys?[k] = resolve(v)
            }
        }
        
        return SoundConfig(events: newEvents, keys: newKeys)
    }
}
