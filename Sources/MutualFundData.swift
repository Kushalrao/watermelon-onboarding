import SwiftUI

/// A mutual fund as its page shows it (`MutualFundDetailView`): what it is called, what it has returned, how it
/// has grown, the facts in Basics, what it holds, and who runs it.
///
/// One fund is drawn in Figma, "Kotak Mahindra Cap - Direct Growth" (101:15002), and it is here as drawn
/// (`kotak`). The other funds have no page in Figma, so their content is made here as a sample: it is not the
/// funds' real data. Each one's figures come from its name, so they are the same on every run. Their holdings
/// are the twenty companies the frames have logos for, in an order and at weights of the fund's own, and their
/// sectors are the five the frame has drawings for.
struct MutualFund: Identifiable {
    /// What kind of fund it is: decides its sectors and how bumpy its growth is
    enum Kind {
        case small, mid, large, flexi, contra, sectoral, hybrid, debt
    }

    /// A company the fund holds
    struct Holding: Identifiable {
        let id: Int
        /// As written in the list: "Eternal Ltd"
        let name: String
        /// A shorter name, for where there is little room: "Eternal"
        let short: String
        /// The company's logo, an image set's name
        let logo: String
        /// The sector the company is in, as the list of all holdings writes it: "Consumer Discretionary"
        let sector: String
        /// Its share of the fund, in percent
        let share: Double
    }

    struct Manager {
        /// The portrait, an image set's name
        let portrait: String
        let name: String
        /// "July 2023 - Active"
        let since: String
    }

    /// How the fund house is shown over the fund's name
    enum Mark {
        /// The house's square logo on its tile (101:15335)
        case tile(String)
    }

    var id: String { name }
    let name: String
    /// The name as the page's title sets it, with the frame's line breaks where it has them
    let title: String
    let house: String
    let mark: Mark
    let kind: Kind
    /// What it has returned a year over three years, in percent
    let returned: Double
    /// The rows of Basics, as written
    let facts: [(label: String, value: String)]
    /// Twenty holdings, the largest first
    let holdings: [Holding]
    let sectors: [(name: String, share: Double)]
    let managers: [Manager]
    /// What 100 put in three years ago has been worth since, at even steps up to now
    let series: [Double]
    /// What `returned` is over, as the page's tab writes it: "3Y", or less for a fund younger than that
    var span = "3Y"
    /// The Decade rating, where it is not the one in Basics. The frame writes three for its one fund: 4.7 under
    /// the name, 4.9 at the foot of the page and 5 in Basics.
    var ratingAsDrawn: Double? = nil
    /// The rows of Fund charges, where the frame writes them for the fund
    var chargesAsDrawn: [(label: String, value: String)]? = nil

    /// What a row of Basics says: "0.51%"
    func fact(_ label: String) -> String {
        facts.first { $0.label == label }?.value ?? ""
    }

    /// The fund's Decade rating out of five, which the page writes under the name and again at its foot
    var rating: Double {
        ratingAsDrawn ?? Double(fact("Rating")) ?? 4
    }

    /// 101:15195: the rows of Fund charges, with the frame's wording ("Exist load"). The expense ratio is the
    /// one in Basics; the rest are the frame's own figures, the same for every fund.
    var charges: [(label: String, value: String)] {
        chargesAsDrawn ?? [("Expense ratio", fact("Expense ratio")), ("Exist load", "None"), ("Stamp duty on investment", "0.005%"), ("Tax implication", "0.005%")]
    }

    /// The fund's NAV now, in rupees, read from its Basics row ("Rs247.02")
    var nav: Double {
        Double(fact("Nav").filter { $0.isNumber || $0 == "." }) ?? 100
    }

    /// The same fund with another return, and the growth that goes with it: a fund is opened with the figure
    /// that was tapped
    func returning(_ returned: Double) -> MutualFund {
        guard returned != self.returned else { return self }
        var fund = MutualFund(name: name, title: title, house: house, mark: mark, kind: kind, returned: returned, facts: facts,
                              holdings: holdings, sectors: sectors, managers: managers, series: Self.growth(name: name, returned: returned, kind: kind))
        fund.span = span
        fund.ratingAsDrawn = ratingAsDrawn
        fund.chargesAsDrawn = chargesAsDrawn
        return fund
    }

