import XCTest

/// Drives real touch gestures against the app so scrolling / swipe-to-context can be verified on video.
final class GestureTests: XCTestCase {
    func testScrollAndContextSwipe() {
        let app = XCUIApplication()
        app.launchArguments = ["-style", "collapse", "-fund"]
        app.launch()
        sleep(2)

        func point(_ x: CGFloat, _ y: CGFloat) -> XCUICoordinate {
            app.coordinate(withNormalizedOffset: CGVector(dx: x / 393, dy: y / 852))
        }

        // 1. Vertical scroll on the stats card — page must scroll
        point(200, 650).press(forDuration: 0.05, thenDragTo: point(200, 300), withVelocity: .default, thenHoldForDuration: 0.1)
        sleep(2)

        // 2. Scroll back to the top
        point(200, 300).press(forDuration: 0.05, thenDragTo: point(200, 700), withVelocity: .default, thenHoldForDuration: 0.1)
        sleep(2)

        // 3. Slow right swipe on the stats card (y 262…500) — widget should follow, then composer opens with chip
        point(60, 380).press(forDuration: 0.05, thenDragTo: point(260, 380), withVelocity: .slow, thenHoldForDuration: 0.8)
        sleep(3)

        // 4. Close the composer (xmark near top-right of the card)
        let close = app.buttons.matching(NSPredicate(format: "label == 'xmark' OR identifier == 'xmark'")).firstMatch
        if close.exists { close.tap() } else { point(346, 300).tap() }
        sleep(2)

        // 5. Left swipe on the Nav value card — should do nothing (no composer)
        point(300, 680).press(forDuration: 0.05, thenDragTo: point(100, 680), withVelocity: .slow, thenHoldForDuration: 0.3)
        sleep(2)
    }

