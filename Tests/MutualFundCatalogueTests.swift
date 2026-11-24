import UIKit
import XCTest
@testable import MutualFundsPrototype

/// The bundled list of active mutual funds reads, is whole, and can be searched and sorted into its classes.
final class MutualFundCatalogueTests: XCTestCase {
    func testTheListIsWhole() {
        XCTAssertEqual(MutualFundCatalogue.funds.count, 1150)
        XCTAssertEqual(Set(MutualFundCatalogue.funds.map(\.id)).count, 1150, "scheme codes are unique")
        XCTAssertEqual(MutualFundCatalogue.assetClasses, ["Equity", "Debt", "Hybrid", "Solution oriented", "Life cycle"])
        XCTAssertEqual(MutualFundCatalogue.amcs.count, 54)
        XCTAssertEqual(MutualFundCatalogue.categories().count, 43, "44 class-and-category pairs; \"Sectoral Fund\" is in two classes")
    }

    func testNamesDropTheirPlanAndOption() {
        for fund in MutualFundCatalogue.funds {
            XCTAssertFalse(fund.name.localizedCaseInsensitiveContains("direct"), fund.name)
            XCTAssertFalse(fund.name.isEmpty)
        }
        XCTAssertEqual(MutualFundCatalogue.fund(code: 119835)?.name, "SBI Contra Fund")
        XCTAssertEqual(MutualFundCatalogue.fund(code: 119835)?.house, "SBI")
    }

    func testFilters() {
        XCTAssertEqual(MutualFundCatalogue.funds(assetClass: "Equity").count, 576)
        XCTAssertEqual(MutualFundCatalogue.funds(category: "Small Cap Fund").count, 37)
        XCTAssertEqual(MutualFundCatalogue.funds(assetClass: "Debt", category: "Liquid Fund").count, 40)
        XCTAssertEqual(MutualFundCatalogue.funds(amc: "ICICI Prudential Mutual Fund").count, 64)
        XCTAssertEqual(MutualFundCatalogue.categories(in: "Hybrid").first, "Arbitrage Fund")
    }

    func testSearch() {
        XCTAssertEqual(MutualFundCatalogue.search("hdfc small cap").first?.name, "HDFC Small Cap Fund")
        XCTAssertEqual(MutualFundCatalogue.search("parag flexi").first?.name, "Parag Parikh Flexi Cap Fund")
        XCTAssertTrue(MutualFundCatalogue.search("liquid").allSatisfy { $0.category.contains("Liquid") || $0.name.localizedCaseInsensitiveContains("liquid") })
        XCTAssertTrue(MutualFundCatalogue.search("").isEmpty)
        XCTAssertTrue(MutualFundCatalogue.search("zzzz").isEmpty)
        XCTAssertLessThanOrEqual(MutualFundCatalogue.search("fund", limit: 10).count, 10)
    }

    func testEveryCategoryHasFundsAndADrawing() {
        let categories: [FundCategory] = [.equity, .debt, .hybrid, .smallCap, .midCap, .largeCap, .liquid, .banking, .technology, .realEstate, .performingSmallCap,
                                          .infrastructure, .pharma, .fmcg, .energy, .automobile, .commodities]
        for category in categories {
            XCTAssertFalse(category.funds.isEmpty, "\(category.title) has no funds")
            XCTAssertNotNil(UIImage(named: category.art), "\(category.art) is not an image set")
            // The page's line and its pill's question are the category's own, not its count of funds
            XCTAssertNotEqual(category.invests, category.noun, "\(category.id) has no line of its own")
            XCTAssertFalse(category.asks.isEmpty)
        }
        XCTAssertEqual(FundCategory.smallCap.funds.count, 37)
        XCTAssertEqual(FundCategory.performingSmallCap.invests, "smaller companies")
        XCTAssertEqual(FundCategory.performingSmallCap.asks, "small cap")
        for image in ["MFCatTop", "MFCatAsk", "MFExploreChevronDown", "MFExploreGrid"] {
            XCTAssertNotNil(UIImage(named: image), "\(image) is not an image set")
        }
        XCTAssertEqual(FundCategory.banking.funds.count, 27, "funds of Bank of India are not banking funds for their house's name")
        // The better three-year return comes first, and funds too young to have one come last
        let ranked = FundCategory.equity.funds
        let returns = ranked.compactMap(\.threeYear)
        XCTAssertEqual(returns, returns.sorted(by: >))
        XCTAssertNil(ranked.last?.threeYear)
        for kind in ["Equity", "Banking", "Small cap", "Debt", "Real estate", "Mid cap", "Liquid", "Large cap", "Technology", "Equity funds", "Hybrid funds"] {
            XCTAssertNotNil(FundCategory.named(kind), "\(kind) opens no category")
        }
    }

