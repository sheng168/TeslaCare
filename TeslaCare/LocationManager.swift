//
//  LocationManager.swift
//  TeslaCare
//
//  Created by Jin on 5/9/26.
//

import Foundation
import CoreLocation
import OSLog

private let logger = AppLogger(subsystem: "com.teslacare", category: "Location")

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var userLocation: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined

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

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        logger.error("Location update failed: \(error)")
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