    /// The fund of that name, or the drawn one if there is none. The first homepage draws one name under two
    /// houses' logos, so the logo decides between them where it can.
    static func named(_ name: String, logo: String? = nil) -> MutualFund {
        all.first { $0.name == name && $0.logo == logo } ?? all.first { $0.name == name } ?? kotak
    }

    /// The page for a fund of that name: one of the drawn or sample funds, or one from the list of active funds
    static func page(named name: String) -> MutualFund? {
        all.first { $0.name == name } ?? MutualFundCatalogue.funds.first { $0.name == name }.map(listed)
    }

    /// The name without the house at its start, as the page's bar writes it under the house's name once the
    /// page has scrolled (105:19744, "Asset allocation fund"); the whole name where it does not start with it
    var shortName: String {
        guard name.lowercased().hasPrefix(house.lowercased() + " ") else { return name }
        let rest = name.dropFirst(house.count).trimmingCharacters(in: .whitespaces)
        return rest.isEmpty ? name : rest.prefix(1).uppercased() + rest.dropFirst()
    }

    /// The house's square logo
    var logo: String? {
        switch mark {
        case .tile(let image): image
        }
    }

    // MARK: The drawn fund

    /// The companies the frames have logos for (101:15099 …), in the order they are drawn, each with its sector
    static let companies: [(name: String, short: String, logo: String, sector: String)] = [
        ("Eternal Ltd", "Eternal", "MFHoldEternal", "Consumer Discretionary"),
        ("Eicher Motors Ltd", "Eicher Motors", "MFHoldEicher", "Automobile"),
        ("Mahindra & Mahindra", "M&M", "MFHoldMahindra", "Automobile"),
        ("HDFC Bank Ltd", "HDFC Bank", "MFHoldHDFCBank", "Financial"),
        ("Bharti Airtel Ltd", "Airtel", "MFHoldAirtel", "Telecom"),
        ("ICICI Bank Ltd", "ICICI Bank", "MFHoldICICIBank", "Financial"),
        ("Reliance Industries Ltd", "Reliance", "MFHoldReliance", "Energy"),
        ("Infosys Ltd", "Infosys", "MFHoldInfosys", "Technology"),
        ("Tata Motors Ltd", "Tata Motors", "MFHoldTataMotors", "Automobile"),
        ("Larsen & Toubro Ltd", "L&T", "MFHoldLT", "Industrials"),
        ("State Bank of India", "SBI", "MFHoldSBI", "Financial"),
        ("Axis Bank Ltd", "Axis Bank", "MFHoldAxisBank", "Financial"),
        ("Tata Consultancy Services Ltd", "TCS", "MFHoldTCS", "Technology"),
        ("Bajaj Finance Ltd", "Bajaj Finance", "MFHoldBajajFinance", "Financial"),
        ("Maruti Suzuki India Ltd", "Maruti", "MFHoldMaruti", "Automobile"),
        ("Sun Pharmaceutical Industries Ltd", "Sun Pharma", "MFHoldSunPharma", "Healthcare"),
        ("ITC Ltd", "ITC", "MFHoldITC", "Consumer Staples"),
        ("Titan Company Ltd", "Titan", "MFHoldTitan", "Consumer Discretionary"),
        ("NTPC Ltd", "NTPC", "MFHoldNTPC", "Utilities"),
        ("UltraTech Cement Ltd", "UltraTech", "MFHoldUltraTech", "Materials"),
    ]

    /// The shares the frame writes beside them
    private static let drawnShares: [Double] = [
        6.42, 5.18, 4.76, 4.31, 3.95, 3.62, 3.38, 3.11, 2.87, 2.64, 2.42, 2.21, 2.05, 1.88, 1.73, 1.59, 1.46, 1.34, 1.22, 1.11,
    ]

    /// The five sectors the frame has drawings for (101:15138 …), with each one's image set
    static let sectorArt: [String: String] = [
        "Banking": "MFSectorBanking", "Pharma": "MFSectorPharma", "Automobile": "MFSectorAutomobile",
        "Commodities": "MFSectorCommodities", "Energy": "MFSectorEnergy",
    ]

