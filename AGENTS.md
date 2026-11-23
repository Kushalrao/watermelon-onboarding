# MutualFundsPrototype: handoff for a coding agent

Written 2026-11-21. This is the working context for picking up where the last session stopped. It covers the
state of the work, how the owner wants things done, how to build and test, and a map of the second onboarding,
which is where all recent work has been.

`CLAUDE.md` in this folder holds the design-system rules (tokens, `DsText`, `Surface`, the lint). Read it too;
this file does not repeat it.

## 1. Where things stand

- SwiftUI iOS prototype, iOS 18, generated with XcodeGen from `project.yml`. Bundle id
  `com.kushal.prototype.MutualFundsPrototype`.
- Git: branch `demo`, remote `origin`, with PR #1 open. As of 2026-11-23 everything is committed and pushed:
  `59a5a67` is the second onboarding, `61ac286` the mutual funds work. Commit and push only when the owner asks.
- A plain launch (no flags) opens the mutual funds homepage, second version (`Sources/MutualFundsHomeV2.swift`,
  Figma `sub7vIn6sMBlHb4SIWHyek` node 47:6749). The first version (`Sources/MutualFundsHome.swift`, node 10:4545
  with sections 15:6246, 15:6247 and 15:6248 and the fund houses' map 15:6337 in
  `Sources/MutualFundsHouseMap.swift`) is behind `-mfHomeV1`. A fund opens `Sources/MutualFundDetail.swift`
  (node 37:3821), with its content from `Sources/MutualFundData.swift`. The second onboarding needs `-onboarding`.
- The mutual funds screens were checked on the simulator and on a device; they have no UI tests yet.
- Last verified: `testOnboardingV2ReportCompare` passed after the most recent change (the side blur on the
  compare frame), and the lint is clean. The full walk-through, `testOnboardingV2Welcome`, has **not** been
  re-run since two later changes (the default report version flipping back, and the side blur). Run it before
  relying on it.

## 2. How the owner works

These are standing instructions, gathered over the sessions.

- **Follow Figma exactly.** Positions, sizes, copy and colours come from the node the owner links. Typos in
  the Figma copy are kept as they are (for example "Lets see how to use the app").
- **Do not add what was not asked for.** No extra screens, controls, copy or animation.
- **No staggered appear transitions by default.** Content shows at once unless the owner asks for a reveal.
  Reveals already in place that the owner has seen and kept stay.
- **Do not change the first onboarding (v1).** Changes to shared v1 files must be additive and leave v1's
  behaviour as it was (a new parameter with the old value as its default).
- **Keep what is replaced when asked.** When the owner says to retain a version, put it behind a launch flag
  rather than deleting it (see section 6).
- **The default launch opens the area being worked on**, from that area's entry screen. A change hidden behind
  a flag is not reachable for the owner, who runs the app without flags.
- **Commit and push only when asked.**
- **Never send the owner's personal details to outside services.** Downloading public assets needs a yes
  first (the 50 company logos were approved once; that does not carry over).
- The owner uses the Simulator while tests run. A stray tap can fail a UI test once; rerun before believing a
  failure.
- Instructions arrive terse and with typos. Read them for intent, and when one can be read two ways, say which
  reading was taken.
- Names the owner uses: **"advisory animation"** is the transition before "Meet your personal advisor"
  (`WorldBefore`), not the research-document animation.

## 3. Build, run, test

Always `cd` to the project folder first.

```bash
D=174632DC-4744-4970-869D-80F9693E14FF          # iPhone 17 Pro simulator, 402 × 874 pt, top inset 62

xcodegen generate -q                             # after adding or removing any file

xcodebuild -project MutualFundsPrototype.xcodeproj -scheme MutualFundsPrototype \
  -destination "id=$D" -derivedDataPath build build \
  | grep -E "\.swift:[0-9]+:[0-9]+: error|BUILD (SUCCEEDED|FAILED)"

# one UI test
xcodebuild -project MutualFundsPrototype.xcodeproj -scheme MutualFundsPrototype \
  -destination "id=$D" -derivedDataPath build test \
  -only-testing:MutualFundsPrototypeUITests/GestureTests/testOnboardingV2ReportCompare \
  | grep -E "\.swift:[0-9]+:[0-9]+: error|TEST BUILD|Test Case|\*\* TEST"

python3 tools/lint/check_ds_rules.py             # must stay clean
```

