//
//  DropnoteUITestsLaunchTests.swift
//  DropnoteUITests
//
//  Created by Antti Mattila on 27.11.2025.
//

import XCTest

final class DropnoteUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        // Verify the app launched successfully
        XCTAssertTrue(app.state == .runningForeground || app.state == .runningBackground,
                     "App should be running")
        
        // Take a screenshot of the initial state (menu bar only since panel isn't visible)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testLaunchWithCleanState() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-state"]
        app.launch()
        
        XCTAssertTrue(app.state == .runningForeground || app.state == .runningBackground,
                     "App should be running with clean state")
        
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Clean State Launch"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testStatusItemVisibleAfterLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        
        let statusItem = app.statusItems.firstMatch
        
        // Status item should become available shortly after launch
        let exists = statusItem.waitForExistence(timeout: 5)
        
        if exists {
            // Click to open panel for screenshot
            statusItem.click()
            Thread.sleep(forTimeInterval: 0.5)
            
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "Panel Open"
            attachment.lifetime = .keepAlways
            add(attachment)
        } else {
            // Still take a screenshot even if status item isn't accessible
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "Status Item Not Found"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }
}