    /// The sectors a holding's company can be in (`Holding.sector`) that each of the five drawn sectors takes in
    private static let sectorKinds: [String: Set<String>] = [
        "Banking": ["Financial"], "Pharma": ["Healthcare"], "Automobile": ["Automobile"],
        "Commodities": ["Materials", "Consumer Staples"], "Energy": ["Energy", "Utilities"],
    ]

    /// The largest of the fund's holdings that are in a sector, by their short names: "HDFC Bank, ICICI Bank, SBI"
    func companies(in sector: String) -> String {
        let names = holdings.filter { Self.sectorKinds[sector]?.contains($0.sector) == true }.prefix(3).map(\.short)
        return names.isEmpty ? "Equity" : names.joined(separator: ", ")
    }

    /// Figma 101:15002, as drawn. The frame writes its holdings' shares again beside its sectors, and they are
    /// kept so. Its curve is not the frame's, which is drawn at Rs37 to Rs43 over a NAV of Rs247.02: it is made
    /// for the fund's return and NAV, as the other funds' are.
    static let kotak: MutualFund = {
        let name = "Kotak Mahindra Cap - Direct Growth"
        var fund = MutualFund(
            name: name,
            title: name,
            house: "Kotak Mahindra",
            mark: .tile("MFHomeKotak"),
            kind: .large,
            returned: 18.7,
            facts: [("Nav", "Rs247.02"), ("Expense ratio", "0.02%"), ("Min SIP", "Rs500"), ("Rating", "5"), ("Fund size", "Rs500")],
            holdings: companies.enumerated().map { Holding(id: $0.offset, name: $0.element.name, short: $0.element.short, logo: $0.element.logo, sector: $0.element.sector, share: drawnShares[$0.offset]) },
            sectors: [("Banking", 6.42), ("Pharma", 5.18), ("Automobile", 4.76), ("Commodities", 4.31), ("Energy", 3.95)],
            managers: [Manager(portrait: "MFDetailManager1", name: "Priya Ranjan", since: "July 2023 - Active"),
                       Manager(portrait: "MFDetailManager2", name: "Priya Ranjan", since: "July 2023 - Active")],
            series: growth(name: name, returned: 18.7, kind: .large)
        )
        fund.ratingAsDrawn = 4.7
        fund.chargesAsDrawn = [("Expense ratio", "0.51%"), ("Exist load", "None"), ("Stamp duty on investment", "0.005%"), ("Tax implication", "0.005%")]
        return fund
    }()

    // MARK: The homepage's funds (sample content)

