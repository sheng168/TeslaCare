//
//  LocationManager.swift
//  TeslaCare
//
//  Created by Jin on 5/9/26.
//

import Foundation
import CoreLocation
import OSLog

private let logger = Logger(subsystem: "com.teslacare", category: "Location")

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var userLocation: CLLocation?
    var latestHeading: CLHeading?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    /// The current compass heading in degrees (true north preferred), or `nil` if unavailable.
    var headingDegrees: Double? {
        guard let latestHeading, latestHeading.headingAccuracy >= 0 else { return nil }
        return latestHeading.trueHeading >= 0 ? latestHeading.trueHeading : latestHeading.magneticHeading
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        authorizationStatus = manager.authorizationStatus
        logger.info("LocationManager initialized, authorizationStatus: \(self.authorizationStatus.rawValue)")
    }

    func requestPermission() {
        logger.info("Requesting location permission")
        manager.requestWhenInUseAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        logger.info("Authorization changed: \(manager.authorizationStatus.rawValue)")
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last
        logger.info("Location updated: \(locations.last?.coordinate.latitude ?? 0), \(locations.last?.coordinate.longitude ?? 0)")
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        latestHeading = newHeading
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        logger.error("Location update failed: \(error)")
    }

    /// Begins compass updates so a heading is available when a photo is captured.
    func startUpdatingHeading() {
        guard CLLocationManager.headingAvailable() else {
            logger.info("Heading unavailable on this device")
            return
        }
        manager.startUpdatingHeading()
    }

    func stopUpdatingHeading() {
        manager.stopUpdatingHeading()
    }

    func refresh() {
        logger.info("Refresh requested, authorizationStatus: \(self.authorizationStatus.rawValue)")
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        default:
            logger.warning("refresh called with unsupported authorization status: \(self.authorizationStatus.rawValue)")
            break
        }
    }
}