- Use `build-for-testing` then `test-without-building` to split a slow run. UI tests can take several minutes;
  give the command a long timeout.
- Simulators are managed with **simslim** (`/opt/homebrew/bin/simslim`): `simslim boot $D`, then
  `xcrun simctl bootstatus $D`. `simslim erase` and `simslim delete` destroy data: ask first.
- Install and launch by hand:
  `xcrun simctl install $D build/Build/Products/Debug-iphonesimulator/MutualFundsPrototype.app`, then
  `xcrun simctl launch $D com.kushal.prototype.MutualFundsPrototype <flags>`, and `open -a Simulator`.
- Screenshots from a UI test: prefix `xcodebuild` with `TEST_RUNNER_SHOTS_DIR=<dir>`; tests read `SHOTS_DIR`
  in their `shot(_:)` helper. Write them outside the repo and delete them afterwards.
- Recording: `xcrun simctl io $D recordVideo --codec h264 -f out.mov` in the background, stop it with
  `kill -INT`. For timing, read real packet times with `ffprobe` (`packet=pts_time`) and extract frames with
  `-fps_mode passthrough`; the `fps=` filter gave wrong frames. If it says "Host recording is already in
  progress", `simslim shutdown $D` then `simslim boot $D`.
- Temporary tests written for a recording (`testTMP…`) must be removed afterwards. None remain now.

## 4. Launch flags

| Flag | Opens |
|---|---|
| none, or `-mf` | the mutual funds homepage, second version (`MutualFundsHomeV2View`, Figma 47:6749) |
| `-mfHomeV1` | the first mutual funds homepage (`MutualFundsHomeView`), with the fund houses' map |
| `-mfFund` | the homepage with the drawn fund's page (`MutualFundDetailView`, Figma 37:3821) already pushed over it. Each fund's content is in `Sources/MutualFundData.swift`; all but HSBC's is sample data |
| `-onboarding` | second onboarding from its first screen |
| `-onboardingV1` | the first onboarding, whole |
| `-onboardingStep N` | second onboarding at step `0` (intro) or `20` (opening) |
| `-onboardingV2Stage N` | the opening at stage N, 0 to 13 (use with `-onboardingStep 20`) |
| `-onboardingPhone`, `-onboardingOTP`, `-onboardingPAN` (or `-onboardingIdentity`) | the intro at its number, code or KYC frame |
| `-onboardingIntroV1` | the first onboarding's intro (PAN looked up) inside the second |
| `-researchGather` | the earlier research frame: documents gathering into a report on a phone |
| `-reportSimple` | the other report-making version (section 6) |
| `-home`, `-homeV1` … `-homeV4`, `-fund`, `-fd`, `-fd…` | home page versions, fund page, fixed deposits |
| `-experience chat` | the standalone chat (the `ChatPrototype` scheme) |

Example: `-onboardingStep 20 -onboardingV2Stage 6` opens on the topics frame, one tap from the report.

## 5. The second onboarding

### Files

| File | What it holds |
|---|---|
| `Sources/OnboardingV2.swift` | `OnboardingVersion`, `OnboardingFlowV2`: step 0 is the intro, step 20 the opening, then `onFinish` |
| `Sources/OnboardingV2Intro.swift` | `OnboardingIntroV2View`: welcome, mobile number, OTP, KYC |
| `Sources/OnboardingV2Welcome.swift` | `OnboardingWelcomeV2View`: the opening, one staged view of about 2,900 lines |
| `Sources/OnboardingV2Guides.swift` | `OnboardingV2HoldWidget`, `OnboardingV2SwipeWidget`, `OnboardingV2LevelsWidget` |
| `Sources/OnboardingComplexity.swift`, `OnboardingAnalysis.swift`, `OnboardingIntro.swift` | v1 files with additive changes only: `ComplexityCard.quick` and `soft`, `HeatSweep.glass`, `ReportReel.held`, and `PhoneNumberField` / `OneTimeCodeField` made non-private |
| `UITests/GestureTests.swift` | `testOnboardingV2Welcome` (full walk-through, launched with `-reportSimple`) and `testOnboardingV2ReportCompare` (default version, from stage 6) |

The long doc comment at the top of `OnboardingWelcomeV2View` describes every frame with its Figma node and is
kept current. Read it before changing anything in that file.

### Intro (`OnboardingIntroV2View`)