    static let all: [MutualFund] = [
        kotak,
        sample("HDFC Small Cap Fund", house: "HDFC", logo: "MFHomeHDFC", .small, returned: 27.6, nav: "Rs142.38", expense: "0.68%", sip: "Rs100", rating: "4", size: "Rs36,294 Cr",
               managers: [("Arjun Mehta", "June 2014 - Active"), ("Kavya Iyer", "May 2022 - Active")]),
        sample("Quant Small Cap Fund", house: "Quant", logo: "MFHomeQuant", .small, returned: 24.6, nav: "Rs268.71", expense: "0.64%", sip: "Rs1,000", rating: "5", size: "Rs29,629 Cr",
               managers: [("Rohan Kulkarni", "February 2020 - Active"), ("Neha Bansal", "November 2023 - Active")]),
        sample("Tata Small Cap Fund", house: "Tata", logo: "MFHomeTata", .small, returned: 23.2, nav: "Rs41.92", expense: "0.34%", sip: "Rs100", rating: "4", size: "Rs11,164 Cr",
               managers: [("Vikram Desai", "November 2018 - Active"), ("Ananya Rao", "October 2023 - Active")]),
        sample("Nippon India Small Cap", house: "Nippon India", logo: "MFHomeNippon", .small, returned: 22.4, nav: "Rs178.55", expense: "0.63%", sip: "Rs100", rating: "4", size: "Rs66,602 Cr",
               managers: [("Sameer Nair", "January 2017 - Active"), ("Ishita Sen", "February 2023 - Active")]),
        sample("SBI Small Cap Fund", house: "SBI", logo: "MFHomeSBI", .small, returned: 20.9, nav: "Rs189.04", expense: "0.72%", sip: "Rs500", rating: "3", size: "Rs35,563 Cr",
               managers: [("Rahul Menon", "November 2013 - Active"), ("Divya Kapoor", "March 2024 - Active")]),
        sample("Bandhan Small Cap Fund", house: "Bandhan", logo: "MFHomeBandhan", .small, returned: 20.3, nav: "Rs48.26", expense: "0.39%", sip: "Rs100", rating: "5", size: "Rs14,062 Cr",
               managers: [("Manish Gupta", "January 2023 - Active"), ("Sneha Pillai", "December 2023 - Active")]),
        sample("Axis Small Cap Fund", house: "Axis", logo: "MFHomeAxis", .small, returned: 19.6, nav: "Rs118.63", expense: "0.56%", sip: "Rs100", rating: "4", size: "Rs26,143 Cr",
               managers: [("Karthik Reddy", "November 2016 - Active"), ("Pooja Shah", "August 2023 - Active")]),
        sample("Kotak Small Cap Fund", house: "Kotak", logo: "MFHomeKotak", .small, returned: 18.8, nav: "Rs296.15", expense: "0.52%", sip: "Rs100", rating: "3", size: "Rs17,508 Cr",
               managers: [("Harsh Agarwal", "October 2023 - Active"), ("Meera Joshi", "January 2024 - Active")]),
        sample("HDFC Mid Cap Fund", house: "HDFC", logo: "MFHomeHDFC", .mid, returned: 26.1, nav: "Rs203.47", expense: "0.71%", sip: "Rs100", rating: "5", size: "Rs83,105 Cr",
               managers: [("Siddharth Bose", "June 2007 - Active"), ("Tanvi Malhotra", "June 2023 - Active")]),
        sample("Parag Parikh Flexi Cap", house: "PPFAS", logo: "MFHomePPFAS", .flexi, returned: 21.4, nav: "Rs89.36", expense: "0.63%", sip: "Rs1,000", rating: "5", size: "Rs1,03,868 Cr",
               managers: [("Rajesh Varma", "May 2013 - Active"), ("Aditi Chawla", "January 2016 - Active")]),
        sample("SBI Contra Fund", house: "SBI", logo: "MFHomeSBI", .contra, returned: 22.9, nav: "Rs412.80", expense: "0.66%", sip: "Rs500", rating: "5", size: "Rs46,654 Cr",
               managers: [("Dev Khanna", "May 2018 - Active"), ("Ritu Saxena", "December 2023 - Active")]),
        sample("ICICI Pru Large Cap", house: "ICICI Prudential", logo: "MFHomeICICI", .large, returned: 18.7, nav: "Rs118.05", expense: "0.86%", sip: "Rs100", rating: "5", size: "Rs71,840 Cr",
               managers: [("Anil Thomas", "September 2018 - Active"), ("Shreya Ghosh", "July 2022 - Active")]),
        sample("Motilal Oswal Midcap", house: "Motilal Oswal", logo: "MFHomeMotilal", .mid, returned: 27.3, nav: "Rs112.94", expense: "0.70%", sip: "Rs500", rating: "3.1", size: "Rs33,053 Cr",
               managers: [("Nikhil Jain", "July 2020 - Active"), ("Priyanka Dutta", "October 2024 - Active")]),
        // The funds the second homepage draws (47:6749), with the ratings it gives them
        sample("Nippon Pru Large Cap", house: "Nippon India", logo: "MFHomeNippon", .large, returned: 18.7, nav: "Rs96.41", expense: "0.74%", sip: "Rs100", rating: "3.1", size: "Rs41,750 Cr",
               managers: [("Sameer Nair", "August 2019 - Active"), ("Ishita Sen", "February 2023 - Active")]),
        sample("Nippon Pru Large Cap", house: "Aditya Birla", logo: "MFHomeAdityaBirla", .large, returned: 18.7, nav: "Rs538.20", expense: "0.98%", sip: "Rs100", rating: "2.9", size: "Rs30,235 Cr",
               managers: [("Gaurav Sethi", "November 2021 - Active"), ("Lata Krishnan", "April 2024 - Active")]),
        sample("Axis Pru Large Cap", house: "Axis", logo: "MFHomeAxis", .large, returned: 18.7, nav: "Rs67.83", expense: "0.69%", sip: "Rs100", rating: "4.5", size: "Rs33,412 Cr",
               managers: [("Karthik Reddy", "November 2016 - Active"), ("Pooja Shah", "August 2023 - Active")]),
        sample("Edelweiss Mid Cap", house: "Edelweiss", logo: "MFHomeEdelweiss", .mid, returned: 25.4, nav: "Rs108.17", expense: "0.39%", sip: "Rs100", rating: "3.1", size: "Rs10,028 Cr",
               managers: [("Tarun Bhatia", "October 2021 - Active"), ("Mira Fernandes", "March 2024 - Active")]),
        sample("Invesco India Mid Cap", house: "Invesco", logo: "MFHomeInvesco", .mid, returned: 24.2, nav: "Rs186.55", expense: "0.55%", sip: "Rs500", rating: "3.1", size: "Rs7,406 Cr",
               managers: [("Aditya Kohli", "September 2020 - Active"), ("Sana Qureshi", "November 2023 - Active")]),
        sample("ICICI Pru Infrastructure", house: "ICICI Prudential", logo: "MFHomeICICI", .sectoral, returned: 31.2, nav: "Rs209.76", expense: "1.14%", sip: "Rs100", rating: "4.5", size: "Rs7,920 Cr",
               managers: [("Anil Thomas", "June 2017 - Active"), ("Shreya Ghosh", "May 2023 - Active")]),
        sample("Bandhan Infrastructure", house: "Bandhan", logo: "MFHomeBandhan", .sectoral, returned: 29.6, nav: "Rs58.34", expense: "0.84%", sip: "Rs100", rating: "4.5", size: "Rs1,676 Cr",
               managers: [("Manish Gupta", "January 2024 - Active"), ("Sneha Pillai", "June 2024 - Active")]),
        sample("Quant Infrastructure", house: "Quant", logo: "MFHomeQuant", .sectoral, returned: 27.8, nav: "Rs41.09", expense: "0.71%", sip: "Rs1,000", rating: "4.5", size: "Rs3,304 Cr",
               managers: [("Rohan Kulkarni", "February 2022 - Active"), ("Neha Bansal", "November 2023 - Active")]),
        sample("Axis Midcap Fund", house: "Axis", logo: "MFHomeAxis", .mid, returned: 22.8, nav: "Rs127.46", expense: "0.54%", sip: "Rs100", rating: "4", size: "Rs31,147 Cr",
               managers: [("Karthik Reddy", "November 2016 - Active"), ("Pooja Shah", "August 2023 - Active")]),
    ]

