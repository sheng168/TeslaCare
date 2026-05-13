//
//  NotificationManager.swift
//  TeslaCare
//

import Foundation
import SwiftData
import UserNotifications
import OSLog

private let logger = Logger(subsystem: "com.teslacare", category: "Notifications")

enum NotificationManager {
    static let hour = 60 * 60.0
    static let day = 24 * hour
    #if DEBUG
    static let reminderInterval: TimeInterval = 2 * hour // 2 minutes
    #else
    static let reminderInterval: TimeInterval = 14 * day  // 2 weeks
    #endif

    // Cancels any existing reminder for this car and schedules a new one
    // 2 weeks after its lastUpdatedAt (or dateAdded if never updated).
    // If already overdue, fires in 60 seconds so the user gets it promptly.
    static func scheduleUpdateReminder(for car: Car) {
        let center = UNUserNotificationCenter.current()
        let id = notificationID(for: car)

        center.removePendingNotificationRequests(withIdentifiers: [id])

        let lastUpdate = car.lastUpdatedAt ?? car.dateAdded
        let fireDate = lastUpdate.addingTimeInterval(reminderInterval)
        let delay = max(60, fireDate.timeIntervalSinceNow)

        let content = UNMutableNotificationContent()
        content.title = "Check in on \(car.displayName)"
        content.body = "No updates in 2 weeks — sync with Tesla or record new measurements."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
        logger.info("Scheduled update reminder for car: \(car.displayName), delay: \(delay)s")
    }

    static func cancelUpdateReminder(for car: Car) {
        logger.info("Cancelling update reminder for car: \(car.displayName)")
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [notificationID(for: car)])
    }

    static func requestPermission() {
        logger.info("Requesting notification permission")
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { granted, error in
                if let error {
                    logger.error("Notification permission request failed: \(error)")
                } else {
                    logger.info("Notification permission granted: \(granted)")
                }
            }
    }

    // Stable per-car identifier: prefer VIN (globally unique), fall back to model ID hash.
    private static func notificationID(for car: Car) -> String {
        if let vin = car.vin, !vin.isEmpty {
            return "car-update-\(vin)"
        }
        return "car-update-\(car.persistentModelID.hashValue)"
    }
}