Stages `welcome, mobile, otp, kyc`. Figma: 1341:1275, 1362:6812, 1362:6984, 1362:7246, tick 1362:7536.

- Welcome: a phone mock with a looping scripted finance chat (`IntroChat`), the Decade mark, heading,
  "Agree & Continue", and a terms link.
- Mobile: Continue enables at 10 digits. OTP: "Change number" goes back; no resend countdown, no auto-advance.
- KYC slides up from the bottom with fixed details. Continue shows a green `DoneTick`, and 1.1 s later the
  flow moves on. The v1 PAN loader is not part of this flow; it survives behind `-onboardingIntroV1`.

### Opening (`OnboardingWelcomeV2View.Stage`)

| # | Stage | Heading | Figma | What happens, and how it moves on |
|---|---|---|---|---|
| 0 | `welcome` | Welcome to new standard of wealth advisory | 1267:12910 | four cards, two by two, no horizontal scroll. Continue |
| 1 | `simplest` | Proactive, so you don't miss | 1251:12475, phone 1341:2551 | `FindingsTurn`: one finding at a time between two handles, three background washes in turn. Continue |
| 2 | `research` | Analysis backed by research | 1267:15806 | `TurningBook`: a blank book with turning pages, no phone. Continue |
| 3 | `meet` | Meet your personal advisor | 1341:2567, 1362:5808 | the advisory animation (`WorldBefore`), then her portrait and the "Ask your advisor" pill with "Tap to try!". Tap the pill |
| 4 | `access` | Access your advisor anytime | 1249:6146 | **no longer visited**: `advance()` skips it from `meet`. Kept in the enum |
| 5 | `typing` | none | 1362:6195 | tick, pill rides up over a keyboard. Moves on by itself after 1.9 s |
| 6 | `topics` | Tell your advisor to research on a topic | 1251:7096 | prompts in two columns on the phone. Tap one |
| 7 | `chat` | none | 1354:3723 | tick at once. `ResearchRun` scrolls what the advisor goes through, in steps, for 4.75 s, then the report comes clear from the top down |
| 8 | `simple` | Wealth simplified for you | 1249:4944, 1249:5255, 1277:18139 | the compare line: report on the left, simple version on the right. Continue |
| 9 | `usage` | Lets see how to use the app | 1362:7957 | words alone, no phone. Moves on after 1.9 s |
| 10 | `hold` | Hold any widget to get curious | 1249:2716 | hold the widget. Tick, then on by itself 0.6 s after the questions show. No Continue |
| 11 | `swipe` | Swipe and get specific | 1251:6920 | swipe the widget. Tick, then on by itself. No Continue |
| 12 | `levels` | Adjust to what feels comfortable | 792:13117 | reading-level card and slider; the level changes immediately. Continue |
| 13 | `connect` | All set! Connect your portfolio & get insights | 1251:12800 | "Connect mutual funds" brings up `MFCentralImportSheet`; going on from it ends the onboarding |

Stage timings live in the `.task(id: stage)` switch in the view's `body`. `next()` is a tapped advance (with
a haptic); `advance()` is the plain one.

### The compare frame (stage 8), the most recent work