    private static func sample(_ name: String, house: String, logo: String, _ kind: Kind, returned: Double, nav: String, expense: String,
                               sip: String, rating: String, size: String, managers: [(String, String)]) -> MutualFund {
        var dice = Dice(seed: name)
        // The twenty companies in an order of the fund's own, at the frame's weights scaled to the fund's largest
        let order = dice.shuffled(Array(companies.indices))
        let largest = dice.between(3.4, 7.2)
        let holdings = order.enumerated().map { place, company in
            Holding(id: place, name: companies[company].name, short: companies[company].short, logo: companies[company].logo,
                    sector: companies[company].sector, share: (drawnShares[place] / drawnShares[0] * largest * 100).rounded() / 100)
        }
        let sectors = sectors(for: kind).map { ($0.name, (($0.share + dice.between(-0.8, 0.8)) * 100).rounded() / 100) }.sorted { $0.1 > $1.1 }
        return MutualFund(
            name: name, title: name, house: house, mark: .tile(logo), kind: kind, returned: returned,
            facts: [("Nav", nav), ("Expense ratio", expense), ("Min SIP", sip), ("Rating", rating), ("Fund size", size)],
            holdings: holdings,
            sectors: sectors.map { (name: $0.0, share: $0.1) },
            managers: managers.enumerated().map { Manager(portrait: $0.offset == 0 ? "MFDetailManager1" : "MFDetailManager2", name: $0.element.0, since: $0.element.1) },
            series: growth(name: name, returned: returned, kind: kind)
        )
    }

