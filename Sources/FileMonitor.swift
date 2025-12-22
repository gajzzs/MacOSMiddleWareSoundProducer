import Cocoa
import CoreServices
import os

class FileMonitor {
    static let shared = FileMonitor()
    
    private var lastTriggerTime: Date = Date.distantPast
    private let throttleInterval: TimeInterval = 0.1
    private var streamRef: FSEventStreamRef?
    
    private init() {}
    
    func startMonitoring() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.path
        let desktopPath = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!.path
        
        let pathsToWatch = [documentsPath, desktopPath] as CFArray
        
        Logger.monitor.info("Monitoring paths for Disk I/O: \(pathsToWatch, privacy: .public)")
        
        var context = FSEventStreamContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        
        // Define callback closure
        let callback: FSEventStreamCallback = { (streamRef, clientCallBackInfo, numEvents, eventPaths, eventFlags, eventIds) in
            FileMonitor.shared.handleEvent(numEvents: numEvents)
        }
        
        // Flags: FileEvents allows file-level granularity (vs folder level)
        let flags = FSEventStreamCreateFlags(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents)
        
        // Latency: 0.1s to balance responsiveness and performance
        streamRef = FSEventStreamCreate(kCFAllocatorDefault,
                                        callback,
                                        &context,
                                        pathsToWatch,
                                        FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
                                        0.1,
                                        flags)
        
        if let stream = streamRef {
            FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
            FSEventStreamStart(stream)
            Logger.monitor.info("File Monitor Started")
        } else {
            Logger.monitor.error("Failed to start File Monitor")
        }
    }
    
    func handleEvent(numEvents: Int) {
        let now = Date()
        // Simple throttle to prevent sound spam during bulk operations
        if now.timeIntervalSince(lastTriggerTime) > throttleInterval {
            lastTriggerTime = now
             Logger.monitor.debug("Disk Event Detected (\(numEvents) file changes)")
            SoundManager.shared.play(event: "disk_write")
        }
    }
}