    func testScoresAndRows() {
        XCTAssertTrue(MutualFundCatalogue.funds.allSatisfy { (1...5).contains($0.score) })
        XCTAssertEqual(MutualFundCatalogue.fund(code: 119835)?.kindLine, "Direct • Equity • Contra")
        XCTAssertEqual(MutualFundCatalogue.funds(category: "ELSS").first?.kindLine, "Direct • Equity • ELSS")
        let page = MutualFund.listed(MutualFundCatalogue.fund(code: 119835)!)
        XCTAssertEqual(page.name, "SBI Contra Fund")
        XCTAssertEqual(page.facts.first?.value, "Rs427.90")
        XCTAssertEqual(page.series.count, 141)
    }

    func testTheHomepageListsRealFunds() {
        let lists = [MutualFundsHomeV2View.ranked, MutualFundsHomeV2View.midCaps, MutualFundsHomeV2View.infrastructure, MutualFundsHomeV2View.rising]
        for list in lists {
            XCTAssertEqual(list.count, 3)
            XCTAssertTrue(list.allSatisfy { MutualFundCatalogue.fund(code: $0.id) != nil })
        }
        XCTAssertEqual(Set(lists.joined().map(\.id)).count, 12, "no fund is in two of the homepage's short lists")
        // "All mutual funds" is the top of the small caps' page
        XCTAssertEqual(MutualFundsHomeV2View.all, Array(FundCategory.smallCap.funds.prefix(8)))
        XCTAssertEqual(MutualFundsHomeV2View.ranked, Array(FundCategory.smallCap.funds.prefix(3)), "the ranked card is the top of the page it opens")
        XCTAssertTrue(MutualFundsHomeV2View.midCaps.allSatisfy { $0.category == "Mid Cap Fund" })
        XCTAssertTrue(MutualFundsHomeV2View.infrastructure.allSatisfy { $0.name.localizedCaseInsensitiveContains("infra") })
        XCTAssertEqual(FundCategory.infrastructure.funds.count, 19)
    }

    func testAFundsPage() {
        // The frame's chart runs from about Rs37.2 to Rs41.7 and is marked at 37, 39, (41,) 43
        let drawn = MutualFund.scale(low: 37.24, high: 41.67)
        XCTAssertEqual(drawn.base, 37)
        XCTAssertEqual(drawn.step, 2)
        XCTAssertEqual(drawn.decimals, 0)
        let wide = MutualFund.scale(low: 301, high: 537.11)
        XCTAssertEqual(wide.base, 300)
        XCTAssertEqual(wide.step, 100)
        let fine = MutualFund.scale(low: 10.412, high: 10.451)
        XCTAssertLessThanOrEqual(fine.base, 10.412)
        XCTAssertGreaterThan(fine.decimals, 0)
        // The drawn fund is as the frame writes it
        XCTAssertEqual(MutualFund.kotak.rating, 4.7)
        XCTAssertEqual(MutualFund.kotak.charges.map(\.value), ["0.51%", "None", "0.005%", "0.005%"])
        XCTAssertEqual(MutualFund.kotak.span, "3Y")
        // Any other fund's charges take their expense ratio from Basics, and every sector has a drawing
        for listed in MutualFundCatalogue.funds.prefix(200) {
            let page = MutualFund.listed(listed)
            XCTAssertEqual(page.charges.first?.value, page.fact("Expense ratio"))
            XCTAssertEqual(page.sectors.count, 5)
            // The pop-up of holdings lists all twenty, each with a logo and a sector, the largest first
            XCTAssertEqual(page.holdings.count, 20)
            XCTAssertTrue(page.holdings.allSatisfy { !$0.sector.isEmpty && UIImage(named: $0.logo) != nil })
            XCTAssertEqual(page.holdings.map(\.share), page.holdings.map(\.share).sorted(by: >))
            for sector in page.sectors {
                XCTAssertNotNil(MutualFund.sectorArt[sector.name].flatMap { UIImage(named: $0) }, "\(sector.name) has no drawing")
            }
            XCTAssertEqual(page.rating, listed.score)
            XCTAssertEqual(page.series.count, 141)
            XCTAssertEqual(page.span, listed.threeYear != nil ? "3Y" : listed.oneYear != nil ? "1Y" : "All")
        }
        for image in ["MFDetailBack", "MFDetailUp", "MFDetailExpand", "MFDetailAvatar"] {
            XCTAssertNotNil(UIImage(named: image), "\(image) is not an image set")
        }
    }