    /// A page for a fund from the list of active funds (`ListedFund`). Its name, house, NAV and return are the
    /// list's. The list has nothing on a fund's costs, size, holdings, sectors or managers, so those are a sample
    /// made from its name, as the homepage funds' are; its rating is its score within its category.
    static func listed(_ fund: ListedFund) -> MutualFund {
        let kind: Kind = switch (fund.assetClass, fund.capFocus) {
        case ("Debt", _): .debt
        case ("Equity", "Small cap"): .small
        case ("Equity", "Mid cap"): .mid
        case ("Equity", "Large cap"): .large
        case ("Equity", _) where fund.category.contains("Sectoral") || fund.category.contains("Thematic"): .sectoral
        case ("Equity", _) where fund.category.contains("Contra") || fund.category.contains("Value"): .contra
        case ("Equity", _): .flexi
        default: .hybrid
        }
        var dice = Dice(seed: fund.listedName)
        let order = dice.shuffled(Array(companies.indices))
        let largest = dice.between(3.4, 7.2)
        let holdings = order.enumerated().map { place, company in
            Holding(id: place, name: companies[company].name, short: companies[company].short, logo: companies[company].logo,
                    sector: companies[company].sector, share: (drawnShares[place] / drawnShares[0] * largest * 100).rounded() / 100)
        }
        let sectors = sectors(for: kind).map { ($0.name, (($0.share + dice.between(-0.8, 0.8)) * 100).rounded() / 100) }.sorted { $0.1 > $1.1 }
        let people = dice.shuffled(["Arjun Mehta", "Kavya Iyer", "Rohan Kulkarni", "Neha Bansal", "Vikram Desai", "Ananya Rao", "Sameer Nair", "Ishita Sen",
                                    "Rahul Menon", "Divya Kapoor", "Manish Gupta", "Sneha Pillai", "Karthik Reddy", "Pooja Shah", "Dev Khanna", "Ritu Saxena"])
        let months = ["January", "March", "May", "July", "September", "November"]
        let returned = (fund.headline * 10).rounded() / 10
        var page = MutualFund(
            name: fund.name, title: fund.name, house: fund.house, mark: .tile(fund.logo ?? ""), kind: kind, returned: returned,
            facts: [("Nav", "Rs" + String(format: "%.2f", fund.nav)),
                    ("Expense ratio", String(format: "%.2f%%", dice.between(0.18, 1.12))),
                    ("Min SIP", ["Rs100", "Rs500", "Rs1,000"][Int(dice.between(0, 2.999))]),
                    ("Rating", String(format: "%.1f", fund.score)),
                    ("Fund size", "Rs" + String(format: "%.0f", dice.between(180, 9800)) + " Cr")],
            holdings: holdings,
            sectors: sectors.map { (name: $0.0, share: $0.1) },
            managers: (0..<2).map { place in
                Manager(portrait: place == 0 ? "MFDetailManager1" : "MFDetailManager2", name: people[place],
                        since: "\(months[Int(dice.between(0, 5.999))]) \(Int(dice.between(2014, 2025.999))) - Active")
            },
            series: growth(name: fund.listedName, returned: returned, kind: kind)
        )
        // The return is the list's headline: over three years, or the longest shorter stretch the fund has run
        page.span = fund.threeYear != nil ? "3Y" : fund.oneYear != nil ? "1Y" : "All"
        return page
    }