- `Compare` is an `@Observable` class holding `split` (0 is all simple, 1 is all report), `reportLeads`
  (derived in `split`'s `didSet`, true above 0.5), `focusing`, `shown`, `touched` and `simplified`. It is kept
  apart from the view's `@State` so dragging the line redraws only `CompareLayer`.
- The line comes in, sways across and back twice, and rests at `splitRest = 0.25` (three quarters simple).
- The side with less of the screen is blurred (`unfocused = 7`), and the two sides swap over
  `refocusing = .easeInOut(duration: 0.9)` when the line crosses the middle. The blur starts only once
  `focusing` is true: when the sway comes to rest, when a drag starts, or on the accessibility adjust action.
- Dragged all the way left, the heading becomes "Decades of research, simplified for you".

### How the opening is built

- **Layout.** Frames are 390 × 840 in Figma. On device: `side = (screenWidth − 390) / 2` and
  `y = figmaY − 44 + top`, with `top` from `@Environment(\.onboardingTop)`. Views are placed with the
  `.at(x, y)` helper.
- **One view, many stages.** The ground and the status-bar rule stay put; headings change through the
  `Wording` transition; the shared spring is `move = .spring(response: 0.6, dampingFraction: 0.84)`.
- **The phone** is drawn once and moves between stages (`Stage.deviceTop`, `Stage.veil`). It shows when
  `(stage == .meet && met) || (stage >= .access && stage < .connect && stage != .usage)`. At `meet` and
  `typing` it is drawn larger (`loneZoom`) with only the pill visible.
- **Time-driven drawing.** `GatherField`, `DocStream` and `TurningBook` are `TimelineView(.animation)` with
  `Canvas`, using seeded xorshift shuffles so each run looks the same.
- **Haptics** go through `Haptics` (`tap`, `beat(strength:)`, `landed`, `settle`, `prepare`). They have not
  been felt on a real device.
- **Styling.** Onboarding files are not in the lint's `ADOPTED` list. They match Figma with `FigmaFont`,
  `Color(hex:)`, raw `Text` and `GapText`, with `// Gap:` comments on off-scale values. Keep that for the
  onboarding. Screens outside it follow `CLAUDE.md`.

### Things that have gone wrong before

- A view removed from a `ZStack` drops behind its siblings and vanishes at once unless it has an explicit
  `.zIndex`. On the phone: `ResearchRun` 1, `CompareLayer` 2, the island 3.
- `.animation(nil, value:)` on a moving view also kills its position animation. Scope it:
  `.animation(nil) { $0.opacity(...) }`.
- The report under `ResearchRun` is the real v1 chat run unseen at `chatPace = 40`; `reportUp()` waits 0.5 s
  for it to settle before `chatReported` is set. Shortening either brought back a blank frame at the hand-off.
- The level card collides with its own text at 292 wide, so it is laid out at 326 and scaled down.
- In UI tests, states that last about a second (the tick) cannot be asserted reliably because of XCUITest's
  idle wait. Assert what follows, or wait for disappearance. Use `.firstMatch` where the hidden chat
  duplicates a label.

## 6. Versions kept behind flags

| What | Default | Kept version |
|---|---|---|
| Report making after a topic is picked | `ResearchRun`, then the report and the compare line | `-reportSimple`: `SimpleMaking` (a stream of documents on a yellow wash, then the simple report alone, no drag line) |
| Research frame (stage 2) | `TurningBook` | `-researchGather`: `ReportAssembly` on a phone |
| Intro | `OnboardingIntroV2View` | `-onboardingIntroV1`: v1 intro with the PAN loader |
| Whole onboarding | v2 | `-onboardingV1` |

The switches are `static let compares` and `static let gathers` in `OnboardingWelcomeV2View`, and
`firstIntro` in `OnboardingFlowV2`.

## 7. Figma

- File key `q8Ms61bjVPwvXtyroY01ed` for the onboarding. (The design system's file is in `CLAUDE.md`.)
- The owner links nodes as `node-id=1362-7957`; the same node is written `1362:7957` in code comments.
- The usual Figma MCP connections were not working in the last session. What worked: with the Figma desktop
  app open and its Dev Mode MCP server on, it listens at `http://127.0.0.1:3845/mcp`. A short JSON-RPC script
  can call `get_design_context` and `get_metadata` there, and assets download from
  `http://localhost:3845/assets/<hash>.svg|png`. If the port refuses connections, Figma desktop is closed or
  the server is off; ask the owner to open it.
- New images go into `Resources/Assets.xcassets` as their own image sets. Use the asset Figma gives; do not
  redraw it.

## 8. Open items

Waiting on the owner:

- The third point of the "Wealth intelligence is powered with" sheet (`Sources/OnboardingResearchIntro.swift`,
  a v1 screen). The owner said they would supply it. Do not invent one.

Known and already told to the owner, none of it asked to be fixed:

- Haptics are untested on a device.
- The advisor's entry in the advisory animation was asked for "0.4x slow"; it was read as 0.4× speed.
- In the default version the report appears about 4.75 s after the topic tap.
- A prompt pill reading "Is Parag Pareikh…" is clipped and misspelt, as in Figma.
- White text on the mauve findings card is low in contrast.
- VoiceOver may expose the hidden report's text while `ResearchRun` covers it.
- The KYC date-of-birth placeholder was replaced with `15/08/1999`.
- The 50 extra logos in the advisory animation were chosen by which sites served a large enough icon, not by
  importance.
- The KYC green tick has not been captured in a screenshot.
- `OnboardingFlowV2`'s doc comment still says the swipe's Continue ends the onboarding; it now ends from the
  connect frame's MFCentral sheet.
