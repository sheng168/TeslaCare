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

    // MARK: - Weekly Tire Check

    static func scheduleWeeklyTireCheck() {
        var components = DateComponents()
        components.weekday = 1 // Sunday
        components.hour = 9
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = "Weekly Tire Check"
        content.body = "Take a quick look at your tires — check pressure and tread depth."
        content.sound = .default

        let request = UNNotificationRequest(identifier: "weekly-tire-check", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
        logger.info("Scheduled weekly tire check")
    }

    static func cancelWeeklyTireCheck() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["weekly-tire-check"])
        logger.info("Cancelled weekly tire check")
    }

    // MARK: - Low Tread Alert

    static func scheduleLowTreadAlerts(for tires: [Tire], warningThreshold: Double) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["low-tread-alert"])

        let lowTires = tires.filter {
            guard let depth = $0.latestMeasurement?.treadDepth else { return false }
            return depth <= warningThreshold
        }
        guard !lowTires.isEmpty else {
            logger.info("No tires below warning threshold — skipping low tread alert")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Low Tread Depth Alert"
        content.body = lowTires.count == 1
            ? "\(lowTires[0].displayName) has low tread depth and may need attention."
            : "\(lowTires.count) tires have low tread depth and may need attention."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
        let request = UNNotificationRequest(identifier: "low-tread-alert", content: content, trigger: trigger)
        center.add(request)
        logger.info("Scheduled low tread alert for \(lowTires.count) tire(s)")
    }

    static func cancelLowTreadAlerts() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["low-tread-alert"])
        logger.info("Cancelled low tread alerts")
    }

    // MARK: - Rotation Reminders

    static func scheduleRotationReminders(for cars: [Car], intervalMiles: Double) {
        let center = UNUserNotificationCenter.current()
        for car in cars {
            let id = rotationNotificationID(for: car)
            center.removePendingNotificationRequests(withIdentifiers: [id])

            guard let currentMileage = car.mileage else { continue }
            let lastRotationMileage = car.rotationEvents?.compactMap(\.mileage).max() ?? 0
            let milesSinceRotation = Double(currentMileage - lastRotationMileage)
            guard milesSinceRotation >= intervalMiles else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Tire Rotation Due — \(car.displayName)"
            content.body = "\(Int(milesSinceRotation).formatted()) miles since last rotation. Time to rotate your tires."
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            center.add(request)
            logger.info("Scheduled rotation reminder for car: \(car.displayName)")
        }
    }

    static func cancelRotationReminders(for cars: [Car]) {
        let ids = cars.map { rotationNotificationID(for: $0) }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        logger.info("Cancelled rotation reminders")
    }

    // MARK: - Identifiers

    // Stable per-car identifier: prefer VIN (globally unique), fall back to model ID hash.
    private static func notificationID(for car: Car) -> String {
        if let vin = car.vin, !vin.isEmpty {
            return "car-update-\(vin)"
        }
        return "car-update-\(car.persistentModelID.hashValue)"
    }

    private static func rotationNotificationID(for car: Car) -> String {
        if let vin = car.vin, !vin.isEmpty {
            return "rotation-due-\(vin)"
        }
        return "rotation-due-\(car.persistentModelID.hashValue)"
    }
}