    /// A kind of fund's sectors, the largest first: the five the frame has drawings for, at shares of the kind's
    /// own. For a debt fund they stand for the sectors of the companies it lends to.
    private static func sectors(for kind: Kind) -> [(name: String, share: Double)] {
        switch kind {
        case .small: [("Automobile", 16.4), ("Pharma", 13.8), ("Banking", 12.1), ("Commodities", 9.6), ("Energy", 5.2)]
        case .mid: [("Banking", 19.5), ("Automobile", 14.9), ("Pharma", 11.2), ("Commodities", 8.4), ("Energy", 6.8)]
        case .large: [("Banking", 27.6), ("Energy", 11.9), ("Automobile", 9.7), ("Pharma", 7.4), ("Commodities", 5.1)]
        case .flexi: [("Banking", 21.3), ("Automobile", 11.6), ("Pharma", 9.1), ("Energy", 7.2), ("Commodities", 5.8)]
        case .contra: [("Banking", 16.8), ("Energy", 12.4), ("Pharma", 9.7), ("Commodities", 8.3), ("Automobile", 6.1)]
        case .sectoral: [("Commodities", 21.3), ("Energy", 18.6), ("Automobile", 12.9), ("Banking", 9.2), ("Pharma", 3.8)]
        case .hybrid: [("Banking", 17.2), ("Energy", 8.6), ("Automobile", 7.1), ("Pharma", 6.4), ("Commodities", 4.3)]
        case .debt: [("Banking", 38.5), ("Energy", 14.4), ("Commodities", 6.2), ("Automobile", 4.8), ("Pharma", 2.1)]
        }
    }

    /// How bumpy a kind of fund's growth is
    private static func roughness(_ kind: Kind) -> Double {
        switch kind {
        case .small: 0.11
        case .sectoral: 0.1
        case .mid: 0.09
        case .hybrid: 0.045
        case .debt: 0.012
        case .contra: 0.08
        case .flexi: 0.07
        case .large: 0.06
        }
    }

    /// 141 steps from 100 to what the return makes of it in three years, wandering on the way as much as the
    /// fund's kind does; the same for a name and a return every time
    static func growth(name: String, returned: Double, kind: Kind) -> [Double] {
        path(seed: name + String(returned), from: 100, to: 100 * pow(1 + returned / 100, 3), rough: roughness(kind))
    }

    /// 141 steps from one worth to another: a random walk pinned at both ends, so it starts and ends where it is
    /// told to, and the same for a seed every time
    private static func path(seed: String, from: Double, to: Double, rough: Double) -> [Double] {
        var dice = Dice(seed: seed)
        let steps = 141
        let end = log(to / from)
        var walk = [0.0]
        for _ in 1..<steps { walk.append(walk[walk.count - 1] + dice.between(-1, 1)) }
        let last = walk[steps - 1]
        let reach = max(walk.enumerated().map { abs($0.element - last * Double($0.offset) / Double(steps - 1)) }.max() ?? 1, 0.001)
        return (0..<steps).map { step in
            let along = Double(step) / Double(steps - 1)
            let wander = (walk[step] - last * along) / reach
            return (from * exp(end * along + rough * wander) * 100).rounded() / 100
        }
    }

    /// The prices to mark beside a curve drawn in rupees (101:15007 …): a round price at or just under the
    /// curve's lowest, which the curve's wash stands on, and every second round price up from it. The frame's
    /// curve runs from about Rs37.2 to Rs41.7 and is marked at 37, 39 and 43.
    static func scale(low: Double, high: Double) -> (base: Double, step: Double, decimals: Int) {
        let rough = max(high - low, 0.0001) / 4
        let power = pow(10, floor(log10(rough)))
        let unit = [5, 2, 1].map { $0 * power }.first { $0 <= rough * 1.0001 } ?? power
        let base = (low / unit + 0.0001).rounded(.down) * unit
        return (base, unit * 2, unit >= 1 ? 0 : min(3, Int((-log10(unit)).rounded(.up))))
    }
}

// MARK: Periods

extension MutualFund {
    /// A stretch of the fund's past the chart can show (101:15011)
    enum Period: String, CaseIterable, Identifiable {
        case month = "1M", half = "6M", year = "1Y", three = "3Y", five = "5Y", all = "All"

        var id: String { rawValue }

        /// As VoiceOver says it
        var spoken: String {
            switch self {
            case .month: "1 month"
            case .half: "6 months"
            case .year: "1 year"
            case .three: "3 years"
            case .five: "5 years"
            case .all: "All time"
            }
        }
    }

