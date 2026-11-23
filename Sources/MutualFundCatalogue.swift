import Foundation

/// One scheme from the list of active mutual funds in India: 1,150 Direct plan, Growth option schemes with their
/// classification, returns and NAV. It is the list that search and categorisation in the mutual funds pages are
/// to be built on.
///
/// The list is a copy, in `Resources/mutual_funds.json`, of the owner's sheet "Active mutual funds in India —
/// metadata and returns" (a Claude sheet of the owner's, whose link is not kept in this public repo; sheet "Active funds", read on
/// 2026-11-23 at its revision 4; its NAVs are of 20 and 22 November 2026). To refresh it, read the sheet again
/// and rewrite the file with the same keys.
///
/// The category pages list it, and the second homepage's lists are drawn from it. The first homepage
/// (`-mfHomeV1`) still draws the frames' own funds (`MutualFund`), with the figures the frames give them.
struct ListedFund: Identifiable, Decodable, Hashable {
    /// The AMFI scheme code
    let id: Int
    /// The scheme's name without its plan and option: "HDFC Small Cap Fund"
    let name: String
    /// The name as listed: "HDFC Small Cap Fund - Direct Plan - Growth"
    let listedName: String
    /// "Equity", "Debt", "Hybrid", "Solution oriented" or "Life cycle"
    let assetClass: String
    /// The SEBI category: "Small Cap Fund", "Liquid Fund", "Sectoral/ Thematic" …
    let category: String
    /// "Large cap", "Mid cap", "Small cap", "Flexi cap (any)" …, "Not cap-specific", or "n/a" outside equity
    let capFocus: String
    /// Returns in percent; the three- and five-year ones are a year (CAGR). A fund younger than a period has none.
    let oneYear: Double?
    let threeYear: Double?
    let fiveYear: Double?
    /// A year since the fund began, in percent
    let sinceInception: Double
    /// The fund house, as listed: "HDFC Mutual Fund"
    let amc: String
    /// When the Direct plan began, "yyyy-MM-dd"
    let inception: String
    let nav: Double
    /// The day the NAV is of, "yyyy-MM-dd"
    let navDate: String
    let isin: String?

    private enum CodingKeys: String, CodingKey {
        case id = "s", name = "n", listedName = "f", assetClass = "a", category = "c", capFocus = "m"
        case oneYear = "y1", threeYear = "y3", fiveYear = "y5", sinceInception = "si"
        case amc = "h", inception = "d", nav = "v", navDate = "vd", isin = "i"
    }

    /// The fund house without "Mutual Fund": "HDFC"
    var house: String {
        amc.replacingOccurrences(of: " Mutual Fund", with: "", options: .caseInsensitive)
    }

    /// The fund house's logo, an image set's name, for the houses the app has one for
    var logo: String? {
        MutualFundCatalogue.logos[amc]
    }

    /// The return to show for it: a year over three years, or over the longest shorter stretch it has run
    var headline: Double {
        threeYear ?? oneYear ?? sinceInception
    }

    /// How it is classed, as a list row writes it: "Direct • Equity • Small cap"
    var kindLine: String {
        var words = category.replacingOccurrences(of: " Fund", with: "").split(separator: " ").map(String.init)
        // Sentence case, as the frames write it, with initials left alone ("ELSS", "PSU")
        words = words.enumerated().map { place, word in
            word.count > 1 && word == word.uppercased() && word.contains(where: \.isLetter) ? word : place == 0 ? word.prefix(1).uppercased() + word.dropFirst().lowercased() : word.lowercased()
        }
        return "Direct • \(assetClass) • \(words.joined(separator: " "))"
    }

    /// How it has done beside the other funds of its SEBI category, from 1 to 5. It is made here from the list's
    /// returns, for the row's figure and dots: it is not a rating agency's rating.
    var score: Double {
        MutualFundCatalogue.scores[id] ?? 3
    }

    /// What a search is matched against, in lower case: the name, the house, and how the fund is classed
    fileprivate var haystack: String {
        "\(name) \(house) \(category) \(assetClass) \(capFocus)".lowercased()
    }
}

