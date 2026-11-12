import CryptoKit
import SwiftUI
import UIKit
import XCTest
@testable import MutualFundsPrototype

/// Token contract tests: the generated files must agree with the Figma snapshot they were generated from, and
/// the alias chain between tiers must stay intact. The snapshot is read from the repo (the simulator can see the
/// Mac's files), so these fail the moment the snapshot and the code part ways.
final class TokenContractTests: XCTestCase {
    private static let repo = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
    private static let snapshotURL = repo.appendingPathComponent("tools/tokens/figma-variables.json")
    private static let generatedDir = repo.appendingPathComponent("Sources/DesignSystem/Tokens/Generated")

    private var snapshot: [String: Any]!

    override func setUpWithError() throws {
        let data = try Data(contentsOf: Self.snapshotURL)
        snapshot = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func variables(_ collection: String) throws -> [[String: Any]] {
        let collections = try XCTUnwrap(snapshot["collections"] as? [[String: Any]])
        let match = try XCTUnwrap(collections.first { $0["name"] as? String == collection }, "\(collection) not in snapshot")
        return try XCTUnwrap(match["variables"] as? [[String: Any]])
    }

    private var textStyles: [[String: Any]] { snapshot["textStyles"] as? [[String: Any]] ?? [] }

    private func number(_ value: Any?) -> CGFloat? { (value as? NSNumber).map { CGFloat(truncating: $0) } }

    /// 0xRRGGBB and alpha of a SwiftUI colour, as it resolves in light mode
    private func rgba(_ color: Color) -> (hex: String, alpha: CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        let hex = String(format: "#%02X%02X%02X", Int((r * 255).rounded()), Int((g * 255).rounded()), Int((b * 255).rounded()))
        return (hex, a)
    }

    // MARK: Drift

    func testGeneratedFilesWereGeneratedFromThisSnapshot() throws {
        let digest = SHA256.hash(data: try Data(contentsOf: Self.snapshotURL)).map { String(format: "%02x", $0) }.joined()
        let files = try FileManager.default.contentsOfDirectory(at: Self.generatedDir, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "swift" }
        XCTAssertEqual(files.count, 7)
        for file in files {
            let source = try String(contentsOf: file, encoding: .utf8)
            XCTAssertTrue(source.contains("Snapshot sha256: \(digest)"),
                          "\(file.lastPathComponent) was generated from a different snapshot. Run: python3 tools/tokens/generate.py")
        }
    }

    // MARK: Tier 1: every snapshot variable has a constant with the same value

    func testEveryTypographyVariableIsAFoundationConstant() throws {
        let vars = try variables("Typography")
        for v in vars {
            let name = try XCTUnwrap(v["name"] as? String)
            if v["type"] as? String == "STRING" {
                XCTAssertEqual(FoundationTokens.stringsByFigmaName[name], v["value"] as? String, name)
            } else {
                XCTAssertEqual(FoundationTokens.numbersByFigmaName[name], number(v["value"]), name)
            }
        }
        XCTAssertEqual(FoundationTokens.stringsByFigmaName.count + FoundationTokens.numbersByFigmaName.count, vars.count)
    }

    func testEveryContainerVariableIsAConstant() throws {
        let vars = try variables("Container styles")
        var seen = 0
        for v in vars {
            let name = try XCTUnwrap(v["name"] as? String)
            let value = try XCTUnwrap(number(v["value"]))
            if name.hasPrefix("Spacing/") {
                XCTAssertEqual(SpacingPrimitives.byFigmaName[name], value, name)
            } else if name.hasPrefix("Radius/") {
                XCTAssertEqual(RadiusToken.allCases.first { $0.figmaName == name }?.value, value, name)
            } else if name.hasPrefix("Border/") {
                // Figma holds 0.7 as a float32; the constant is the two-place value
                XCTAssertEqual(try XCTUnwrap(BorderTokens.byFigmaName[name]), value, accuracy: 0.005, name)
            } else {
                XCTFail("\(name): a Container styles group the port doesn't know")
            }
            seen += 1
        }
        XCTAssertEqual(SpacingPrimitives.byFigmaName.count + RadiusToken.allCases.count + BorderTokens.byFigmaName.count, seen)
    }

    func testEveryColourPrimitiveIsAConstant() throws {
        let vars = try variables("Colors primitives")
        for v in vars {
            let name = try XCTUnwrap(v["name"] as? String)
            let color = try XCTUnwrap(ColorPrimitives.byFigmaName[name], "\(name) missing from ColorPrimitives")
            let value = try XCTUnwrap(v["value"] as? [String: Any])
            XCTAssertEqual(rgba(color).hex, v["hex"] as? String, name)
            XCTAssertEqual(rgba(color).alpha, try XCTUnwrap(number(value["a"])), accuracy: 0.001, name)
        }
        XCTAssertEqual(ColorPrimitives.byFigmaName.count, vars.count)
    }

    func testEveryShadowStyleIsAPrimitive() throws {
        let styles = try XCTUnwrap(snapshot["effectStyles"] as? [[String: Any]])
        XCTAssertEqual(ShadowPrimitives.all.count, styles.count)
        for style in styles {
            let name = try XCTUnwrap(style["name"] as? String)
            let effect = try XCTUnwrap((style["effects"] as? [[String: Any]])?.first)
            let offset = try XCTUnwrap(effect["offset"] as? [String: Any])
            let p = try XCTUnwrap(ShadowPrimitives.all.first { $0.figmaName == name }, name)
            XCTAssertEqual(String(format: "#%06X", p.color), effect["color"] as? String, name)
            XCTAssertEqual(CGFloat(p.opacity), try XCTUnwrap(number(effect["opacity"])), accuracy: 0.0001, name)
            XCTAssertEqual(p.offsetX, number(offset["x"]), name)
            XCTAssertEqual(p.offsetY, number(offset["y"]), name)
            XCTAssertEqual(p.blur, number(effect["blur"]), name)
            XCTAssertEqual(p.spread, number(effect["spread"]), name)
        }
    }

    // MARK: Tier 2

    func testTypographyScaleMatchesTheTextStyles() throws {
        XCTAssertEqual(TypographyVariant.allCases.count, textStyles.count)
        let sizes = Set(FoundationTokens.numbersByFigmaName.filter { $0.key.hasPrefix("font/size/") }.values)
        let lineHeights = Set(FoundationTokens.numbersByFigmaName.filter { $0.key.hasPrefix("font/lineheight/") }.values)
        for style in textStyles {
            let name = try XCTUnwrap(style["name"] as? String)
            let spec = try XCTUnwrap(TypographyVariant(rawValue: name), "no variant for \(name)").spec
            let lineHeight = try XCTUnwrap(style["lineHeight"] as? [String: Any])
            let letterSpacing = try XCTUnwrap(style["letterSpacing"] as? [String: Any])
            XCTAssertEqual(spec.size, number(style["fontSize"]), "\(name) size")
            XCTAssertEqual(spec.lineHeight, number(lineHeight["value"]), "\(name) line height")
            XCTAssertEqual(spec.family, style["fontFamily"] as? String, "\(name) family")
            XCTAssertEqual(spec.weight, style["fontStyle"] as? String, "\(name) weight")
            XCTAssertTrue(sizes.contains(spec.size), "\(name) size is not a font/size token")
            XCTAssertTrue(lineHeights.contains(spec.lineHeight), "\(name) line height is not a font/lineheight token")
            // Tracking: percent in the style (or 0), applied as points = size × pct / 100
            let percent = letterSpacing["unit"] as? String == "PERCENT" ? try XCTUnwrap(number(letterSpacing["value"])) : 0
            XCTAssertEqual(spec.trackingPercent, percent, "\(name) tracking percent")
            XCTAssertEqual(DSPlatform.trackingPoints(percent: spec.trackingPercent, fontSize: spec.size),
                           spec.size * percent / 100, accuracy: 0.0001, "\(name) tracking points")
        }
    }

    func testEveryColourScaleValueEqualsItsAliasedPrimitive() throws {
        let vars = try variables("Color Semantics")
        for v in vars {
            let name = try XCTUnwrap(v["name"] as? String)
            let alias = try XCTUnwrap(v["value"] as? [String: Any])
            XCTAssertEqual(alias["type"] as? String, "VARIABLE_ALIAS", "\(name) is not an alias")
            let target = try XCTUnwrap(alias["name"] as? String)
            XCTAssertEqual(ColorScale.aliasByFigmaName[name], target, name)
            let semantic = try XCTUnwrap(ColorScale.byFigmaName[name], "\(name) missing from ColorScale")
            let primitive = try XCTUnwrap(ColorPrimitives.byFigmaName[target], "\(target) missing from ColorPrimitives")
            XCTAssertEqual(semantic, primitive, name)
            XCTAssertEqual(rgba(semantic).hex, rgba(primitive).hex, name)
        }
        XCTAssertEqual(ColorScale.byFigmaName.count, vars.count)
        // Every token has exactly one role, so each can be reached from a component
        XCTAssertEqual(SurfaceFill.allCases.count + BorderColor.allCases.count + TextColor.allCases.count, vars.count)
    }

    func testEverySpacingAliasResolvesToAPrimitive() {
        let primitives = Set(SpacingPrimitives.byFigmaName.values).union([0])
        for token in SpacingToken.allCases {
            XCTAssertTrue(primitives.contains(token.value), "\(token) = \(token.value) is not a primitive")
        }
        XCTAssertEqual(SpacingToken.allCases.count, SpacingPrimitives.byFigmaName.count + 1)
    }

    func testShadowScaleMapsThePrimitives() {
        XCTAssertEqual(ShadowToken.allCases.count, ShadowPrimitives.all.count)
        for token in ShadowToken.allCases {
            let spec = token.spec
            XCTAssertEqual(spec.radius, spec.figma.blur / 2)
            XCTAssertEqual(spec.x, spec.figma.offsetX)
            XCTAssertEqual(spec.y, spec.figma.offsetY)
            XCTAssertEqual(rgba(spec.color).alpha, CGFloat(spec.figma.opacity), accuracy: 0.005)
        }
    }

    // MARK: SwiftUI mapping

    func testEveryStyleHasABundledFaceAndWeight() {
        for variant in TypographyVariant.allCases {
            let spec = variant.spec
            XCTAssertNotNil(DSPlatform.fontWeights[spec.weight], "\(variant): no Font.Weight for \(spec.weight)")
            let name = DSPlatform.postScriptName(family: spec.family, weight: spec.weight)
            XCTAssertNotNil(name, "\(variant): no PostScript name for \(spec.family) \(spec.weight)")
            XCTAssertNotNil(name.flatMap { UIFont(name: $0, size: spec.size) }, "\(variant): \(name ?? "?") is not bundled")
        }
    }

    /// One line of any variant is exactly its Figma line height tall; two lines, twice that
    @MainActor func testRenderedLineHeightEqualsTheToken() throws {
        guard #available(iOS 26.0, *) else { throw XCTSkip("Exact line height needs iOS 26 (ADR 005)") }
        for variant in TypographyVariant.allCases {
            let one = UIHostingController(rootView: DsText("8", variant: variant).fixedSize())
            XCTAssertEqual(one.sizeThatFits(in: CGSize(width: 2000, height: 2000)).height, variant.spec.lineHeight,
                           accuracy: 0.5, "\(variant) one line")
            let two = UIHostingController(rootView: DsText("8\n8", variant: variant).fixedSize())
            XCTAssertEqual(two.sizeThatFits(in: CGSize(width: 2000, height: 2000)).height, variant.spec.lineHeight * 2,
                           accuracy: 0.5, "\(variant) two lines")
        }
    }

    func testLineHeightIsNeverBelowFontSize() {
        for variant in TypographyVariant.allCases {
            XCTAssertGreaterThanOrEqual(variant.spec.lineHeight, variant.spec.size, "\(variant)")
        }
    }
}