    func testAFundsCardsAreWidgets() {
        // A card on a fund's page can be held and sent to the advisor: it knows its fund, its title and its questions
        let listed = MutualFundCatalogue.fund(code: 119835)!
        let sections: [FundContext.FundSection] = [.growth, .basics, .holdings, .sectors, .charges, .managers]
        for section in sections {
            let card = FundContext.fundCard(listed.name, section)
            XCTAssertEqual(card.fund?.name, "SBI Contra Fund")
            XCTAssertEqual(card.title, section.title)
            XCTAssertEqual(card.subtitle, "SBI Contra Fund")
            XCTAssertEqual(card.questions.count, 2)
            XCTAssertNotNil(UIImage(named: card.icon), "\(card.icon) is not an image set")
        }
        XCTAssertEqual(FundContext.fundCard(MutualFund.kotak.name, .holdings).fund?.house, "Kotak Mahindra")
        XCTAssertNil(FundContext.fundCard("No such fund", .holdings).fund)
        // The sectors' pop-up names the holdings in each sector
        XCTAssertEqual(MutualFund.kotak.companies(in: "Banking"), "HDFC Bank, ICICI Bank, SBI")
        XCTAssertEqual(MutualFund.kotak.companies(in: "Nowhere"), "Equity")
        // The bar's pill writes the fund's name without the house it has just written over it
        XCTAssertEqual(MutualFund.kotak.shortName, "Cap - Direct Growth")
        XCTAssertEqual(MutualFund.listed(listed).shortName, "Contra Fund")
        XCTAssertEqual(MutualFund.listed(MutualFundCatalogue.search("parag flexi").first!).shortName, "Parag Parikh Flexi Cap Fund")
    }

    func testTheExplorePagesKindsAndSearch() {
        // The kinds the page's chips and search offer open pages with funds on them
        for kind in MutualFundsHomeV2View.kinds {
            XCTAssertNotNil(FundCategory.named(kind.title), "\(kind.title) opens no category")
            XCTAssertNotNil(UIImage(named: kind.orb))
        }
        // A category's page narrows its funds by every word typed, in the name or the house
        let small = FundCategory.smallCap.funds
        XCTAssertEqual(small.filter { $0.matches("") }.count, small.count)
        XCTAssertEqual(small.filter { $0.matches("hdfc") }.map(\.name), ["HDFC Small Cap Fund"])
        XCTAssertEqual(small.filter { $0.matches("  SMALL  bandhan ") }.map(\.name), ["Bandhan Small Cap Fund"])
        XCTAssertTrue(small.filter { $0.matches("zzzz") }.isEmpty)
    }

    func testEveryLogoIsInTheApp() {
        for (amc, logo) in MutualFundCatalogue.logos {
            XCTAssertTrue(MutualFundCatalogue.amcs.contains(amc), "\(amc) is not a fund house in the list")
            XCTAssertNotNil(UIImage(named: logo), "\(logo) is not an image set")
        }
        // Every house in the list has one, and so do the frame's two that the list has no fund from
        for amc in MutualFundCatalogue.amcs {
            XCTAssertNotNil(MutualFundCatalogue.logos[amc], "\(amc) has no logo")
        }
        for extra in ["MFHomeAngelOne", "MFHomeILFS"] {
            XCTAssertNotNil(UIImage(named: extra), "\(extra) is not an image set")
        }
    }

    /// A list's returns over the stretch picked: the catalogue's own where it has them, the headline at three
    /// years, and the same sample figure every time for the two stretches it has none for
    func testReturnsOverAPeriod() throws {
        let fund = try XCTUnwrap(MutualFundCatalogue.funds.first { $0.threeYear != nil && $0.fiveYear != nil && $0.oneYear != nil })
        XCTAssertEqual(fund.returned(over: .threeYears), fund.headline)
        XCTAssertEqual(fund.returned(over: .oneYear), fund.oneYear)
        XCTAssertEqual(fund.returned(over: .fiveYears), fund.fiveYear)
        XCTAssertEqual(fund.returned(over: .all), fund.sinceInception)
        XCTAssertEqual(fund.returned(over: .oneMonth), fund.returned(over: .oneMonth))
        XCTAssertNotNil(fund.returned(over: .sixMonths))
        let young = try XCTUnwrap(MutualFundCatalogue.funds.first { $0.fiveYear == nil })
        XCTAssertNil(young.returned(over: .fiveYears))
        XCTAssertEqual(FundPeriod.allCases.map(\.rawValue), ["1M", "6M", "1Y", "3Y", "5Y", "ALL"])
    }
}