/// The list of active mutual funds, and the ways into it that search and categorisation need
enum MutualFundCatalogue {
    /// Every fund, in the sheet's order. Empty if the bundled file cannot be read.
    static let funds: [ListedFund] = {
        guard let url = Bundle.main.url(forResource: "mutual_funds", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let funds = try? JSONDecoder().decode([ListedFund].self, from: data) else { return [] }
        return funds
    }()

    /// The asset classes, the one with most funds first
    static let assetClasses: [String] = ranked(funds.map(\.assetClass))

    /// The fund houses, as listed, the one with most funds first
    static let amcs: [String] = ranked(funds.map(\.amc))

    /// The SEBI categories, the one with most funds first; of one asset class, or of all
    static func categories(in assetClass: String? = nil) -> [String] {
        ranked(funds.filter { assetClass == nil || $0.assetClass == assetClass }.map(\.category))
    }

    /// The funds that fit every filter given
    static func funds(assetClass: String? = nil, category: String? = nil, capFocus: String? = nil, amc: String? = nil) -> [ListedFund] {
        funds.filter {
            (assetClass == nil || $0.assetClass == assetClass) && (category == nil || $0.category == category)
                && (capFocus == nil || $0.capFocus == capFocus) && (amc == nil || $0.amc == amc)
        }
    }

    /// The funds a typed search finds, best first. Every word typed must be found, in the name, the house or
    /// how the fund is classed ("hdfc small", "liquid", "flexi parag"). A name that starts with what was typed
    /// comes first, then a name with a word that does, then the rest; within each, the better three-year return.
    static func search(_ text: String, limit: Int = 50) -> [ListedFund] {
        let words = text.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)
        guard !words.isEmpty else { return [] }
        let typed = words.joined(separator: " ")
        let found = funds.compactMap { fund -> (fund: ListedFund, rank: Int)? in
            let haystack = fund.haystack
            guard words.allSatisfy(haystack.contains) else { return nil }
            let name = fund.name.lowercased()
            let rank = name.hasPrefix(typed) ? 0 : words.allSatisfy { word in name.split(separator: " ").contains { $0.hasPrefix(word) } } ? 1 : 2
            return (fund, rank)
        }
        return found
            .sorted { ($0.rank, -($0.fund.threeYear ?? -.infinity), $0.fund.name) < ($1.rank, -($1.fund.threeYear ?? -.infinity), $1.fund.name) }
            .prefix(limit)
            .map(\.fund)
    }

    /// Funds in the order a category page lists them: the better three-year return first, then the funds too
    /// young to have one, by the return they do have
    static func ranked(_ funds: [ListedFund]) -> [ListedFund] {
        funds.sorted {
            let first = ($0.threeYear != nil ? 0 : 1, -$0.headline, $0.name)
            let second = ($1.threeYear != nil ? 0 : 1, -$1.headline, $1.name)
            return first < second
        }
    }

    /// Each fund's score by scheme code: where its return stands among its category's, the lowest 1 and the
    /// highest 5, to one decimal
    static let scores: [Int: Double] = {
        var scores: [Int: Double] = [:]
        for (_, group) in Dictionary(grouping: funds, by: { "\($0.assetClass)/\($0.category)" }) {
            let ordered = group.sorted { $0.headline < $1.headline }
            for (place, fund) in ordered.enumerated() {
                let standing = ordered.count > 1 ? Double(place) / Double(ordered.count - 1) : 0.5
                scores[fund.id] = ((1 + 4 * standing) * 10).rounded() / 10
            }
        }
        return scores
    }()

    /// The fund with that scheme code
    static func fund(code: Int) -> ListedFund? {
        funds.first { $0.id == code }
    }

    /// The image sets the app has for fund houses, by the house's listed name: 32 of the list's 54
    static let logos: [String: String] = [
        "360 ONE Mutual Fund": "MFHomeThreeSixtyOne", "Aditya Birla Sun Life Mutual Fund": "MFHomeAdityaBirla",
        "Axis Mutual Fund": "MFHomeAxis", "Bajaj Finserv Mutual Fund": "MFHomeBajaj", "Bandhan Mutual Fund": "MFHomeBandhan",
        "Baroda BNP Paribas Mutual Fund": "MFHomeBaroda", "Canara Robeco Mutual Fund": "MFHomeCanara", "DSP Mutual Fund": "MFHomeDSP",
        "Edelweiss Mutual Fund": "MFHomeEdelweiss", "Franklin Templeton Mutual Fund": "MFHomeFranklin", "Groww Mutual Fund": "MFHomeGroww",
        "HDFC Mutual Fund": "MFHomeHDFC", "HSBC Mutual Fund": "MFHomeHSBC", "ICICI Prudential Mutual Fund": "MFHomeICICI",
        "Invesco Mutual Fund": "MFHomeInvesco", "JM Financial Mutual Fund": "MFHomeJM", "Kotak Mahindra Mutual Fund": "MFHomeKotak",
        "LIC Mutual Fund": "MFHomeLIC", "Mahindra Manulife Mutual Fund": "MFHomeMahindra", "Mirae Asset Mutual Fund": "MFHomeMirae",
        "Motilal Oswal Mutual Fund": "MFHomeMotilal", "Navi Mutual Fund": "MFHomeNavi", "Nippon India Mutual Fund": "MFHomeNippon",
        "PGIM India Mutual Fund": "MFHomePGIM", "PPFAS Mutual Fund": "MFHomePPFAS", "SBI Mutual Fund": "MFHomeSBI",
        "Sundaram Mutual Fund": "MFHomeSundaram", "Tata Mutual Fund": "MFHomeTata", "UTI Mutual Fund": "MFHomeUTI",
        "Union Mutual Fund": "MFHomeUnion", "WhiteOak Capital Mutual Fund": "MFHomeWhiteOak", "quant Mutual Fund": "MFHomeQuant",
    ]

    /// The values, each once, the commonest first; ties in A to Z order
    private static func ranked(_ values: [String]) -> [String] {
        Dictionary(grouping: values, by: { $0 }).sorted { ($1.value.count, $0.key) < ($0.value.count, $1.key) }.map(\.key)
    }
}
