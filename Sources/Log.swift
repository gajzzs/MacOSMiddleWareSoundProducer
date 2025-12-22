import os

extension Logger {
    private static let subsystem = "com.middleware.SoundProducer"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let sound = Logger(subsystem: subsystem, category: "sound")
    static let eventTap = Logger(subsystem: subsystem, category: "eventTap")
    static let access = Logger(subsystem: subsystem, category: "accessibility")
    static let monitor = Logger(subsystem: subsystem, category: "monitor") // File, Window, Network
    static let config = Logger(subsystem: subsystem, category: "config")
}