    /// The fund page's text can be selected: a long press on text picks up a word with the system's menu, and the
    /// widget doesn't lift; a long press off the text still lifts it
    func testFundTextSelection() {
        let app = XCUIApplication()
        app.launchArguments = ["-fund"]
        app.launch()
        sleep(3)
        func point(_ x: CGFloat, _ y: CGFloat) -> XCUICoordinate {
            app.coordinate(withNormalizedOffset: CGVector(dx: x / 402, dy: y / 874))
        }
        func shot(_ name: String) {
            let dir = ProcessInfo.processInfo.environment["SHOTS_DIR"] ?? NSTemporaryDirectory()
            try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dir + "/" + name + ".png"))
        }
        XCTAssertTrue(app.staticTexts["HSBC midcap direct growth"].waitForExistence(timeout: 5))
        // On "Lower expense ratio, zero commissions": the word under the finger is picked up; the system's menu
        // never shows, and once the selection's been still our questions about it and Copy come up
        // Held on, and dragged out over more words: nothing comes up while the finger's still down
        point(160, 293).press(forDuration: 1.0, thenDragTo: point(300, 293), withVelocity: .slow, thenHoldForDuration: 1.2)
        shot("select-word")
        XCTAssertTrue(app.buttons["Copy"].waitForExistence(timeout: 3))
        sleep(1)
        shot("select-suggestions")
        XCTAssertFalse(app.menuItems["Copy"].exists)
        XCTAssertFalse(app.menuItems["Look Up"].exists)
        // Copy copies, says so, and lets the selection go
        app.buttons["Copy"].tap()
        shot("select-copied")
        sleep(2)
        XCTAssertFalse(app.buttons["Copy"].exists)
        // Again, and this time a tap off the text lets it go
        point(160, 293).press(forDuration: 1.0)
        XCTAssertTrue(app.buttons["Copy"].waitForExistence(timeout: 3))
        point(330, 180).tap()
        sleep(1)
        XCTAssertFalse(app.buttons["Copy"].exists)
        shot("select-cleared")
        // Again, and a question opens the composer with it written in
        point(160, 293).press(forDuration: 1.0)
        XCTAssertTrue(app.buttons["Copy"].waitForExistence(timeout: 3))
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'ratio'")).firstMatch.tap()
        sleep(2)
        shot("select-asked")
        point(346, 120).tap()
        sleep(1)
    }

    func testFundTextSelectionLift() {
        let app = XCUIApplication()
        app.launchArguments = ["-fund"]
        app.launch()
        sleep(3)
        func point(_ x: CGFloat, _ y: CGFloat) -> XCUICoordinate {
            app.coordinate(withNormalizedOffset: CGVector(dx: x / 402, dy: y / 874))
        }
        func shot(_ name: String) {
            let dir = ProcessInfo.processInfo.environment["SHOTS_DIR"] ?? NSTemporaryDirectory()
            try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dir + "/" + name + ".png"))
        }
        // On the feature list's icon, off the text: the widget lifts
        point(36, 343).press(forDuration: 0.9)
        sleep(2)
        shot("select-lift")
    }

    func testHoldWidget() {
        let app = XCUIApplication()
        app.launchArguments = ["-style", "collapse", "-fund"]
        app.launch()
        sleep(2)
        func point(_ x: CGFloat, _ y: CGFloat) -> XCUICoordinate {
            app.coordinate(withNormalizedOffset: CGVector(dx: x / 393, dy: y / 852))
        }
        // Hold the feature list (y 272…486), release, wait, then tap outside
        point(200, 380).press(forDuration: 0.9)
        sleep(2)
        point(330, 780).tap()
        sleep(2)
        // Hold the price card (y 529…974) — it rises so its chips stay on screen
        point(200, 600).press(forDuration: 0.9)
        sleep(2)
        point(330, 780).tap()
        sleep(2)
    }

    /// Fixed deposits: hold a card to lift it out with its questions, then swipe one right to ask about it
    func testFDHoldAndSwipe() {
        let app = XCUIApplication()
        app.launchArguments = ["-fd", "-fdListV1"]
        app.launch()
        sleep(2)
        func point(_ x: CGFloat, _ y: CGFloat) -> XCUICoordinate {
            app.coordinate(withNormalizedOffset: CGVector(dx: x / 393, dy: y / 852))
        }
        func shot(_ name: String) {
            let dir = ProcessInfo.processInfo.environment["SHOTS_DIR"] ?? NSTemporaryDirectory()
            try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dir + "/" + name + ".png"))
        }
        point(200, 420).press(forDuration: 0.9)
        sleep(2)
        shot("fd-held")
        point(330, 800).tap()
        sleep(2)
        point(60, 420).press(forDuration: 0.05, thenDragTo: point(280, 420), withVelocity: .slow, thenHoldForDuration: 0.6)
        sleep(2)
        shot("fd-swiped")
    }

    /// Fixed deposits: the small finance banks, then returns calculated on an amount
    func testFDBanksAndReturns() {
        let app = XCUIApplication()
        app.launchArguments = ["-fd", "-fdListV1"]
        app.launch()
        sleep(2)
        func shot(_ name: String) {
            let dir = ProcessInfo.processInfo.environment["SHOTS_DIR"] ?? NSTemporaryDirectory()
            try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dir + "/" + name + ".png"))
        }
        app.buttons["Small Finance Banks"].tap()
        sleep(1)
        shot("fd-banks")
        app.buttons["Compare returns"].tap()
        sleep(1)
        for key in ["1", "0", "0", "0", "0", "0"] { app.buttons[key].tap() }
        shot("fd-sheet")
        app.buttons["Calculate Returns"].tap()
        sleep(1)
        app.buttons["5Y"].tap()
        sleep(1)
        shot("fd-returns")
    }

    /// Fixed deposits: a tap on a bank's card pushes its page; back pops to the list
    func testFDBankPage() {
        let app = XCUIApplication()
        app.launchArguments = ["-fd", "-fdListV1", "-fdBankV1"]
        app.launch()
        sleep(2)
        func shot(_ name: String) {
            let dir = ProcessInfo.processInfo.environment["SHOTS_DIR"] ?? NSTemporaryDirectory()
            try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dir + "/" + name + ".png"))
        }
        app.buttons["Small Finance Banks"].tap()
        sleep(1)
        // The first card under the filters is Suryoday
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).tap()
        sleep(2)
        XCTAssertTrue(app.staticTexts["Things to know"].exists)
        shot("bank-1")
        app.swipeUp(velocity: .slow)
        sleep(1)
        shot("bank-2")
        app.swipeUp(velocity: .slow)
        sleep(1)
        shot("bank-3")
        app.swipeDown(velocity: .fast)
        app.swipeDown(velocity: .fast)
        sleep(1)
        // The chevron over the picture
        app.coordinate(withNormalizedOffset: CGVector(dx: 25.0 / 402, dy: 75.0 / 874)).tap()
        sleep(1)
        XCTAssertTrue(app.buttons["Compare returns"].exists)
        XCTAssertFalse(app.staticTexts["Things to know"].exists)
        shot("bank-back")
    }

    /// Fixed deposits: the second version of the bank's page, the default
    /// The bank page that ends on "How your money could grow?" in place of the plans
    func testFDBankGrowth() {
        let app = XCUIApplication()
        app.launchArguments = ["-fd", "-fdListV1"]
        app.launch()
        sleep(2)
        func shot(_ name: String) {
            let dir = ProcessInfo.processInfo.environment["SHOTS_DIR"] ?? NSTemporaryDirectory()
            try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dir + "/" + name + ".png"))
        }
        app.buttons["Small Finance Banks"].tap()
        sleep(1)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).tap()
        sleep(2)
        XCTAssertTrue(app.staticTexts["FIXED DEPOSIT"].exists)
        app.swipeUp(velocity: .fast)
        app.swipeUp(velocity: .fast)
        app.swipeUp(velocity: .fast)
        sleep(1)
        XCTAssertTrue(app.staticTexts["How your money could grow?"].exists)
        XCTAssertFalse(app.staticTexts["Available FD’s"].exists)
        shot("growth-1")
        app.buttons["5 years"].tap()
        sleep(1)
        XCTAssertTrue(app.staticTexts["5 years"].exists)
        shot("growth-5y")
        let slider = app.otherElements["One time deposit"]
        XCTAssertTrue(slider.exists)
        slider.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.5))
            .press(forDuration: 0.1, thenDragTo: slider.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)))
        sleep(1)
        shot("growth-slid")
        // Pushed past the track's end and held, the slider opens into the meter and the amount keeps climbing
        slider.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
            .press(forDuration: 0.1, thenDragTo: slider.coordinate(withNormalizedOffset: CGVector(dx: 1.04, dy: 0.5)), withVelocity: .slow, thenHoldForDuration: 2.5)
        sleep(1)
        let reached = Int((slider.value as? String ?? "").filter(\.isNumber)) ?? 0
        XCTAssertGreaterThan(reached, 100_000)
        shot("growth-metered")
        // The bar's "View plans" opens every plan in one card; a row grows into its plan as before
        app.buttons["View plans"].tap()
        sleep(2)
        XCTAssertTrue(app.staticTexts["Select your plan"].exists)
        XCTAssertTrue(app.staticTexts["More than 1 year"].exists)
        XCTAssertTrue(app.buttons["One time deposit"].isSelected)
        app.buttons["Recurring deposit"].tap()
        sleep(1)
        XCTAssertTrue(app.buttons["Recurring deposit"].isSelected)
        app.buttons["One time deposit"].tap()
        sleep(1)
        shot("growth-plans")
        app.staticTexts["5 years"].firstMatch.tap()
        sleep(2)
        XCTAssertTrue(app.staticTexts["Interest payout"].exists)
        shot("growth-plan")
        app.buttons["Close plan"].tap()
        sleep(2)
        app.buttons["Back to bank"].tap()
        sleep(2)
        XCTAssertTrue(app.staticTexts["How your money could grow?"].exists)
        shot("growth-back")
    }

    func testFDBankPageV2() {
        let app = XCUIApplication()
        app.launchArguments = ["-fd", "-fdListV1", "-fdBankV2"]
        app.launch()
        sleep(2)
        func shot(_ name: String) {
            let dir = ProcessInfo.processInfo.environment["SHOTS_DIR"] ?? NSTemporaryDirectory()
            try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dir + "/" + name + ".png"))
        }
        app.buttons["Small Finance Banks"].tap()
        sleep(1)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).tap()
        sleep(2)
        XCTAssertTrue(app.staticTexts["FIXED DEPOSIT"].exists)
        shot("bank2-1")
        // Hold the bank's card to lift it out with questions; a tap elsewhere puts it back
        func at(_ x: CGFloat, _ y: CGFloat) -> XCUICoordinate {
            app.coordinate(withNormalizedOffset: CGVector(dx: x / 402, dy: y / 874))
        }
        at(200, 400).press(forDuration: 0.9)
        sleep(2)
        XCTAssertTrue(app.staticTexts["Is this bank safe?"].exists)
        shot("bank2-held")
        at(200, 840).tap()
        sleep(2)
        // Swipe it right to send it to the composer
        at(60, 400).press(forDuration: 0.05, thenDragTo: at(280, 400), withVelocity: .slow, thenHoldForDuration: 0.6)
        sleep(2)
        XCTAssertTrue(app.staticTexts["About the bank"].exists)
        shot("bank2-swiped")
        at(200, 100).tap()
        sleep(2)
        // The advisor pill at the foot of the page opens the composer, and the cross puts it away
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.4, dy: (874.0 - 74) / 874)).tap()
        sleep(2)
        XCTAssertTrue(app.staticTexts["Akshima"].exists)
        shot("bank2-composer")
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15)).tap()
        sleep(2)
        app.swipeUp(velocity: .slow)
        sleep(1)
        shot("bank2-2")
        app.swipeUp(velocity: .slow)
        sleep(1)
        shot("bank2-3")
        // A plan's row grows into its card; an amount opens the card's foot with the maturity value
        app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH '5 years'")).firstMatch.tap()
        sleep(2)
        XCTAssertTrue(app.staticTexts["Fixed deposit"].exists)
        XCTAssertTrue(app.buttons["Continue"].exists)
        shot("plan-1")
        for key in ["5", "0", "0", "0", "0"] { app.buttons[key].tap() }
        // The maturity line waits for typing to pause
        sleep(2)
        XCTAssertTrue(app.staticTexts["Your FD at maturity will be Rs75,213"].exists)
        shot("plan-2")
        // Continue turns the card into the review; its chevron turns it back
        app.buttons["Continue"].tap()
        sleep(2)
        XCTAssertTrue(app.staticTexts["Start your fixed deposit"].exists)
        XCTAssertTrue(app.staticTexts["Rs75,213"].exists)
        shot("plan-review")
        app.buttons["Back to amount"].tap()
        sleep(2)
        app.buttons["Close plan"].tap()
        sleep(2)
        XCTAssertFalse(app.buttons["Continue"].exists)
        // Pulling the card down folds it back into its row too
        app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH '5 years'")).firstMatch.tap()
        sleep(2)
        XCTAssertTrue(app.buttons["Continue"].exists)
        at(200, 200).press(forDuration: 0.05, thenDragTo: at(200, 420), withVelocity: .slow, thenHoldForDuration: 0.1)
        sleep(2)
        XCTAssertFalse(app.buttons["Continue"].exists)
        shot("plan-closed")
        app.swipeUp(velocity: .slow)
        sleep(1)
        shot("bank2-4")
        app.swipeDown(velocity: .fast)
        app.swipeDown(velocity: .fast)
        app.swipeDown(velocity: .fast)
        sleep(1)
        app.coordinate(withNormalizedOffset: CGVector(dx: 25.0 / 402, dy: 94.0 / 874)).tap()
        sleep(1)
        XCTAssertFalse(app.staticTexts["FIXED DEPOSIT"].exists)
    }

    func testHomeToFundAndBack() {
        let app = XCUIApplication()
        app.launchArguments = ["-home"]
        app.launch()
        sleep(2)
        func point(_ x: CGFloat, _ y: CGFloat) -> XCUICoordinate {
            app.coordinate(withNormalizedOffset: CGVector(dx: x / 393, dy: y / 852))
        }
        // Investments portfolio → fund page slides in
        point(72, 348).tap()
        sleep(3)
        // Back chevron → home
        point(32, 82).tap()
        sleep(2)
        // A chat row also opens the fund page
        point(196, 580).tap()
        sleep(2)
    }

    func testPriceChart() {
        let app = XCUIApplication()
        app.launchArguments = ["-fund"]
        app.launch()
        sleep(4)
        func point(_ x: CGFloat, _ y: CGFloat) -> XCUICoordinate {
            app.coordinate(withNormalizedOffset: CGVector(dx: x / 393, dy: y / 852))
        }
        // Bring the price card (y 671…1116) up under the header
        point(200, 600).press(forDuration: 0.05, thenDragTo: point(200, 120), withVelocity: .slow, thenHoldForDuration: 0.3)
        sleep(2)
        app.buttons["1M"].tap(); sleep(2)
        app.buttons["1Y"].tap(); sleep(2)
        app.buttons["3Y"].tap(); sleep(2)
        // Tap two days on the chart, then the same day again to clear
        let chart = app.buttons["1M"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        chart.withOffset(CGVector(dx: 80, dy: -180)).tap(); sleep(2)
        chart.withOffset(CGVector(dx: 220, dy: -180)).tap(); sleep(2)
        chart.withOffset(CGVector(dx: 220, dy: -180)).tap(); sleep(2)
    }

    func testHorseRear() {
        let app = XCUIApplication()
        app.launchArguments = ["-home"]
        app.launch()
        sleep(8)
        func point(_ x: CGFloat, _ y: CGFloat) -> XCUICoordinate {
            app.coordinate(withNormalizedOffset: CGVector(dx: x / 393, dy: y / 852))
        }
        // The horse stands at the top left once it has walked in; tap its body
        point(60, 335).tap()
        sleep(3)
        point(60, 335).tap()
        sleep(3)
    }

    func testHorseDash() {
        let app = XCUIApplication()
        app.launchArguments = ["-home"]
        app.launch()
        sleep(8)
        func point(_ x: CGFloat, _ y: CGFloat) -> XCUICoordinate {
            app.coordinate(withNormalizedOffset: CGVector(dx: x / 393, dy: y / 852))
        }
        // Swipe right across the horse: it bolts off and walks back in
        point(50, 335).press(forDuration: 0.01, thenDragTo: point(200, 340), withVelocity: .fast, thenHoldForDuration: 0)
        sleep(8)
    }

    func testOpenChatFromNav() {
        let app = XCUIApplication()
        app.launchArguments = ["-home"]
        app.launch()
        sleep(3)
        func point(_ x: CGFloat, _ y: CGFloat) -> XCUICoordinate {
            app.coordinate(withNormalizedOffset: CGVector(dx: x / 393, dy: y / 852))
        }
        // Chat tab in the left pill: the chat grows out of it, then the back chevron shrinks it home
        point(53, 789).tap()
        sleep(2)
        point(40, 82).tap()
        sleep(2)
        // + in the right pill
        point(343, 789).tap()
        sleep(2)
        point(40, 82).tap()
        sleep(2)
    }

    func testNewChatAndMoodDial() {
        let app = XCUIApplication()
        app.launchArguments = ["-home"]
        app.launch()
        sleep(3)
        func point(_ x: CGFloat, _ y: CGFloat) -> XCUICoordinate {
            app.coordinate(withNormalizedOffset: CGVector(dx: x / 393, dy: y / 852))
        }
        // Agent avatar: a new chat, the agent thinks, then opens the conversation
        point(283, 789).tap()
        sleep(6)
        point(40, 82).tap()
        sleep(2)
        // + : the mood dial; drag the knob from the top round to the right, then left
        point(343, 789).tap()
        sleep(2)
        point(196, 600).press(forDuration: 0.1, thenDragTo: point(330, 700), withVelocity: .slow, thenHoldForDuration: 0.5)
        sleep(1)
        point(196, 600).press(forDuration: 0.1, thenDragTo: point(60, 700), withVelocity: .slow, thenHoldForDuration: 0.5)
        sleep(2)
    }

    func testScrollHome() {
        let app = XCUIApplication()
        app.launchArguments = ["-home"]
        app.launch()
        sleep(3)
        app.swipeUp(velocity: .slow)
        app.swipeUp(velocity: .slow)
        sleep(12)
    }

    func testPullToSearch() {
        let app = XCUIApplication()
        app.launchArguments = ["-home"]
        app.launch()
        sleep(4)
        func point(_ x: CGFloat, _ y: CGFloat) -> XCUICoordinate {
            app.coordinate(withNormalizedOffset: CGVector(dx: x / 393, dy: y / 852))
        }
        // Pull the page down well past the threshold and let go
        point(200, 140).press(forDuration: 0.05, thenDragTo: point(200, 560), withVelocity: 500, thenHoldForDuration: 0.4)
        sleep(3)
        // The keyboard is already up, so typing goes straight into search
        app.textFields.firstMatch.typeText("hsbc")
        sleep(2)
        // Tap the dimmed page below to close
        point(200, 800).tap()
        sleep(2)
    }

    func testForYouTab() {
        let app = XCUIApplication()
        app.launchArguments = ["-fund"]
        app.launch()
        sleep(2)
        func point(_ x: CGFloat, _ y: CGFloat) -> XCUICoordinate {
            app.coordinate(withNormalizedOffset: CGVector(dx: x / 393, dy: y / 852))
        }
        // For you slides in from the right
        point(196, 760).tap()
        sleep(2)
        // Scroll it, hold the summary card, put it back
        point(200, 600).press(forDuration: 0.05, thenDragTo: point(200, 300), withVelocity: .default, thenHoldForDuration: 0.1)
        sleep(1)
        point(200, 450).press(forDuration: 0.9)
        sleep(2)
        point(330, 780).tap()
        sleep(1)
        // Back to Market — it slides back in from the left
        point(80, 760).tap()
        sleep(2)
    }

    func testCollapseAndExpand() {
        let app = XCUIApplication()
        app.launchArguments = ["-fund"]
        app.launch()
        sleep(2)
        func point(_ x: CGFloat, _ y: CGFloat) -> XCUICoordinate {
            app.coordinate(withNormalizedOffset: CGVector(dx: x / 393, dy: y / 852))
        }
        // Scroll to the bottom and keep going — the page gathers into the summary widget
        for _ in 0..<5 {
            point(200, 600).press(forDuration: 0.05, thenDragTo: point(200, 150), withVelocity: .fast, thenHoldForDuration: 0)
            sleep(1)
        }
        sleep(3)
        // Pull the widget down to lay the page back out
        point(200, 130).press(forDuration: 0.05, thenDragTo: point(200, 500), withVelocity: .slow, thenHoldForDuration: 0.1)
        sleep(3)
        // Tap a tab, then the pill to open the composer
        point(290, 760).tap()
        sleep(1)
        point(160, 694).tap()
        sleep(2)
    }

    func testOnboardingHold() {
        let app = XCUIApplication()
        app.launchArguments = ["-onboardingStep", "4"]
        app.launch()
        sleep(2)
        func point(_ x: CGFloat, _ y: CGFloat) -> XCUICoordinate {
            app.coordinate(withNormalizedOffset: CGVector(dx: x / 393, dy: y / 852))
        }
        // Tap Continue while inactive — must do nothing
        point(200, 763).tap()
        sleep(1)
        // Hold the research card (y 227…557)
        // Hold on the hint row above the card — the whole panel responds
        point(250, 200).press(forDuration: 0.9)
        sleep(2)
        // Continue must now advance (lands on the swipe screen)
        point(200, 763).tap()
        sleep(2)
        XCTAssertTrue(app.staticTexts["Swipe to ask a specific question"].exists)
    }

    func testOnboardingSwipe() {
        let app = XCUIApplication()
        app.launchArguments = ["-onboardingStep", "5"]
        app.launch()
        sleep(2)
        func point(_ x: CGFloat, _ y: CGFloat) -> XCUICoordinate {
            app.coordinate(withNormalizedOffset: CGVector(dx: x / 393, dy: y / 852))
        }
        // Swipe the chart card right (card y 227…557)
        // Swipe starting on the hint row above the card — the whole panel responds
        point(60, 200).press(forDuration: 0.05, thenDragTo: point(300, 200), withVelocity: .slow, thenHoldForDuration: 0.2)
        sleep(3)
    }

    func testOnboardingComplexity() {
        let app = XCUIApplication()
        app.launchArguments = ["-onboardingStep", "6"]
        app.launch()
        sleep(2)
        func point(_ x: CGFloat, _ y: CGFloat) -> XCUICoordinate {
            app.coordinate(withNormalizedOffset: CGVector(dx: x / 393, dy: y / 852))
        }
        // Knob centre at (55, 571): drag to ANY, then to TERMS, then back to SIMPLY
        point(56, 571).press(forDuration: 0.05, thenDragTo: point(200, 571), withVelocity: .slow, thenHoldForDuration: 0.3)
        sleep(1)
        point(197, 571).press(forDuration: 0.05, thenDragTo: point(345, 571), withVelocity: .slow, thenHoldForDuration: 0.3)
        sleep(1)
        point(338, 571).press(forDuration: 0.05, thenDragTo: point(40, 571), withVelocity: .slow, thenHoldForDuration: 0.3)
        sleep(1)
    }

    func testDecadeWelcomeArrives() {
        let app = XCUIApplication()
        app.launchArguments = ["-onboardingPAN"]
        app.launch()
        sleep(2)
        app.buttons["Confirm"].tap()
        sleep(4)
        XCTAssertTrue(app.staticTexts["Welcome to Decade Wealth Advisory"].exists)
        XCTAssertTrue(app.staticTexts["Hello Ambika"].exists)
    }

    func testFixedDeposits() {
        let app = XCUIApplication()
        app.launchArguments = ["-fd", "-fdListV1"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Bajaj Finance"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Compare returns"].exists)
        // The filters narrow the list
        app.buttons["Small Finance Banks"].tap()
        sleep(1)
        XCTAssertFalse(app.staticTexts["Bajaj Finance"].exists)
        XCTAssertTrue(app.staticTexts["Suryoday SFB"].exists)
        app.buttons["NBFC’s"].tap()
        sleep(1)
        XCTAssertFalse(app.staticTexts["Suryoday SFB"].exists)
        XCTAssertTrue(app.staticTexts["Bajaj Finance"].exists)
    }

    func testCompareReturns() {
        let app = XCUIApplication()
        app.launchArguments = ["-fd", "-fdListV1"]
        app.launch()
        let compare = app.buttons["Compare returns"]
        XCTAssertTrue(compare.waitForExistence(timeout: 3))
        sleep(1)
        compare.tap()
        // The sheet comes up with its number pad
        XCTAssertTrue(app.staticTexts["Enter investment amount"].waitForExistence(timeout: 2))
        sleep(1)
        for key in ["1", "5", "0", "0", "0", "0"] { app.buttons[key].tap() }
        XCTAssertTrue(app.staticTexts["₹1,50,000"].exists)
        app.buttons["Calculate Returns"].tap()
        // The list shows each deposit's maturity value, and the bar holds the amount
        XCTAssertTrue(app.staticTexts["Rs1,53,188"].firstMatch.waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Edit amount"].exists)
        // Changing the tenure changes the returns
        app.buttons["1Y"].tap()
        XCTAssertTrue(app.staticTexts["Rs1,63,162"].firstMatch.waitForExistence(timeout: 2))
        // and the cross puts it all back
        app.buttons["Clear amount"].tap()
        XCTAssertTrue(app.buttons["Compare returns"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Rs1,63,162"].firstMatch.exists)
        // which opens the sheet again
        app.buttons["Compare returns"].tap()
        XCTAssertTrue(app.staticTexts["Enter investment amount"].waitForExistence(timeout: 2))
    }

    func testAdvice() {
        let app = XCUIApplication()
        app.launchArguments = ["-onboardingStep", "1", "-welcomeAnalysis", "-researchSeconds", "2"]
        app.launch()
        // The finished report scrolls down to the question that leads on
        XCTAssertTrue(app.staticTexts["Equity mutual funds 2026"].waitForExistence(timeout: 12))
        XCTAssertFalse(app.buttons["Understood"].exists)
        sleep(2)
        let dirR = ProcessInfo.processInfo.environment["SHOTS_DIR"] ?? NSTemporaryDirectory()
        let ask = app.buttons["How did my equity funds do this year?"]
        for page in 0..<14 {
            try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dirR + "/report-\(page).png"))
            if ask.isHittable { break }
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75))
                .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3)))
            sleep(1)
        }
        // It comes out under the sheet once the report's being read
        XCTAssertTrue(ask.isHittable)
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dirR + "/report-chip.png"))
        // and with the report closed it waits in the chat
        app.buttons["Close analysis"].tap()
        sleep(2)
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dirR + "/chat-chip.png"))
        XCTAssertTrue(ask.isHittable)
        ask.tap()
        // then it's kept in the chat, and the agent turns to personal advice: its own card asking for the funds
        XCTAssertTrue(app.buttons["View analysis"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["How did my equity funds do this year?"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["That’s a personal advisory question. To answer it I need access to your mutual funds."].waitForExistence(timeout: 6))
        XCTAssertFalse(app.staticTexts["useful when its"].exists)
        let connect = app.buttons["Connect securely"]
        XCTAssertTrue(connect.waitForExistence(timeout: 6))
        XCTAssertTrue(app.staticTexts["Action required"].exists)
        sleep(2)
        let dirC = ProcessInfo.processInfo.environment["SHOTS_DIR"] ?? NSTemporaryDirectory()
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dirC + "/connect-1.png"))
        connect.tap()
        // which opens how they'll be brought in
        XCTAssertTrue(app.staticTexts["We will import mutual funds via MFCentral"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Lets connect"].exists)
        XCTAssertTrue(app.buttons["I will upload myself"].exists)
        sleep(1)
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dirC + "/connect-3.png"))
        // Its close puts it away, and the stored analysis opens again
        sleep(1)
        app.buttons["Close"].tap()
        sleep(1)
        XCTAssertFalse(app.staticTexts["We will import mutual funds via MFCentral"].exists)
        app.buttons["View analysis"].tap()
        XCTAssertTrue(app.staticTexts["Equity mutual funds 2026"].waitForExistence(timeout: 3))
    }

    func testImportFlow() {
        let app = XCUIApplication()
        app.launchArguments = ["-onboardingStep", "1", "-welcomeDone", "-welcomeAnalysis", "-welcomeAdvice", "-importFlow"]
        app.launch()
        let dir = ProcessInfo.processInfo.environment["SHOTS_DIR"] ?? NSTemporaryDirectory()
        func shot(_ name: String) {
            try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dir + "/" + name + ".png"))
        }
        // It ticks its steps off, then asks for the one-time password over the number pad
        XCTAssertTrue(app.staticTexts["Connecting securely"].waitForExistence(timeout: 4))
        shot("import-connecting")
        XCTAssertTrue(app.staticTexts["Account connected"].waitForExistence(timeout: 6))
        sleep(1)
        shot("import-connected")
        XCTAssertTrue(app.staticTexts["MFCentral OTP"].waitForExistence(timeout: 5))
        sleep(2)
        shot("import-otp")
        // The code offered from Messages fills it in, and it moves on by itself
        let offer = app.buttons["From Messages 889302"]
        if offer.waitForExistence(timeout: 3) { offer.tap() } else { app.typeText("889302") }
        XCTAssertTrue(app.staticTexts["Mobile verified"].waitForExistence(timeout: 4))
        // then the security questions, one after the other
        XCTAssertTrue(app.staticTexts["Answer security question"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Where were you born"].exists)
        sleep(1)
        shot("import-question")
        app.buttons["I know the answer"].tap()
        XCTAssertTrue(app.staticTexts["What was the name of your first school"].waitForExistence(timeout: 3))
        app.textFields["Answer"].tap()
        app.typeText("Springfield")
        sleep(1)
        shot("import-typing")
        app.buttons["I know the answer"].tap()
        // and it finishes, and says so in a sheet
        XCTAssertTrue(app.staticTexts["Security verified"].waitForExistence(timeout: 5))
        shot("import-complete")
        // the card clears to the houses while the funds load
        sleep(3)
        XCTAssertFalse(app.staticTexts["Security verified"].isHittable)
        shot("import-loading")
        // then what came in, and View carries on
        let done = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Mutual fund portfolio'")).firstMatch
        XCTAssertTrue(done.waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Portfolio analysis started"].exists)
        sleep(1)
        shot("import-done")
        app.buttons["View"].tap()
        // back in the chat the card says it's connected, and a second report is prepared under it
        XCTAssertTrue(app.staticTexts["Connected successfully"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["MFCentral Account"].exists)
        // then thanks, and it goes through the funds; no plan
        XCTAssertTrue(app.staticTexts["Thanks for connecting. I’ll now check how this affects your portfolio."].waitForExistence(timeout: 5))
        sleep(3)
        shot("chat-connected")
        XCTAssertTrue(app.staticTexts["Going through"].exists)
        sleep(4)
        shot("chat-comparing")
        // which opens, and its Understood leads to the congratulations and then the advisor
        let understood = app.buttons["Understood"]
        XCTAssertTrue(understood.waitForExistence(timeout: 16))
        sleep(2)
        XCTAssertTrue(app.staticTexts["Your equity funds 2026"].waitForExistence(timeout: 3))
        for page in 0..<6 {
            shot("own-\(page)")
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
                .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25)))
            sleep(1)
        }
        shot("own-spreads")
        understood.tap()
        sleep(2)
        shot("congrats")
        let meet = app.buttons["Great!"]
        XCTAssertTrue(meet.waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Ambika, meet your personal advisor"].exists)
        sleep(1)
        shot("meet-advisor")
        meet.tap()
        // she goes up into the corner, and the permissions come up under her
        XCTAssertTrue(app.staticTexts["Select permissions you want advisor to communicate from"].waitForExistence(timeout: 8))
        sleep(3)
        shot("comms-1")
        // WhatsApp needs nothing from the system
        let whatsApp = app.switches["WhatsApp"]
        whatsApp.tap()
        XCTAssertEqual(whatsApp.value as? String, "1")
        // App notifications: the system asks (the first time), and the switch stays on once it's allowed
        app.switches["Advisory notifications"].tap()
        let allow = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Allow"]
        if allow.waitForExistence(timeout: 3) {
            shot("comms-ask")
            allow.tap()
            sleep(1)
            XCTAssertEqual(app.switches["Advisory notifications"].value as? String, "1")
        }
        shot("comms-2")
        app.buttons["Continue"].tap()
        sleep(2)
        // on to the guides
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'What feels comfortable'")).firstMatch.exists)
    }

    /// The three guides after the permissions: reading level, hold, swipe; the last Continue ends the onboarding
    func testGuides() {
        let app = XCUIApplication()
        app.launchArguments = ["-onboardingStep", "12"]
        app.launch()
        // She types her line, and the card comes up a second after
        sleep(7)
        let dir = ProcessInfo.processInfo.environment["SHOTS_DIR"] ?? NSTemporaryDirectory()
        func shot(_ name: String) {
            try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dir + "/" + name + ".png"))
        }
        func point(_ x: CGFloat, _ y: CGFloat) -> XCUICoordinate {
            app.coordinate(withNormalizedOffset: CGVector(dx: x / 402, dy: y / 874))
        }
        func heading(_ start: String) -> XCUIElement {
            app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", start)).firstMatch
        }
        XCTAssertTrue(heading("What feels comfortable").exists)
        XCTAssertTrue(app.staticTexts["BEGINNER"].exists)
        shot("guide-read-1")
        // The knob, from BEGINNER to PRO
        point(60, 698).press(forDuration: 0.05, thenDragTo: point(350, 698), withVelocity: .slow, thenHoldForDuration: 0.3)
        sleep(4)
        shot("guide-read-2")
        app.buttons["Continue"].tap()
        XCTAssertTrue(heading("Tap & hold the widget").waitForExistence(timeout: 3))
        sleep(7)
        shot("guide-hold-1")
        // Continue sleeps until the hold's been done
        app.buttons["Continue"].firstMatch.tap()
        sleep(1)
        XCTAssertTrue(heading("Tap & hold the widget").exists)
        point(200, 520).press(forDuration: 1.5)
        sleep(4)
        // She says well done, and answers a question tapped by putting it off
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Congrats'")).firstMatch.exists)
        shot("guide-hold-2")
        app.descendants(matching: .any).matching(NSPredicate(format: "label == 'Explain me the terms'")).firstMatch.tap()
        sleep(4)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'I’ll definitely answer'")).firstMatch.exists)
        shot("guide-hold-3")
        point(200, 780).tap()
        XCTAssertTrue(heading("Swipe the widget").waitForExistence(timeout: 3))
        sleep(7)
        shot("guide-swipe-1")
        point(80, 520).press(forDuration: 0.05, thenDragTo: point(320, 520), withVelocity: .slow, thenHoldForDuration: 0.2)
        sleep(2)
        shot("guide-swipe-2")
        point(200, 780).tap()
        // and the farewell, before the app itself
        XCTAssertTrue(app.staticTexts["You’re in, have a wealthy life"].waitForExistence(timeout: 4))
        shot("farewell")
        sleep(5)
        XCTAssertFalse(app.staticTexts["You’re in, have a wealthy life"].exists)
        XCTAssertFalse(heading("Swipe the widget").exists)
    }

    func testChangeNumber() {
        let app = XCUIApplication()
        app.launchArguments = ["-onboardingOTP"]
        app.launch()
        // On the OTP step, the number card behind offers to change it
        let change = app.buttons["Change number"]
        XCTAssertTrue(change.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Enter the one-time password sent to your mobile"].exists)
        sleep(1)
        change.tap()
        // and takes you back to entering it
        XCTAssertTrue(app.staticTexts["Add your mobile number"].waitForExistence(timeout: 3))
        sleep(1)
        XCTAssertFalse(app.staticTexts["Enter the one-time password sent to your mobile"].exists)
    }

    func testCodeMovesOn() {
        let app = XCUIApplication()
        app.launchArguments = ["-onboardingOTP"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Enter the one-time password sent to your mobile"].waitForExistence(timeout: 5))
        sleep(1)
        let dir = ProcessInfo.processInfo.environment["SHOTS_DIR"] ?? NSTemporaryDirectory()
        // The whole code typed: it's shown as right
        app.typeText("892392")
        XCTAssertTrue(app.images["Code is correct"].waitForExistence(timeout: 2))
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dir + "/otp-correct.png"))
        // then the button is a loader for a moment (too brief to query reliably), and the next screen comes by itself
        XCTAssertTrue(app.staticTexts["Confirm kyc"].waitForExistence(timeout: 4))
    }

    func testChatScrollsBack() {
        let app = XCUIApplication()
        app.launchArguments = ["-onboardingStep", "1", "-welcomeDone", "-welcomeAnalysis", "-welcomeAdvice"]
        app.launch()
        XCTAssertTrue(app.buttons["View analysis"].waitForExistence(timeout: 4))
        sleep(1)
        // The prompts slide sideways
        let third = app.buttons["How much should I invest each month?"]
        let before = third.frame.minX
        app.buttons["How can I improve my portfolio for better profits?"].swipeLeft()
        sleep(1)
        XCTAssertLessThan(third.frame.minX, before - 50)
        XCTAssertFalse(app.staticTexts["Connect your mutual funds portfolio for personal advise"].exists)
        // The results heading has scrolled away above the avatar
        let results = app.staticTexts["We have all its required to analyze it now"]
        XCTAssertLessThan(results.frame.minY, 150)
        // Pulling the chat down brings it back
        let card = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35))
        card.press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85)))
        sleep(1)
        XCTAssertGreaterThan(results.frame.minY, 150)
        // and pulled far enough, the first question is there
        // from anywhere, rows of cards included
        let top = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45))
        for _ in 0..<5 {
            top.press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95)))
        }
        sleep(1)
        XCTAssertGreaterThan(app.staticTexts["you’re interested in?"].frame.minY, 150)
    }

    func testReportQuestions() {
        let app = XCUIApplication()
        app.launchArguments = ["-onboardingStep", "1", "-analysisDone"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Equity mutual funds 2026"].waitForExistence(timeout: 8))
        sleep(2)
        // A question in the report opens to its answer where it is, and closes again
        let question = app.buttons["Why did it beat the previous six months?"]
        for _ in 0..<4 where !question.isHittable {
            let from = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6))
            from.press(forDuration: 0.02, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45)), withVelocity: .fast, thenHoldForDuration: 0)
            sleep(2)
        }
        XCTAssertTrue(question.isHittable)
        let answer = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "The six months before were a falling market")).firstMatch
        XCTAssertFalse(answer.exists)
        question.tap()
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", "The six months before were a falling market")).firstMatch.waitForExistence(timeout: 2))
        sleep(1)
        let dir = ProcessInfo.processInfo.environment["SHOTS_DIR"] ?? NSTemporaryDirectory()
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dir + "/question-open.png"))
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Why did it beat the previous six months?")).firstMatch.tap()
        sleep(1)
        XCTAssertFalse(app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", "The six months before were a falling market")).firstMatch.exists)
    }

    func testReportRead() {
        let app = XCUIApplication()
        app.launchArguments = ["-onboardingStep", "1", "-analysisDone"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Equity mutual funds 2026"].waitForExistence(timeout: 8))
        sleep(2)
        // Down at its foot, the read on the year: three questions, the second crediting the research
        for _ in 0..<14 { app.swipeUp(velocity: .fast) }
        sleep(1)
        let dir = ProcessInfo.processInfo.environment["SHOTS_DIR"] ?? NSTemporaryDirectory()
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dir + "/read-end.png"))
        XCTAssertTrue(app.staticTexts["What else does Decade look at in a fund?"].exists)
        XCTAssertTrue(app.staticTexts["From Decade Research"].exists)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4))
            .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85)))
        sleep(1)
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dir + "/read-mid.png"))
    }

    func testGender() {
        let app = XCUIApplication()
        app.launchArguments = ["-onboardingPAN"]
        app.launch()
        let dir = ProcessInfo.processInfo.environment["SHOTS_DIR"] ?? NSTemporaryDirectory()
        let field = app.buttons["Gender"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        XCTAssertEqual(field.value as? String, "Select your gender")
        XCTAssertTrue(app.buttons["Edit details"].exists)
        sleep(1)
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dir + "/gender-field.png"))
        // The field opens the choices over the foot of the card
        field.tap()
        XCTAssertTrue(app.buttons["Female"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Other"].exists)
        app.buttons["Male"].tap()
        // and the one picked is shown in the field, and ticked when the choices open again
        XCTAssertFalse(app.buttons["Female"].waitForExistence(timeout: 1))
        XCTAssertEqual(field.value as? String, "Male")
        field.tap()
        XCTAssertTrue(app.buttons["Male"].waitForExistence(timeout: 2))
        sleep(1)
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dir + "/gender-sheet.png"))
        XCTAssertTrue(app.buttons["Male"].isSelected)
    }

    func testAnalysis() {
        let app = XCUIApplication()
        app.launchArguments = ["-onboardingStep", "1", "-welcomeDone", "-researchSeconds", "9"]
        app.launch()
        // With the results in, the agent starts the analysis by itself: the report's card, preparing, which opens it
        let preparing = app.buttons["Preparing report"]
        XCTAssertTrue(preparing.waitForExistence(timeout: 6))
        XCTAssertFalse(app.buttons["Creating analysis"].exists)
        sleep(1)
        preparing.tap()
        XCTAssertTrue(app.staticTexts["Mutual funds analysis"].waitForExistence(timeout: 4))
        XCTAssertFalse(app.staticTexts["While it happens"].exists)
        sleep(3)
        let dir = ProcessInfo.processInfo.environment["SHOTS_DIR"] ?? NSTemporaryDirectory()
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dir + "/a-preparing.png"))
        // When its time is up the analysis opens by itself
        XCTAssertTrue(app.staticTexts["Equity mutual funds 2026"].waitForExistence(timeout: 14))
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dir + "/a-open.png"))
    }

    func testResearchDone() {
        let app = XCUIApplication()
        app.launchArguments = ["-onboardingStep", "1", "-welcomeChat", "-researchSeconds", "4"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Research plan created"].waitForExistence(timeout: 3))
        // When the time is up the plan folds away, the results come in, and the agent goes on to the analysis
        XCTAssertTrue(app.staticTexts["We have all its required to analyze it now"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["Research plan created"].exists)
        XCTAssertFalse(app.buttons["Find insights from research"].exists)
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'Preparing'")).firstMatch.waitForExistence(timeout: 6))
        XCTAssertTrue(app.buttons["Mutual funds research plan"].exists)
    }

    func testWelcomeChat() {
        let app = XCUIApplication()
        // A long research, so it's still running through every step that looks at it
        app.launchArguments = ["-onboardingStep", "1", "-researchSeconds", "90"]
        app.launch()
        // Continue forms under the card and sends the message
        let next = app.buttons["Lets get started"]
        XCTAssertTrue(next.waitForExistence(timeout: 8))
        sleep(1)
        let dirW = ProcessInfo.processInfo.environment["SHOTS_DIR"] ?? NSTemporaryDirectory()
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dirW + "/w-welcome.png"))
        next.tap()
        // How the research is done comes up first, and nothing is said until it's understood
        let understood = app.buttons["Understood"]
        XCTAssertTrue(understood.waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["Decade Research"].exists)
        XCTAssertTrue(app.staticTexts["Data backed with Morningstar"].exists)
        XCTAssertTrue(app.staticTexts["SEBI registered advisory team"].exists)
        XCTAssertTrue(app.staticTexts["Advisory Decisioning"].exists)
        XCTAssertFalse(app.staticTexts["you’re interested in?"].exists)
        sleep(2)
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dirW + "/w-research.png"))
        understood.tap()
        // The agent opens with a heading, an offer, and topics to start on
        XCTAssertTrue(app.staticTexts["you’re interested in?"].waitForExistence(timeout: 4))
        let topic = app.buttons["How have equity mutual funds done over the last year and what does that tell us about the future?"]
        XCTAssertTrue(topic.waitForExistence(timeout: 6))
        sleep(2)
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dirW + "/w-topics.png"))
        // "Build me a mutual fund portfolio" is suggested first, ahead of it
        XCTAssertTrue(app.buttons["Build me a mutual fund portfolio"].exists)
        // Its frame takes in the whole two-row rail, so aim at the second card of the top row (the cards are 186
        // wide, 17 apart, 19 in from the rail's edge)
        topic.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: 19 + 186 + 17 + 70, dy: 90)).tap()
        // The topic goes in as the message, then a reply and the plan it's preparing
        XCTAssertTrue(app.staticTexts["How have equity mutual funds done over the last year and what does that tell us about the future?"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Mutual funds research plan"].waitForExistence(timeout: 6))
        XCTAssertFalse(app.staticTexts["Research plan created"].exists)
        // which stays closed, the research running from the chip, until the chip's tapped
        sleep(2)
        XCTAssertFalse(app.staticTexts["Creating the plan"].exists)
        app.buttons["Mutual funds research plan"].tap()
        XCTAssertTrue(app.staticTexts["Creating the plan"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["Research plan created"].waitForExistence(timeout: 4))
        // Tapping the chat behind folds it back into the chip
        sleep(2)
        // on the strip of it that shows above the sheet
        app.buttons["Back to chat"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.06)).tap()
        sleep(1)
        XCTAssertFalse(app.staticTexts["Research plan created"].exists)
        XCTAssertTrue(app.buttons["Mutual funds research plan"].isHittable)
        // While the research runs, what it's doing shows under the chip; no report card until the analysis is built
        sleep(3)
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dirW + "/w-step-a.png"))
        sleep(3)
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dirW + "/w-step-b.png"))
        sleep(4)
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dirW + "/w-step-c.png"))
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Preparing'")).firstMatch.exists
            || app.otherElements.matching(NSPredicate(format: "label CONTAINS 'Preparing'")).firstMatch.exists)
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dirW + "/w-preparing.png"))
        // and the chip opens it again, already all there
        app.buttons["Mutual funds research plan"].tap()
        // The chip shifts as the live research under it changes height; a tap that lands mid-shift is tried once more
        if !app.staticTexts["Research plan created"].waitForExistence(timeout: 3) {
            app.buttons["Mutual funds research plan"].tap()
        }
        XCTAssertTrue(app.staticTexts["Research plan created"].waitForExistence(timeout: 3))
        sleep(2)
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dirW + "/w-plan-again.png"))
        // The close at the top right folds it away too
        XCTAssertTrue(app.buttons["Close research"].waitForExistence(timeout: 3))
        app.buttons["Close research"].tap()
        sleep(1)
        XCTAssertFalse(app.staticTexts["Research plan created"].exists)
    }

    func testAdvisoryChat() {
        let app = XCUIApplication()
        app.launchArguments = ["-onboardingStep", "2"]
        app.launch()
        let suggestion = app.buttons["Lets start with Research"]
        XCTAssertTrue(suggestion.waitForExistence(timeout: 6))
        sleep(1)
        suggestion.tap()
        sleep(3)
        XCTAssertFalse(app.buttons["Lets start with Research"].exists)
        XCTAssertTrue(app.staticTexts["Lets start with Research"].exists)

        // The agent says it's starting, thinks again, and the research sheet comes up with its sources
        XCTAssertTrue(app.staticTexts["Research plan created"].waitForExistence(timeout: 8))
        sleep(4)
        let first = app.staticTexts["HDFC Midcap fund direct growth - NAV"]
        XCTAssertTrue(first.exists)
        for _ in 0..<4 { app.swipeUp() }
        sleep(1)
        XCTAssertFalse(first.isHittable)
    }

    func testOnboardingIntro() {
        let app = XCUIApplication()
        app.launchArguments = ["-onboarding"]
        app.launch()
        sleep(4)
        // The terms open as a sheet that scrolls, and Understood puts it away
        let termsLink = app.buttons["Read the terms and conditions"]
        termsLink.tap()
        sleep(1)
        XCTAssertTrue(app.staticTexts["Terms & Conditions"].exists)
        let dir0 = ProcessInfo.processInfo.environment["SHOTS_DIR"] ?? NSTemporaryDirectory()
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dir0 + "/terms.png"))
        app.swipeUp()
        sleep(1)
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dir0 + "/terms-scrolled.png"))
        app.buttons["Understood"].tap()
        sleep(1)
        XCTAssertFalse(app.staticTexts["Terms & Conditions"].exists)
        // The page shrinks into the phone card and the number pad comes up
        app.buttons["Agree and Continue"].tap()
        sleep(2)
        let dir = ProcessInfo.processInfo.environment["SHOTS_DIR"] ?? NSTemporaryDirectory()
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dir + "/intro-phone.png"))
        app.textFields.firstMatch.typeText("9871156837")
        sleep(1)
        // The phone card steps back with the number; the OTP card drops in
        app.buttons["Verify"].tap()
        sleep(2)
        app.typeText("889302")
        sleep(1)
        // The OTP card steps back into the heading; the sphere card lands
        app.buttons["Verify"].tap()
        sleep(3)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Verify your pan")).firstMatch.exists)
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dir0 + "/kyc-loading.png"))
        // Five seconds on, the sphere flattens over the card and reveals the PAN card; Verify comes back
        sleep(8)
        XCTAssertTrue(app.staticTexts["VANGIPURAPPU VENKATA"].exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Confirm your")).firstMatch.exists)
        XCTAssertTrue(app.buttons["Confirm"].isHittable)
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dir0 + "/kyc-found.png"))
    }

    func testChatSend() {
        let app = XCUIApplication()
        app.launchArguments = ["-experience", "chat"]
        app.launch()
        sleep(2)
        let field = app.textFields.firstMatch
        field.tap()
        field.typeText("Should I pause my SIP?\n")
        sleep(4)
        field.tap()
        field.typeText("Ok, show me past dips\n")
        sleep(4)
    }

    /// The fixed deposits page: hold a card, swipe it to the composer, the advisor pill, then a tap pushes the bank's page
    func testFDHome() {
        let app = XCUIApplication()
        app.launchArguments = ["-fd"]
        app.launch()
        sleep(2)
        func shot(_ name: String) {
            let dir = ProcessInfo.processInfo.environment["SHOTS_DIR"] ?? NSTemporaryDirectory()
            try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dir + "/" + name + ".png"))
        }
        func at(_ x: CGFloat, _ y: CGFloat) -> XCUICoordinate {
            app.coordinate(withNormalizedOffset: CGVector(dx: x / 402, dy: y / 874))
        }
        XCTAssertTrue(app.staticTexts["Browse all fixed deposits"].exists)
        shot("home-1")
        app.swipeUp(velocity: .slow)
        sleep(1)
        app.swipeUp(velocity: .slow)
        sleep(1)
        shot("home-2")
        at(200, 300).press(forDuration: 0.9)
        sleep(2)
        shot("home-held")
        at(200, 840).tap()
        sleep(2)
        at(60, 300).press(forDuration: 0.05, thenDragTo: at(280, 300), withVelocity: .slow, thenHoldForDuration: 0.6)
        sleep(2)
        shot("home-swiped")
        at(200, 100).tap()
        sleep(2)
        app.swipeUp(velocity: .slow)
        sleep(1)
        shot("home-3")
        app.swipeUp(velocity: .slow)
        sleep(1)
        shot("home-4")
        // A bank's card opens its page; found by name, wherever the page has scrolled to
        let card = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Suryoday SF Bank'")).firstMatch
        var tries = 0
        while !(card.exists && card.isHittable && card.frame.midY < 700) && tries < 6 {
            app.swipeDown(velocity: .slow)
            sleep(1)
            tries += 1
        }
        card.tap()
        sleep(2)
        XCTAssertTrue(app.staticTexts["FIXED DEPOSIT"].exists)
        shot("home-bank")
        at(32, 95).tap()
        sleep(2)
        XCTAssertTrue(app.staticTexts["Ask your advisor"].exists)
    }

    /// Search on the fixed deposits page: an intent narrows the deposits, a bank opens its page, and a pull down opens it too
    /// The switch's "Your deposits" side: the chart, the states and a card per deposit
    func testFDYourDeposits() {
        let app = XCUIApplication()
        app.launchArguments = ["-fd"]
        app.launch()
        sleep(2)
        func shot(_ name: String) {
            let dir = ProcessInfo.processInfo.environment["SHOTS_DIR"] ?? NSTemporaryDirectory()
            try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dir + "/" + name + ".png"))
        }
        app.buttons["Your deposits"].tap()
        usleep(600_000)
        shot("yours-growing")
        sleep(2)
        XCTAssertTrue(app.staticTexts["Total deposits"].exists)
        XCTAssertTrue(app.staticTexts["Active fixed deposit"].exists)
        XCTAssertFalse(app.staticTexts["Browse all fixed deposits"].exists)
        XCTAssertTrue(app.buttons["3Y"].isSelected)
        shot("yours-1")
        app.buttons["5Y"].tap()
        sleep(1)
        XCTAssertTrue(app.buttons["5Y"].isSelected)
        app.swipeUp()
        sleep(1)
        shot("yours-2")
        // A row opens that deposit's own page, and Back returns
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Bajaj Finance'")).firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Fixed deposit growth"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["View FD Certificate"].exists)
        sleep(2)
        shot("held-1")
        app.swipeUp()
        sleep(1)
        shot("held-2")
        app.swipeUp()
        sleep(1)
        shot("held-3")
        app.swipeDown()
        app.swipeDown()
        sleep(1)
        app.buttons.matching(identifier: "Back").allElementsBoundByIndex.last?.tap()
        sleep(2)
        XCTAssertTrue(app.staticTexts["Active fixed deposit"].exists)
        XCTAssertFalse(app.buttons["View FD Certificate"].exists)
        app.swipeDown()
        sleep(1)
        app.buttons["All"].tap()
        sleep(1)
        XCTAssertTrue(app.staticTexts["Create your fixed deposit plan"].exists)
    }

    /// "Compare returns" joins the bar once the banks have started to show
    func testFDCompare() {
        let app = XCUIApplication()
        app.launchArguments = ["-fd"]
        app.launch()
        sleep(2)
        func shot(_ name: String) {
            let dir = ProcessInfo.processInfo.environment["SHOTS_DIR"] ?? NSTemporaryDirectory()
            try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dir + "/" + name + ".png"))
        }
        XCTAssertFalse(app.buttons["Compare returns"].exists)
        app.swipeUp()
        sleep(2)
        XCTAssertTrue(app.buttons["Compare returns"].exists)
        shot("compare-bar")
        app.buttons["Compare returns"].tap()
        sleep(2)
        XCTAssertTrue(app.staticTexts["Enter investment amount"].exists)
        shot("compare-sheet")
        for key in ["5", "0", "0", "0", "0"] { app.buttons[key].tap() }
        app.buttons["Calculate Returns"].tap()
        sleep(2)
        // The heading stays; the cards carry what the amount comes to
        XCTAssertTrue(app.staticTexts["Browse all fixed deposits"].exists)
        XCTAssertTrue(app.staticTexts["Rs53,725"].exists)
        shot("compare-done")
        // "Compare returns" has given way to the amount and the tenures; another tenure changes the returns
        XCTAssertFalse(app.buttons["Compare returns"].exists)
        XCTAssertTrue(app.buttons["Edit amount"].exists)
        app.buttons["3Y"].tap()
        sleep(1)
        XCTAssertFalse(app.staticTexts["Rs53,725"].exists)
        shot("compare-3y")
        // The amount reopens the sheet
        app.buttons["Edit amount"].tap()
        sleep(1)
        XCTAssertTrue(app.staticTexts["Enter investment amount"].exists)
        app.buttons["Back to deposits"].tap()
        sleep(1)
        // Scrolled back up, the bar goes with the banks
        app.swipeDown()
        app.swipeDown()
        sleep(2)
        XCTAssertFalse(app.buttons["Edit amount"].exists)
        shot("compare-gone")
        // (the second pull opens search; put it away)
        if app.buttons["Cancel"].exists { app.buttons["Cancel"].tap(); sleep(1) }
        // and the cross puts the rates and "Compare returns" back
        app.swipeUp()
        sleep(2)
        app.buttons["Clear amount"].tap()
        sleep(1)
        XCTAssertTrue(app.buttons["Compare returns"].exists)
        XCTAssertFalse(app.buttons["Edit amount"].exists)
        shot("compare-cleared")
    }

    func testFDSearch() {
        let app = XCUIApplication()
        app.launchArguments = ["-fd"]
        app.launch()
        sleep(2)
        func shot(_ name: String) {
            let dir = ProcessInfo.processInfo.environment["SHOTS_DIR"] ?? NSTemporaryDirectory()
            try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dir + "/" + name + ".png"))
        }
        func at(_ x: CGFloat, _ y: CGFloat) -> XCUICoordinate {
            app.coordinate(withNormalizedOffset: CGVector(dx: x / 402, dy: y / 874))
        }
        app.buttons["Search"].tap()
        sleep(1)
        shot("search-open")
        app.typeText("short")
        sleep(1)
        shot("search-typed")
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Short term'")).firstMatch.tap()
        sleep(2)
        XCTAssertTrue(app.buttons["Clear search"].exists)
        app.swipeUp(velocity: .slow)
        sleep(1)
        shot("search-intent")
        app.buttons["Clear search"].tap()
        sleep(1)
        app.swipeDown(velocity: .fast)
        sleep(1)
        // Pull the page down past the threshold and let go
        at(200, 300).press(forDuration: 0.05, thenDragTo: at(200, 520), withVelocity: .slow, thenHoldForDuration: 0.1)
        sleep(2)
        shot("search-pulled")
        app.typeText("jana")
        sleep(1)
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Jana SF Bank'")).firstMatch.tap()
        sleep(2)
        XCTAssertTrue(app.staticTexts["FIXED DEPOSIT"].exists)
        shot("search-bank")
    }
}
