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
        app.launchArguments = ["-fd"]
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
        app.launchArguments = ["-fd"]
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
        app.launchArguments = ["-fd", "-fdBankV1"]
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
    func testFDBankPageV2() {
        let app = XCUIApplication()
        app.launchArguments = ["-fd"]
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
        app.buttons["Verify"].tap()
        sleep(4)
        XCTAssertTrue(app.staticTexts["Welcome to Decade Advisory"].exists)
    }

    func testFixedDeposits() {
        let app = XCUIApplication()
        app.launchArguments = ["-fd"]
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
        app.launchArguments = ["-fd"]
        app.launch()
        let compare = app.buttons["Compare returns"]
        XCTAssertTrue(compare.waitForExistence(timeout: 3))
        sleep(1)
        compare.tap()
        // The sheet comes up with its number pad
        XCTAssertTrue(app.staticTexts["Enter investment amount"].waitForExistence(timeout: 2))
        sleep(1)
        for key in ["1", "5", "0", "0", "0", "0"] { app.buttons[key].tap() }
        XCTAssertTrue(app.staticTexts["1,50,000"].exists)
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
        // The finished analysis waits on Understood
        let understood = app.buttons["Understood"]
        XCTAssertTrue(understood.waitForExistence(timeout: 12))
        sleep(1)
        understood.tap()
        // then it's kept in the chat, and the agent turns to personal advice, with prompts to ask it
        XCTAssertTrue(app.buttons["View analysis"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["useful when its"].waitForExistence(timeout: 5))
        let prompt = app.buttons["How can I improve my portfolio for better profits?"]
        XCTAssertTrue(prompt.waitForExistence(timeout: 5))
        sleep(2)
        prompt.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        // Advice that personal needs the funds
        XCTAssertTrue(app.staticTexts["Connect your mutual funds portfolio for personal advise"].waitForExistence(timeout: 3))
        sleep(1)
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.staticTexts["We will import mutual funds via MFCentral"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Upload your portfolio yourself"].exists)
        // Tapping the strip of chat above it puts it away, and the stored analysis opens again
        sleep(1)
        app.buttons["Mutual funds performance"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)).tap()
        sleep(1)
        XCTAssertFalse(app.staticTexts["We will import mutual funds via MFCentral"].exists)
        app.buttons["View analysis"].tap()
        XCTAssertTrue(app.staticTexts["Fund rank movements"].waitForExistence(timeout: 3))
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
        XCTAssertTrue(app.staticTexts["Add your mobile number linked with official records"].waitForExistence(timeout: 3))
        sleep(1)
        XCTAssertFalse(app.staticTexts["Enter the one-time password sent to your mobile"].exists)
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
        XCTAssertGreaterThan(app.staticTexts["with a topic you’re"].frame.minY, 150)
    }

    func testAnalysis() {
        let app = XCUIApplication()
        app.launchArguments = ["-onboardingStep", "1", "-welcomeDone", "-researchSeconds", "9"]
        app.launch()
        // With the results in, the agent starts the analysis by itself; the chip opens it
        let chip = app.buttons["Creating analysis"]
        XCTAssertTrue(chip.waitForExistence(timeout: 4))
        sleep(1)
        XCTAssertFalse(app.staticTexts["While it happens"].exists)
        chip.tap()
        XCTAssertTrue(app.staticTexts["While it happens"].waitForExistence(timeout: 4))
        // While it works, a curve drawn in the box finds its fund
        let canvas = app.otherElements["CurveCanvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 3))
        sleep(1)
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.06, dy: 0.85))
            .press(forDuration: 0.05, thenDragTo: canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.94, dy: 0.15)))
        XCTAssertTrue(app.staticTexts["This is the fund"].waitForExistence(timeout: 3))
        // When its time is up it becomes the analysis
        XCTAssertTrue(app.staticTexts["Fund rank movements"].waitForExistence(timeout: 12))
        XCTAssertFalse(app.staticTexts["While it happens"].exists)
        // and folds back into its chip from the card behind
        sleep(1)
        app.buttons["Mutual funds performance"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)).tap()
        sleep(1)
        XCTAssertFalse(app.staticTexts["Fund rank movements"].exists)
        XCTAssertTrue(app.buttons["Analysis ready"].isHittable)
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
        XCTAssertTrue(app.buttons["Creating analysis"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["Mutual funds research plan"].exists)
    }

    func testWelcomeChat() {
        let app = XCUIApplication()
        app.launchArguments = ["-onboardingStep", "1"]
        app.launch()
        // Continue forms under the card and sends the message
        let next = app.buttons["Continue"]
        XCTAssertTrue(next.waitForExistence(timeout: 8))
        sleep(1)
        next.tap()
        // How the research is done comes up first, and nothing is said until it's understood
        let understood = app.buttons["Understood"]
        XCTAssertTrue(understood.waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["Research"].exists)
        XCTAssertFalse(app.staticTexts["with a topic you’re"].exists)
        sleep(2)
        understood.tap()
        // The agent opens with a heading, an offer, and topics to start on
        XCTAssertTrue(app.staticTexts["with a topic you’re"].waitForExistence(timeout: 4))
        let topic = app.buttons["How mutual funds performed in the last 6 months?"]
        XCTAssertTrue(topic.waitForExistence(timeout: 6))
        sleep(2)
        topic.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        // The topic goes in as the message, then a reply and the plan it's preparing
        XCTAssertTrue(app.staticTexts["How mutual funds performed in the last 6 months?"].waitForExistence(timeout: 3))
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
        // While the research runs, the chip says what it's reading
        sleep(3)
        // and the chip opens it again, already all there
        app.buttons["Mutual funds research plan"].tap()
        XCTAssertTrue(app.staticTexts["Research plan created"].waitForExistence(timeout: 3))
        sleep(2)
        // The close at the top right folds it away too
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
        // The card shrinks into the phone form and the number pad comes up
        app.buttons["Agree & Continue"].tap()
        sleep(2)
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
        XCTAssertTrue(app.staticTexts["Verify your identity"].exists)
        // Five seconds on, the sphere flattens over the card and reveals the PAN card; Verify comes back
        sleep(8)
        XCTAssertTrue(app.staticTexts["VANGIPURAPPU VENKATA"].exists)
        XCTAssertTrue(app.buttons["Verify"].isHittable)
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
}