    /// The fund's growth over a period, as the chart draws it
    struct Chart {
        let period: Period
        /// What 100 put in at the start of the period has been worth since, at 141 even steps up to now
        let series: [Double]
        /// How long the period is, in years
        let years: Double
        /// The return over it, in percent: a year where the period is a year or more, the whole of it where it is less
        let returned: Double
    }

    /// How many years the fund has run, which is what "All" covers. Sample: from the fund's name.
    var age: Double {
        var dice = Dice(seed: name + " age")
        return (dice.between(6, 11) * 2).rounded() / 2
    }

    /// The three years the fund carries are as drawn (or, for a sample fund, as made for its return). The shorter
    /// periods are their last stretch, with a day-by-day grain between the three years' points that leaves the
    /// points themselves where they are. The longer ones go further back along a path made for the fund, which arrives
    /// at the three years' start. Every period is counted from 100 at its own start, as the frame's is.
    func chart(for period: Period) -> Chart {
        let last = series.count - 1
        let rough = Self.roughness(kind)
        let age = self.age
        var dice = Dice(seed: name + " before")
        // Before the three years: steadier growth, at a rate of the fund's own
        let earlier = Self.path(seed: name + " earlier", from: 100 / pow(1 + dice.between(0.07, 0.16), age - 3), to: 100, rough: rough * 1.3)
        // The grain inside each step of the three years, which is about eight days: a value for each day between,
        // joined by straight lines, and nothing at the step's two ends
        let days = 8
        var grainDice = Dice(seed: name + " grain")
        let grain: [[Double]] = (0..<last).map { _ in [0] + (1..<days).map { _ in grainDice.between(-1, 1) } + [0] }

        func worth(_ ago: Double) -> Double {
            if ago <= 3 {
                let place = (3 - ago) / 3 * Double(last)
                let step = min(Int(place), last - 1)
                let within = place - Double(step)
                let line = series[step] + (series[step + 1] - series[step]) * within
                let day = min(Int(within * Double(days)), days - 1)
                let ripple = grain[step][day] + (grain[step][day + 1] - grain[step][day]) * (within * Double(days) - Double(day))
                return line * (1 + rough * 0.045 * ripple)
            }
            let place = (age - ago) / (age - 3) * Double(last)
            let step = min(max(Int(place), 0), last - 1)
            return earlier[step] + (earlier[step + 1] - earlier[step]) * (place - Double(step))
        }

        let years: Double = switch period {
        case .month: 1.0 / 12
        case .half: 0.5
        case .year: 1
        case .three: 3
        case .five: 5
        case .all: age
        }
        let start = worth(years)
        let rebased = period == .three ? series : (0...last).map { step in
            (worth(years * (1 - Double(step) / Double(last))) / start * 10_000).rounded() / 100
        }
        let grown = (rebased[last] / rebased[0])
        let returned = period == .three ? self.returned : years >= 1 ? (pow(grown, 1 / years) - 1) * 100 : (grown - 1) * 100
        return Chart(period: period, series: rebased, years: years, returned: returned)
    }

}

/// A small repeatable source of chance, seeded from a string, for the sample funds
private struct Dice {
    private var state: UInt64

    init(seed: String) {
        // FNV-1a, which is the same on every run (`hashValue` is not)
        var hash: UInt64 = 0xCBF2_9CE4_8422_2325
        for byte in seed.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01B3
        }
        state = hash
    }

    /// SplitMix64
    private mutating func next() -> UInt64 {
        state = state &+ 0x9E37_79B9_7F4A_7C15
        var mixed = state
        mixed = (mixed ^ (mixed >> 30)) &* 0xBF58_476D_1CE4_E5B9
        mixed = (mixed ^ (mixed >> 27)) &* 0x94D0_49BB_1331_11EB
        return mixed ^ (mixed >> 31)
    }

    mutating func between(_ low: Double, _ high: Double) -> Double {
        low + (high - low) * Double(next() >> 11) / Double(1 << 53)
    }

    mutating func shuffled<Element>(_ items: [Element]) -> [Element] {
        var items = items
        for index in items.indices.dropLast() {
            let other = index + Int(next() % UInt64(items.count - index))
            items.swapAt(index, other)
        }
        return items
    }
}
