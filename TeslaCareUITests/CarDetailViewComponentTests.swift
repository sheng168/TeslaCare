//
//  CarDetailViewComponentTests.swift
//  TeslaCareUITests
//
//  Created by Jin on 5/7/26.
//

import XCTest

/// XCTest suite for CarDetailView component tests
/// These tests validate individual UI components and their states
class CarDetailViewComponentTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Header Component Tests
    
    func testCarInfoHeaderDisplay() throws {
        app.launchArguments = ["UI-Testing", "CarWithMeasurements"]
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        // Verify car name
        let carName = app.staticTexts["My Tesla"]
        XCTAssertTrue(carName.exists)
        
        // Verify car details
        let carDetails = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '2023'")).firstMatch
        XCTAssertTrue(carDetails.exists)
        
        // Screenshot
        takeScreenshot(name: "CarInfoHeader_Display")
    }
    
    func testTireHealthIndicator() throws {
        app.launchArguments = ["UI-Testing", "CarWithMeasurements"]
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        // Verify health label
        let healthLabel = app.staticTexts["Overall Tire Health"]
        XCTAssertTrue(healthLabel.exists)
        
        // Verify progress view
        let progressView = app.progressIndicators.firstMatch
        XCTAssertTrue(progressView.exists)
        
        // Verify percentage display
        let percentage = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '%'")).firstMatch
        XCTAssertTrue(percentage.exists)
        
        // Screenshot
        takeScreenshot(name: "TireHealthIndicator")
    }
    
    func testAverageTreadDepthDisplay() throws {
        app.launchArguments = ["UI-Testing", "CarWithMeasurements"]
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        // Verify average is shown
        let average = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Average:'")).firstMatch
        XCTAssertTrue(average.exists)
        
        // Screenshot
        takeScreenshot(name: "AverageTreadDepth")
    }
    
    // MARK: - Health Status Tests
    
    func testHealthyTiresStatus() throws {
        app.launchArguments = ["UI-Testing", "HealthyTires"]
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        // Verify high percentage
        let percentage = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '%'")).firstMatch
        XCTAssertTrue(percentage.exists)
        
        // Screenshot
        takeScreenshot(name: "HealthStatus_Healthy")
    }
    
    func testWarningTiresStatus() throws {
        app.launchArguments = ["UI-Testing", "WarningTires"]
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        // Verify warning icons
        let warningCount = app.images.matching(NSPredicate(format: "identifier CONTAINS 'exclamationmark'")).count
        XCTAssertGreaterThan(warningCount, 0)
        
        // Screenshot
        takeScreenshot(name: "HealthStatus_Warning")
    }
    
    func testDangerousTiresStatus() throws {
        app.launchArguments = ["UI-Testing", "DangerousTires"]
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        // Verify danger icons
        let dangerCount = app.images.matching(NSPredicate(format: "identifier CONTAINS 'triangle'")).count
        XCTAssertGreaterThan(dangerCount, 0)
        
        // Screenshot
        takeScreenshot(name: "HealthStatus_Danger")
    }
    
    // MARK: - Action Buttons Tests
    
    func testRotateButton() throws {
        app.launchArguments = ["UI-Testing", "CarWithMeasurements"]
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        let rotateButton = app.buttons["Rotate"]
        XCTAssertTrue(rotateButton.exists)
        XCTAssertTrue(rotateButton.isEnabled)
        
        // Screenshot
        takeScreenshot(name: "ActionButton_Rotate")
    }
    
    func testReplaceButton() throws {
        app.launchArguments = ["UI-Testing", "CarWithMeasurements"]
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        let replaceButton = app.buttons["Replace"]
        XCTAssertTrue(replaceButton.exists)
        XCTAssertTrue(replaceButton.isEnabled)
        
        // Screenshot
        takeScreenshot(name: "ActionButton_Replace")
    }
    
    func testAddMeasurementButton() throws {
        app.launchArguments = ["UI-Testing", "CarWithMeasurements"]
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        let addButton = app.buttons["Add Measurement"]
        XCTAssertTrue(addButton.exists)
        
        // Screenshot
        takeScreenshot(name: "ActionButton_AddMeasurement")
    }
    
    // MARK: - Measurement History Tests
    
    func testEmptyMeasurementHistory() throws {
        app.launchArguments = ["UI-Testing", "EmptyCarState"]
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        // Verify empty state
        let noMeasurements = app.staticTexts["No Measurements"]
        XCTAssertTrue(noMeasurements.exists)
        
        let emptyDescription = app.staticTexts["Add tire measurements to track tread depth over time"]
        XCTAssertTrue(emptyDescription.exists)
        
        // Screenshot
        takeScreenshot(name: "MeasurementHistory_Empty")
    }
    
    func testMeasurementsList() throws {
        app.launchArguments = ["UI-Testing", "CarWithMeasurements"]
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        // Verify measurement history header
        let historyHeader = app.staticTexts["Measurement History"]
        XCTAssertTrue(historyHeader.exists)
        
        // Verify measurements exist
        let measurements = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '/32\"'"))
        XCTAssertGreaterThan(measurements.count, 0)
        
        // Screenshot
        takeScreenshot(name: "MeasurementHistory_WithData")
    }
    
    func testMeasurementRowComponents() throws {
        app.launchArguments = ["UI-Testing", "CarWithMeasurements"]
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        // Verify position label exists
        let position = app.staticTexts["Front Left"]
        XCTAssertTrue(position.exists || app.staticTexts["Front Right"].exists)
        
        // Verify tread depth value
        let treadDepth = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '/32\"'")).firstMatch
        XCTAssertTrue(treadDepth.exists)
        
        // Screenshot
        takeScreenshot(name: "MeasurementRow_Components")
    }
    
    // MARK: - Event History Tests
    
    func testRotationHistory() throws {
        app.launchArguments = ["UI-Testing", "WithRotationHistory"]
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        // Scroll to rotation history
        app.swipeUp()
        
        let rotationHistory = app.staticTexts["Rotation History"]
        XCTAssertTrue(rotationHistory.exists)
        
        // Screenshot
        takeScreenshot(name: "EventHistory_Rotation")
    }
    
    func testReplacementHistory() throws {
        app.launchArguments = ["UI-Testing", "WithReplacementHistory"]
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        app.swipeUp()
        
        let replacementHistory = app.staticTexts["Replacement History"]
        XCTAssertTrue(replacementHistory.exists)
        
        // Screenshot
        takeScreenshot(name: "EventHistory_Replacement")
    }
    
    func testAirFilterHistory() throws {
        app.launchArguments = ["UI-Testing", "WithAirFilterHistory"]
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        app.swipeUp()
        app.swipeUp()
        
        let airFilterHistory = app.staticTexts["Air Filter Changes"]
        XCTAssertTrue(airFilterHistory.exists)
        
        // Screenshot
        takeScreenshot(name: "EventHistory_AirFilter")
    }
    
    // MARK: - Helper Functions
    
    func takeScreenshot(name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        XCTContext.runActivity(named: "Screenshot: \(name)") { activity in
            activity.add(attachment)
        }
    }
}
