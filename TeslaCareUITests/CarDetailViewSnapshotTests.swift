//
//  CarDetailViewSnapshotTests.swift
//  TeslaCareUITests
//
//  Created by Jin on 5/7/26.
//
//  Visual regression testing using snapshot comparisons
//

import XCTest

/// These tests create reference screenshots for visual regression testing
/// Run these tests to generate baseline screenshots, then compare against future changes
final class CarDetailViewSnapshotTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Full View Screenshots
    
    @MainActor
    func testSnapshot_EmptyView() throws {
        app.launchArguments.append("EmptyCarState")
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        // Wait for animations
        Thread.sleep(forTimeInterval: 1)
        
        captureSnapshot(name: "01_EmptyState_Full")
    }
    
    @MainActor
    func testSnapshot_HealthyTires_Full() throws {
        app.launchArguments.append("HealthyTires")
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        Thread.sleep(forTimeInterval: 1)
        
        captureSnapshot(name: "02_HealthyTires_Full")
    }
    
    @MainActor
    func testSnapshot_WarningTires_Full() throws {
        app.launchArguments.append("WarningTires")
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        Thread.sleep(forTimeInterval: 1)
        
        captureSnapshot(name: "03_WarningTires_Full")
    }
    
    @MainActor
    func testSnapshot_DangerousTires_Full() throws {
        app.launchArguments.append("DangerousTires")
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        Thread.sleep(forTimeInterval: 1)
        
        captureSnapshot(name: "04_DangerousTires_Full")
    }
    
    @MainActor
    func testSnapshot_WithAllHistory() throws {
        app.launchArguments.append("CompleteHistory")
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        Thread.sleep(forTimeInterval: 1)
        
        // Top section
        captureSnapshot(name: "05_CompleteHistory_Section1")
        
        // Scroll to middle
        app.swipeUp()
        Thread.sleep(forTimeInterval: 0.5)
        captureSnapshot(name: "05_CompleteHistory_Section2")
        
        // Scroll to bottom
        app.swipeUp()
        Thread.sleep(forTimeInterval: 0.5)
        captureSnapshot(name: "05_CompleteHistory_Section3")
    }
    
    // MARK: - Component Detail Screenshots
    
    @MainActor
    func testSnapshot_TireHealthIndicator_Healthy() throws {
        app.launchArguments.append("HealthyTires")
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        Thread.sleep(forTimeInterval: 1)
        
        captureSnapshot(name: "Component_TireHealth_Healthy")
    }
    
    @MainActor
    func testSnapshot_TireHealthIndicator_Warning() throws {
        app.launchArguments.append("WarningTires")
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        Thread.sleep(forTimeInterval: 1)
        
        captureSnapshot(name: "Component_TireHealth_Warning")
    }
    
    @MainActor
    func testSnapshot_TireHealthIndicator_Danger() throws {
        app.launchArguments.append("DangerousTires")
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        Thread.sleep(forTimeInterval: 1)
        
        captureSnapshot(name: "Component_TireHealth_Danger")
    }
    
    @MainActor
    func testSnapshot_ActionButtons() throws {
        app.launchArguments.append("CarWithMeasurements")
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        Thread.sleep(forTimeInterval: 1)
        
        captureSnapshot(name: "Component_ActionButtons")
    }
    
    @MainActor
    func testSnapshot_MeasurementHistory() throws {
        app.launchArguments.append("CarWithMeasurements")
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        // Scroll to measurement history
        app.swipeUp()
        Thread.sleep(forTimeInterval: 1)
        
        captureSnapshot(name: "Component_MeasurementHistory")
    }
    
    @MainActor
    func testSnapshot_RotationHistory() throws {
        app.launchArguments.append("WithRotationHistory")
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        app.swipeUp()
        Thread.sleep(forTimeInterval: 1)
        
        captureSnapshot(name: "Component_RotationHistory")
    }
    
    @MainActor
    func testSnapshot_ReplacementHistory() throws {
        app.launchArguments.append("WithReplacementHistory")
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        app.swipeUp()
        Thread.sleep(forTimeInterval: 1)
        
        captureSnapshot(name: "Component_ReplacementHistory")
    }
    
    @MainActor
    func testSnapshot_AirFilterHistory() throws {
        app.launchArguments.append("WithAirFilterHistory")
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        app.swipeUp()
        app.swipeUp()
        Thread.sleep(forTimeInterval: 1)
        
        captureSnapshot(name: "Component_AirFilterHistory")
    }
    
    // MARK: - Modal/Sheet Screenshots
    
    @MainActor
    func testSnapshot_RotateTiresSheet() throws {
        app.launchArguments.append("CarWithMeasurements")
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        // Tap rotate button
        let rotateButton = app.buttons["Rotate"]
        XCTAssertTrue(rotateButton.exists)
        rotateButton.tap()
        
        Thread.sleep(forTimeInterval: 1)
        
        captureSnapshot(name: "Sheet_RotateTires")
    }
    
    @MainActor
    func testSnapshot_ReplaceTiresSheet() throws {
        app.launchArguments.append("CarWithMeasurements")
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        // Tap replace button
        let replaceButton = app.buttons["Replace"]
        XCTAssertTrue(replaceButton.exists)
        replaceButton.tap()
        
        Thread.sleep(forTimeInterval: 1)
        
        captureSnapshot(name: "Sheet_ReplaceTires")
    }
    
    @MainActor
    func testSnapshot_AddMeasurementSheet() throws {
        app.launchArguments.append("CarWithMeasurements")
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        // Tap add measurement button
        let addButton = app.buttons["Add Measurement"]
        XCTAssertTrue(addButton.exists)
        addButton.tap()
        
        Thread.sleep(forTimeInterval: 1)
        
        captureSnapshot(name: "Sheet_AddMeasurement")
    }
    
    // MARK: - Dark Mode Screenshots
    
    @MainActor
    func testSnapshot_DarkMode_HealthyTires() throws {
        // Enable dark mode
        app.launchArguments.append("HealthyTires")
        app.launch()
        
        // Note: To properly test dark mode, you may need to:
        // 1. Set appearance in scheme
        // 2. Or programmatically set it via launch environment
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        Thread.sleep(forTimeInterval: 1)
        
        captureSnapshot(name: "DarkMode_HealthyTires")
    }
    
    // MARK: - Different Device Sizes
    
    @MainActor
    func testSnapshot_iPhone_SE() throws {
        // Note: Run this test on iPhone SE simulator
        app.launchArguments.append("CarWithMeasurements")
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        Thread.sleep(forTimeInterval: 1)
        
        captureSnapshot(name: "Device_iPhoneSE_CarDetail")
    }
    
    @MainActor
    func testSnapshot_iPhone_ProMax() throws {
        // Note: Run this test on iPhone Pro Max simulator
        app.launchArguments.append("CarWithMeasurements")
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        Thread.sleep(forTimeInterval: 1)
        
        captureSnapshot(name: "Device_iPhoneProMax_CarDetail")
    }
    
    @MainActor
    func testSnapshot_iPad() throws {
        // Note: Run this test on iPad simulator
        app.launchArguments.append("CarWithMeasurements")
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        Thread.sleep(forTimeInterval: 1)
        
        captureSnapshot(name: "Device_iPad_CarDetail")
    }
    
    // MARK: - Accessibility Screenshots
    
    @MainActor
    func testSnapshot_LargeText() throws {
        // Note: Enable larger text sizes in simulator settings
        app.launchArguments.append("CarWithMeasurements")
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        Thread.sleep(forTimeInterval: 1)
        
        captureSnapshot(name: "Accessibility_LargeText")
    }
    
    // MARK: - Helper Methods
    
    private func captureSnapshot(name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

// MARK: - Snapshot Test Plan

/*
 SNAPSHOT TEST PLAN
 ==================
 
 This file creates a comprehensive set of reference screenshots for visual regression testing.
 
 FILE NAMING CONVENTION:
 - Numbered screenshots (01_, 02_) show full view progressions
 - Component_ prefix shows individual component states
 - Sheet_ prefix shows modal presentations
 - DarkMode_ prefix shows dark appearance
 - Device_ prefix shows different device sizes
 - Accessibility_ prefix shows accessibility states
 
 EXPECTED SCREENSHOTS:
 
 Full Views:
 -----------
 01_EmptyState_Full                    - Empty car with no data
 02_HealthyTires_Full                  - Green health indicator, good tread
 03_WarningTires_Full                  - Orange warning indicators
 04_DangerousTires_Full                - Red danger indicators
 05_CompleteHistory_Section1           - Top of view with all history
 05_CompleteHistory_Section2           - Middle section scrolled
 05_CompleteHistory_Section3           - Bottom section scrolled
 
 Components:
 -----------
 Component_TireHealth_Healthy          - Health indicator in green
 Component_TireHealth_Warning          - Health indicator in orange
 Component_TireHealth_Danger           - Health indicator in red
 Component_ActionButtons               - Rotate and Replace buttons
 Component_MeasurementHistory          - List of tire measurements
 Component_RotationHistory             - Rotation events list
 Component_ReplacementHistory          - Replacement events list
 Component_AirFilterHistory            - Air filter changes list
 
 Sheets/Modals:
 --------------
 Sheet_RotateTires                     - Rotate tires modal
 Sheet_ReplaceTires                    - Replace tires modal
 Sheet_AddMeasurement                  - Add measurement modal
 
 Dark Mode:
 ----------
 DarkMode_HealthyTires                 - Dark appearance variation
 
 Devices:
 --------
 Device_iPhoneSE_CarDetail             - Small screen layout
 Device_iPhoneProMax_CarDetail         - Large screen layout
 Device_iPad_CarDetail                 - Tablet layout
 
 Accessibility:
 --------------
 Accessibility_LargeText               - Dynamic Type at larger sizes
 
 USAGE:
 ------
 1. Run all snapshot tests to generate baseline images
 2. Store baseline images in version control
 3. Re-run tests after UI changes to compare
 4. Review differences and update baselines if intentional
 5. Use in CI/CD to catch unintended visual regressions
 
 RECOMMENDED TOOLS:
 -----------------
 - Xcode's built-in screenshot comparison
 - Third-party tools like SnapshotTesting by Point-Free
 - Visual diff tools for image comparison
 
 */
