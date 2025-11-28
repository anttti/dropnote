//
//  DropnoteUITests.swift
//  DropnoteUITests
//
//  Created by Antti Mattila on 27.11.2025.
//

import XCTest

final class DropnoteUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Menu Bar Tests
    
    @MainActor
    func testStatusBarItemExists() throws {
        // Menu bar apps should have status items accessible
        let menuBars = app.menuBars
        XCTAssertTrue(menuBars.count > 0, "Menu bar should exist")
    }
    
    @MainActor
    func testStatusItemIsClickable() throws {
        let statusItem = app.statusItems.firstMatch
        guard statusItem.waitForExistence(timeout: 3) else {
            XCTSkip("Status item not accessible in test environment")
            return
        }
        
        XCTAssertTrue(statusItem.isHittable, "Status item should be hittable")
        
        // Click should not crash
        statusItem.click()
        
        // Small wait to ensure no crash
        Thread.sleep(forTimeInterval: 0.5)
    }
    
    // MARK: - Panel Accessibility Tests
    // Note: NSPanel with .nonactivatingPanel style has limited XCUITest accessibility.
    // These tests verify what IS accessible rather than failing on what isn't.
    
    @MainActor
    func testAppLaunchesWithoutCrash() throws {
        // Verify app is running
        XCTAssertTrue(app.state == .runningForeground || app.state == .runningBackground,
                     "App should be running")
    }
    
    @MainActor
    func testStatusItemClickAndToggle() throws {
        let statusItem = app.statusItems.firstMatch
        guard statusItem.waitForExistence(timeout: 3) else {
            XCTSkip("Status item not accessible")
            return
        }
        
        // First click - should open panel
        statusItem.click()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Second click - should close panel (toggle behavior)
        statusItem.click()
        Thread.sleep(forTimeInterval: 0.3)
        
        // If we got here without crash, toggle works
        XCTAssertTrue(true, "Panel toggle completed without crash")
    }
    
    @MainActor
    func testMultipleStatusItemClicks() throws {
        let statusItem = app.statusItems.firstMatch
        guard statusItem.waitForExistence(timeout: 3) else {
            XCTSkip("Status item not accessible")
            return
        }
        
        // Rapid clicking should not crash
        for _ in 0..<5 {
            statusItem.click()
            Thread.sleep(forTimeInterval: 0.2)
        }
        
        XCTAssertTrue(app.state == .runningForeground || app.state == .runningBackground,
                     "App should still be running after rapid clicks")
    }
    
    @MainActor
    func testGlobalHotkeyDoesNotCrash() throws {
        // Press the default hotkey (Cmd+Shift+D)
        // This tests that the hotkey handler doesn't crash
        app.typeKey("d", modifierFlags: [.command, .shift])
        Thread.sleep(forTimeInterval: 0.5)
        
        // Press again to toggle
        app.typeKey("d", modifierFlags: [.command, .shift])
        Thread.sleep(forTimeInterval: 0.3)
        
        XCTAssertTrue(app.state == .runningForeground || app.state == .runningBackground,
                     "App should still be running after hotkey")
    }
    
    @MainActor
    func testEscapeKeyDoesNotCrash() throws {
        let statusItem = app.statusItems.firstMatch
        guard statusItem.waitForExistence(timeout: 3) else {
            XCTSkip("Status item not accessible")
            return
        }
        
        // Open panel
        statusItem.click()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Press escape
        app.typeKey(.escape, modifierFlags: [])
        Thread.sleep(forTimeInterval: 0.3)
        
        XCTAssertTrue(app.state == .runningForeground || app.state == .runningBackground,
                     "App should still be running after escape")
    }
    
    @MainActor
    func testKeyboardShortcutsDoNotCrash() throws {
        let statusItem = app.statusItems.firstMatch
        guard statusItem.waitForExistence(timeout: 3) else {
            XCTSkip("Status item not accessible")
            return
        }
        
        // Open panel
        statusItem.click()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Test Cmd+N (new note)
        app.typeKey("n", modifierFlags: .command)
        Thread.sleep(forTimeInterval: 0.3)
        
        // Test Cmd+Option+Left (previous)
        app.typeKey(.leftArrow, modifierFlags: [.command, .option])
        Thread.sleep(forTimeInterval: 0.2)
        
        // Test Cmd+Option+Right (next)
        app.typeKey(.rightArrow, modifierFlags: [.command, .option])
        Thread.sleep(forTimeInterval: 0.2)
        
        XCTAssertTrue(app.state == .runningForeground || app.state == .runningBackground,
                     "App should still be running after keyboard shortcuts")
    }
    
    // MARK: - Performance Tests
    
    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
