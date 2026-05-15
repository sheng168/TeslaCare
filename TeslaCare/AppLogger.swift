//
//  AppLogger.swift
//  TeslaCare
//

import Foundation
import OSLog

/// Drop-in replacement for Logger that also writes to a dated log file in DEBUG builds.
final class AppLogger {
    private let osLogger: Logger
    private let category: String

    init(subsystem: String = "com.teslacare", category: String) {
        self.osLogger = Logger(subsystem: subsystem, category: category)
        self.category = category
    }

    func info(_ message: @autoclosure () -> String) {
        let msg = message()
        osLogger.info("\(msg, privacy: .public)")
        #if DEBUG
        FileLogStore.shared.write(msg, category: category, level: "INFO")
        #endif
    }

    func error(_ message: @autoclosure () -> String) {
        let msg = message()
        osLogger.error("\(msg, privacy: .public)")
        #if DEBUG
        FileLogStore.shared.write(msg, category: category, level: "ERROR")
        #endif
    }

    func warning(_ message: @autoclosure () -> String) {
        let msg = message()
        osLogger.warning("\(msg, privacy: .public)")
        #if DEBUG
        FileLogStore.shared.write(msg, category: category, level: "WARN")
        #endif
    }

    func debug(_ message: @autoclosure () -> String) {
        let msg = message()
        osLogger.debug("\(msg, privacy: .public)")
        #if DEBUG
        FileLogStore.shared.write(msg, category: category, level: "DEBUG")
        #endif
    }
}

// MARK: - File log store (DEBUG only)

#if DEBUG
final class FileLogStore {
    static let shared = FileLogStore()

    private let fileURL: URL
    private let fileHandle: FileHandle?
    private let queue = DispatchQueue(label: "com.teslacare.filelog", qos: .utility)

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let logsDir = docs.appendingPathComponent("Logs", isDirectory: true)
        try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)
        Self.pruneOldLogs(in: logsDir)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let filename = formatter.string(from: Date()) + ".log"
        fileURL = logsDir.appendingPathComponent(filename)

        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        }
        fileHandle = try? FileHandle(forWritingTo: fileURL)
        fileHandle?.seekToEndOfFile()

        write("=== Session started ===", category: "App", level: "INFO")
    }

    func write(_ message: String, category: String, level: String) {
        queue.async { [weak self] in
            guard let self else { return }
            let ts = Self.timestamp()
            let line = "\(ts) [\(level)] [\(category)] \(message)\n"
            guard let data = line.data(using: .utf8) else { return }
            fileHandle?.write(data)
        }
    }

    static var currentLogURL: URL { shared.fileURL }

    static var allLogURLs: [URL] {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let logsDir = docs.appendingPathComponent("Logs")
        let files = (try? FileManager.default.contentsOfDirectory(
            at: logsDir, includingPropertiesForKeys: nil)) ?? []
        return files.filter { $0.pathExtension == "log" }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
    }

    private static func pruneOldLogs(in dir: URL) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let files = (try? FileManager.default.contentsOfDirectory(
            at: dir, includingPropertiesForKeys: nil)) ?? []
        for file in files where file.pathExtension == "log" {
            let name = file.deletingPathExtension().lastPathComponent
            if let date = logDateFormatter.date(from: name), date < cutoff {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }

    private static func timestamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f.string(from: Date())
    }

    private static let logDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    deinit { try? fileHandle?.close() }
}
#endif
