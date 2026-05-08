//
//  TeslaCareUITests.swift
//  TeslaCareUITests
//
//  Created by Jin on 5/7/26.
//

import XCTest

final class TeslaCareUITests2: XCTestCase {
    
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Car Detail View Tests
    
    @MainActor
    func testCarDetailView_EmptyState() throws {
        app.launchArguments.append("EmptyCarState")
        app.launch()
        
        // Wait for the view to appear
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        // Verify car info header is visible
        let carName = app.staticTexts["My Tesla"]
        XCTAssertTrue(carName.exists)
        
        // Verify year, make, model is displayed
        let carDetails = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '2023'")).firstMatch
        XCTAssertTrue(carDetails.exists)
        
        // Verify "No Measurements" empty state
        let noMeasurements = app.staticTexts["No Measurements"]
        XCTAssertTrue(noMeasurements.exists)
        
        // Verify action buttons exist
        XCTAssertTrue(app.buttons["Rotate"].exists)
        XCTAssertTrue(app.buttons["Replace"].exists)
        
        // Take screenshot
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "CarDetailView_EmptyState"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testCarDetailView_WithMeasurements() throws {
        app.launchArguments.append("CarWithMeasurements")
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        // Verify tire health is displayed
        let tireHealth = app.staticTexts["Overall Tire Health"]
        XCTAssertTrue(tireHealth.exists)
        
        // Verify progress view exists
        let progressView = app.progressIndicators.firstMatch
        XCTAssertTrue(progressView.exists)
        
        // Verify average tread depth is shown
        let averageDepth = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Average:'")).firstMatch
        XCTAssertTrue(averageDepth.exists)
        
        // Verify measurement history section exists
        let measurementHistory = app.staticTexts["Measurement History"]
        XCTAssertTrue(measurementHistory.exists)
        
        // Take screenshot
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "CarDetailView_WithMeasurements"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testCarDetailView_HealthyTires() throws {
        app.launchArguments.append("HealthyTires")
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        // Verify high health percentage (should show green)
        let healthPercentage = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '%'")).firstMatch
        XCTAssertTrue(healthPercentage.exists)
        
        // Take screenshot
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "CarDetailView_HealthyTires"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testCarDetailView_WarningTires() throws {
        app.launchArguments.append("WarningTires")
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        // Verify warning indicators exist
        let warningIcons = app.images.matching(NSPredicate(format: "identifier CONTAINS 'exclamationmark'")).count
        XCTAssertGreaterThan(warningIcons, 0)
        
        // Take screenshot
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "CarDetailView_WarningTires"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testCarDetailView_DangerousTires() throws {
        app.launchArguments.append("DangerousTires")
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        // Verify danger indicators exist
        let dangerIcons = app.images.matching(NSPredicate(format: "identifier CONTAINS 'triangle'")).count
        XCTAssertGreaterThan(dangerIcons, 0)
        
        // Take screenshot
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "CarDetailView_DangerousTires"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testCarDetailView_WithRotationHistory() throws {
        app.launchArguments.append("WithRotationHistory")
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        // Scroll to rotation history
        app.swipeUp()
        
        // Verify rotation history section
        let rotationHistory = app.staticTexts["Rotation History"]
        XCTAssertTrue(rotationHistory.exists)
        
        // Take screenshot
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "CarDetailView_WithRotationHistory"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testCarDetailView_WithReplacementHistory() throws {
        app.launchArguments.append("WithReplacementHistory")
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        // Scroll to replacement history
        app.swipeUp()
        
        // Verify replacement history section
        let replacementHistory = app.staticTexts["Replacement History"]
        XCTAssertTrue(replacementHistory.exists)
        
        // Take screenshot
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "CarDetailView_WithReplacementHistory"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testCarDetailView_WithAirFilterHistory() throws {
        app.launchArguments.append("WithAirFilterHistory")
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        // Scroll to air filter history
        app.swipeUp()
        app.swipeUp()
        
        // Verify air filter history section
        let airFilterHistory = app.staticTexts["Air Filter Changes"]
        XCTAssertTrue(airFilterHistory.exists)
        
        // Take screenshot
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "CarDetailView_WithAirFilterHistory"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testCarDetailView_CompleteHistory() throws {
        app.launchArguments.append("CompleteHistory")
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        // Take screenshot of initial view
        var screenshot = app.screenshot()
        var attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "CarDetailView_CompleteHistory_Top"
        attachment.lifetime = .keepAlways
        add(attachment)
        
        // Scroll and capture mid section
        app.swipeUp()
        sleep(1)
        screenshot = app.screenshot()
        attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "CarDetailView_CompleteHistory_Middle"
        attachment.lifetime = .keepAlways
        add(attachment)
        
        // Scroll and capture bottom section
        app.swipeUp()
        sleep(1)
        screenshot = app.screenshot()
        attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "CarDetailView_CompleteHistory_Bottom"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    // MARK: - Measurement Row Tests
    
    @MainActor
    func testMeasurementRow_Healthy() throws {
        app.launchArguments.append("CarWithMeasurements")
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        // Find a healthy measurement (green)
        let measurementRow = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '/32\"'")).firstMatch
        XCTAssertTrue(measurementRow.exists)
        
        // Take screenshot
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "MeasurementRow_Healthy"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    // MARK: - Action Button Tests
    
    @MainActor
    func testCarDetailView_RotateButton() throws {
        app.launchArguments.append("CarWithMeasurements")
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        // Tap rotate button
        let rotateButton = app.buttons["Rotate"]
        XCTAssertTrue(rotateButton.exists)
        rotateButton.tap()
        
        // Wait for sheet to appear
        sleep(1)
        
        // Take screenshot
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "CarDetailView_RotateSheet"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testCarDetailView_ReplaceButton() throws {
        app.launchArguments.append("CarWithMeasurements")
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        // Tap replace button
        let replaceButton = app.buttons["Replace"]
        XCTAssertTrue(replaceButton.exists)
        replaceButton.tap()
        
        // Wait for sheet to appear
        sleep(1)
        
        // Take screenshot
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "CarDetailView_ReplaceSheet"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testCarDetailView_AddMeasurementButton() throws {
        app.launchArguments.append("CarWithMeasurements")
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        // Tap add measurement button in toolbar
        let addButton = app.buttons["Add Measurement"]
        XCTAssertTrue(addButton.exists)
        addButton.tap()
        
        // Wait for sheet to appear
        sleep(1)
        
        // Take screenshot
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "CarDetailView_AddMeasurementSheet"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testCarDetailView_LogAirFilterButton() throws {
        app.launchArguments.append("CarWithMeasurements")
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        // Tap toolbar overflow menu (if needed) or secondary action
        let logAirFilterButton = app.buttons["Log Air Filter"]
        if logAirFilterButton.exists {
            logAirFilterButton.tap()
        } else {
            // May need to access overflow menu
            let moreButton = app.buttons["More"]
            if moreButton.exists {
                moreButton.tap()
                sleep(1)
                app.buttons["Log Air Filter"].tap()
            }
        }
        
        // Wait for sheet to appear
        sleep(1)
        
        // Take screenshot
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "CarDetailView_LogAirFilterSheet"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    // MARK: - Tire Grid Interaction Tests
    
    @MainActor
    func testCarDetailView_TireGridSelection() throws {
        app.launchArguments.append("CarWithMeasurements")
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        // Take screenshot showing tire grid
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "CarDetailView_TireGrid"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    // MARK: - Different Car Types
    
    @MainActor
    func testCarDetailView_DifferentCarYears() throws {
        // Test with different year formats
        app.launchArguments.append("Car2020")
        app.launch()
        
        let carDetailTitle = app.navigationBars["Tire Tracking"]
        XCTAssertTrue(carDetailTitle.waitForExistence(timeout: 5))
        
        // Verify year is displayed correctly without grouping
        let yearText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '2020'")).firstMatch
        XCTAssertTrue(yearText.exists)
        
        // Take screenshot
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "CarDetailView_2020Car"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
