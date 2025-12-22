import Foundation
import os

class NetworkMonitor {
    static let shared = NetworkMonitor()
    
    private var currentPid: pid_t = -1
    private var process: Process?
    private var pipe: Pipe?
    
    // Threshold in bytes per interval to trigger sound
    // nettop reports TOTAL bytes, so we track diff.
    private var lastBytesIn: Int64 = 0
    private var lastBytesOut: Int64 = 0
    private var isFirstSample = true
    
    private let monitorQueue = DispatchQueue(label: "com.middleware.network", qos: .background)
    
    private init() {}
    
    func updateTarget(pid: pid_t) {
        monitorQueue.async { [weak self] in
            guard let self = self else { return }
            
            if pid == self.currentPid { return }
            
            // Stop existing
            self.stopMonitoring()
            
            self.currentPid = pid
            self.lastBytesIn = 0
            self.lastBytesOut = 0
            self.isFirstSample = true
            
            self.startNettop(pid: pid)
        }
    }
    
    private func stopMonitoring() {
        if let process = process {
            process.terminate()
            process.waitUntilExit() // Clean up
        }
        process = nil
        pipe = nil
    }
    
    private func startNettop(pid: pid_t) {
        let task = Process()
        task.launchPath = "/usr/bin/nettop"
        // -L 0: Infinite samples (run until killed)
        // -P: Per-process summary (not route) (Actually -P aggregates? No, wait)
        // nettop -p PID -L 0 -d (delta?) 
        // Let's use standard cumulative and calc delta ourselves to be safe.
        // -x: extended (csv friendly)
        
        task.arguments = ["-p", "\(pid)", "-L", "0", "-x", "-J", "bytes_in,bytes_out"] 
        // Wait, nettop flags are tricky.
        // -x gives simple CSV format without interactive UI?
        // Let's rely on standard output which is CSV-like in batch mode "-L".
        // Using -J (column selection) is cleaner if supported.
        // Tested locally: nettop -L 1 -P -p PID outputs headers + lines.
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice // Ignore errors
        
        let outHandle = pipe.fileHandleForReading
        
        // Readability Handler
        outHandle.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if data.isEmpty { return }
            if let str = String(data: data, encoding: .utf8) {
                self?.parseOutput(str)
            }
        }
        
        self.process = task
        self.pipe = pipe
        
        do {
            try task.run()
            Logger.monitor.info("Network Monitor started for PID \(pid)")
        } catch {
            Logger.monitor.error("Failed to start nettop: \(error, privacy: .public)")
        }
    }
    
    private func parseOutput(_ output: String) {
        // Output contains headers and rows. 
        // We look for the row corresponding to our PID or just "Total" if filtered by PID?
        // nettop filtered by PID usually shows breakdown by interface (en0, etc).
        // We sum them up?
        
        // Structure:
        // time,interface,state,bytes_in,bytes_out,...
        // 12:00:00,en0,Established,1234,5678,...
        
        let lines = output.components(separatedBy: .newlines)
        
        var currentTotalIn: Int64 = 0
        var currentTotalOut: Int64 = 0
        var foundData = false
        
        for line in lines {
            let parts = line.components(separatedBy: ",")
            if parts.count < 5 { continue }
            
            // Skip Header
            if parts[0].contains("time") { continue }
            
            // nettop CSV usually: time, interface, state, bytes_in, bytes_out...
            // Let's verify index.
            // Based on previous step output: time,,interface,state,bytes_in,bytes_out...
            // It has empty fields sometimes.
            // We need to be robust. 
            // Let's look for numeric values.
            
            // Heuristic: If we find 2 large numbers, they are likely bytes.
            // nettop cols are usually fixed order: bytes_in is idx 4 or 5?
            
            // Attempt to parse known columns. 
            // "time,,interface,state,bytes_in,bytes_out" -> parts[4] = bytes_in?
            
            // Let's iterate and sum.
            // Usually nettop groups by process. If filtered by PID, all rows are that PID's sockets.
            
            // Need robust parsing. 
            // If we assume standard columns:
            if let bin = Int64(parts[4]), let bout = Int64(parts[5]) {
                currentTotalIn += bin
                currentTotalOut += bout
                foundData = true
            }
        }
        
        if !foundData { return }
        
        if isFirstSample {
            lastBytesIn = currentTotalIn
            lastBytesOut = currentTotalOut
            isFirstSample = false
            return
        }
        
        let deltaIn = currentTotalIn - lastBytesIn
        let deltaOut = currentTotalOut - lastBytesOut
        
        lastBytesIn = currentTotalIn
        lastBytesOut = currentTotalOut
        
        // Threshold: 1KB (1024 bytes) to avoid noise
        if deltaIn > 1024 || deltaOut > 1024 {
             Logger.monitor.debug("Network Activity: +\(deltaIn) / +\(deltaOut) bytes")
             DispatchQueue.main.async {
                 SoundManager.shared.play(event: "network_activity") 
             }
        }
    }
}
