import SwiftUI

/// A mutual fund as its page shows it (`MutualFundDetailView`): what it is called, what it has returned, how it
/// has grown, the facts in Basics, what it holds, and who runs it.
///
/// One fund is drawn in Figma, "HSBC Multi Asset Allocation Fund" (37:3821), and it is here as drawn. The
/// funds on the homepages have no page in Figma, so their content is made here as a sample: it is not the funds'
/// real data. Each one's figures come from its name, so they are the same on every run. Their holdings are the
/// twenty companies the frame has logos for, in an order and at weights of the fund's own.
struct MutualFund: Identifiable {
    /// What kind of fund it is: decides its sectors, its split by company size and how bumpy its growth is
    enum Kind {
        case small, mid, large, flexi, contra, sectoral, multiAsset
    }

    /// A company the fund holds
    struct Holding: Identifiable {
        let id: Int
        /// As written in the list: "Eternal Ltd"
        let name: String
        /// As written in the map, where there is room: "Eternal"
        let short: String
        /// The company's logo, an image set's name
        let logo: String
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

    /// How the fund house is shown under the fund's name
    enum Mark {
        /// A wide mark cut down to its symbol, as the frame cuts HSBC's (37:3844)
        case wide(String)
        /// The house's square logo on its tile
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
    /// Its split by company size, in percent: large, mid, small
    let caps: [Double]
    let managers: [Manager]
    /// What 100 put in three years ago has been worth since, at even steps up to now
    let series: [Double]
    /// The prices marked beside the chart, lowest first
    let ticks: [Double]

    /// The fund's NAV now, in rupees, read from its Basics row ("Rs247.02")
    var nav: Double {
        let written = facts.first { $0.label == "Nav" }?.value ?? ""
        return Double(written.filter { $0.isNumber || $0 == "." }) ?? 100
    }

    /// The same fund with another return, and the growth that goes with it: a fund is opened with the figure
    /// that was tapped, and the homepage writes two for one of them
    func returning(_ returned: Double) -> MutualFund {
        guard returned != self.returned, kind != .multiAsset else { return self }
        let series = Self.growth(name: name, returned: returned, kind: kind)
        return MutualFund(name: name, title: title, house: house, mark: mark, kind: kind, returned: returned, facts: facts,
                          holdings: holdings, sectors: sectors, caps: caps, managers: managers, series: series, ticks: Self.ticks(for: series))
    }

    /// The fund of that name, or the drawn one if there is none. The homepage draws one name under two houses'
    /// logos, so the logo decides between them where it can.
    static func named(_ name: String, logo: String? = nil) -> MutualFund {
        all.first { $0.name == name && $0.logo == logo } ?? all.first { $0.name == name } ?? hsbc
    }

    /// The house's square logo, where it is shown on a tile
    var logo: String? {
        if case .tile(let image) = mark { image } else { nil }
    }

    // MARK: The drawn fund

    /// The companies the frame has logos for (41:1812 …), in the order it draws them
    static let companies: [(name: String, short: String, logo: String)] = [
        ("Eternal Ltd", "Eternal", "MFHoldEternal"),
        ("Eicher Motors Ltd", "Eicher Motors", "MFHoldEicher"),
        ("Mahindra & Mahindra", "M&M", "MFHoldMahindra"),
        ("HDFC Bank Ltd", "HDFC Bank", "MFHoldHDFCBank"),
        ("Bharti Airtel Ltd", "Airtel", "MFHoldAirtel"),
        ("ICICI Bank Ltd", "ICICI Bank", "MFHoldICICIBank"),
        ("Reliance Industries Ltd", "Reliance", "MFHoldReliance"),
        ("Infosys Ltd", "Infosys", "MFHoldInfosys"),
        ("Tata Motors Ltd", "Tata Motors", "MFHoldTataMotors"),
        ("Larsen & Toubro Ltd", "L&T", "MFHoldLT"),
        ("State Bank of India", "SBI", "MFHoldSBI"),
        ("Axis Bank Ltd", "Axis Bank", "MFHoldAxisBank"),
        ("Tata Consultancy Services Ltd", "TCS", "MFHoldTCS"),
        ("Bajaj Finance Ltd", "Bajaj Finance", "MFHoldBajajFinance"),
        ("Maruti Suzuki India Ltd", "Maruti", "MFHoldMaruti"),
        ("Sun Pharmaceutical Industries Ltd", "Sun Pharma", "MFHoldSunPharma"),
        ("ITC Ltd", "ITC", "MFHoldITC"),
        ("Titan Company Ltd", "Titan", "MFHoldTitan"),
        ("NTPC Ltd", "NTPC", "MFHoldNTPC"),
        ("UltraTech Cement Ltd", "UltraTech", "MFHoldUltraTech"),
    ]

    /// The shares the frame writes beside them
    private static let drawnShares: [Double] = [
        6.42, 5.18, 4.76, 4.31, 3.95, 3.62, 3.38, 3.11, 2.87, 2.64, 2.42, 2.21, 2.05, 1.88, 1.73, 1.59, 1.46, 1.34, 1.22, 1.11,
    ]

    /// 37:3824: the frame's own curve, read off its 141 points: 100 at the start, 147 now
    private static let drawnSeries: [Double] = [
        100.0, 100.33, 100.51, 100.43, 101.45, 101.83, 101.91, 101.69, 101.67, 101.9, 101.94, 102.36,
        102.67, 102.86, 103.57, 103.16, 103.41, 103.46, 103.73, 104.43, 104.42, 105.36, 105.43, 105.95,
        105.54, 106.37, 106.65, 107.48, 107.84, 108.39, 108.86, 109.03, 109.03, 108.88, 109.6, 108.46,
        108.62, 109.14, 109.01, 108.55, 108.14, 108.65, 109.0, 109.63, 109.69, 110.49, 110.91, 112.33,
        113.45, 113.9, 114.56, 115.63, 116.53, 117.21, 117.49, 117.1, 117.48, 117.79, 118.11, 118.54,
        118.75, 118.54, 119.14, 119.08, 119.51, 119.21, 119.82, 120.8, 120.57, 120.48, 121.38, 121.84,
        122.34, 122.44, 123.13, 123.47, 123.67, 123.47, 123.54, 124.11, 123.74, 123.61, 121.92, 121.38,
        121.39, 120.9, 121.25, 120.6, 121.08, 121.24, 122.13, 122.1, 123.06, 123.55, 124.16, 126.24,
        126.8, 127.56, 128.57, 128.94, 129.32, 128.79, 129.71, 130.19, 131.38, 132.13, 132.95, 132.97,
        133.38, 133.49, 134.46, 134.92, 135.54, 136.46, 137.06, 137.12, 138.19, 138.94, 138.93, 138.5,
        139.27, 141.1, 141.44, 142.75, 142.05, 142.39, 142.42, 142.92, 143.84, 143.96, 144.39, 144.28,
        144.87, 143.98, 144.38, 144.14, 145.29, 145.04, 146.15, 146.4, 147.0,
    ]

    /// Figma 37:3821, as drawn. Its split by size is the frame's bar (194, 90 and 37 of 321); the frame writes
    /// "6.42%" beside all three sizes, which the page replaces with the bar's own shares.
    static let hsbc = MutualFund(
        name: "HSBC Multi Asset Allocation Fund",
        title: "HSBC Multi\nAsset Allocation\nFund",
        house: "HSBC",
        mark: .wide("HSBCLogo"),
        kind: .multiAsset,
        returned: 13.7,
        facts: [("Nav", "Rs247.02"), ("Expense ratio", "0.02%"), ("Min SIP", "Rs500"), ("Rating", "5"), ("Fund size", "Rs500")],
        holdings: companies.enumerated().map { Holding(id: $0.offset, name: $0.element.name, short: $0.element.short, logo: $0.element.logo, share: drawnShares[$0.offset]) },
        sectors: [("Banking", 10.8), ("Auto", 8.6), ("IT", 6.9), ("Telecom", 5.2), ("Energy", 4.1)],
        caps: [194.0 / 321 * 100, 90.0 / 321 * 100, 37.0 / 321 * 100],
        managers: [Manager(portrait: "MFDetailManager1", name: "Priya Ranjan", since: "July 2023 - Active"),
                   Manager(portrait: "MFDetailManager2", name: "Priya Ranjan", since: "July 2023 - Active")],
        series: drawnSeries,
        ticks: [100, 130, 147]
    )

    // MARK: The homepage's funds (sample content)

    static let all: [MutualFund] = [
        hsbc,
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
                    share: (drawnShares[place] / drawnShares[0] * largest * 100).rounded() / 100)
        }
        let sectors = sectors(for: kind).map { ($0.name, (($0.share + dice.between(-0.8, 0.8)) * 10).rounded() / 10) }.sorted { $0.1 > $1.1 }
        let split = caps(for: kind).map { max(1, $0 + dice.between(-2, 2)) }
        let whole = split.reduce(0, +)
        let series = growth(name: name, returned: returned, kind: kind)
        return MutualFund(
            name: name, title: name, house: house, mark: .tile(logo), kind: kind, returned: returned,
            facts: [("Nav", nav), ("Expense ratio", expense), ("Min SIP", sip), ("Rating", rating), ("Fund size", size)],
            holdings: holdings,
            sectors: sectors.map { (name: $0.0, share: $0.1) },
            caps: split.map { $0 / whole * 100 },
            managers: managers.enumerated().map { Manager(portrait: $0.offset == 0 ? "MFDetailManager1" : "MFDetailManager2", name: $0.element.0, since: $0.element.1) },
            series: series,
            ticks: ticks(for: series)
        )
    }

    private static func sectors(for kind: Kind) -> [(name: String, share: Double)] {
        switch kind {
        case .small: [("Industrials", 18.4), ("Financials", 14.2), ("Healthcare", 11.6), ("Consumer", 9.8), ("Chemicals", 7.3)]
        case .mid: [("Financials", 21.5), ("Industrials", 15.9), ("Healthcare", 11.2), ("Auto", 9.4), ("IT", 7.8)]
        case .large: [("Banking", 27.6), ("IT", 12.8), ("Energy", 9.9), ("Auto", 8.7), ("Telecom", 5.4)]
        case .flexi: [("Banking", 19.3), ("IT", 13.6), ("Auto", 9.1), ("Utilities", 7.2), ("Telecom", 5.8)]
        case .contra: [("Banking", 16.8), ("Energy", 11.4), ("Healthcare", 9.7), ("IT", 8.3), ("Metals", 6.1)]
        case .sectoral: [("Construction", 24.3), ("Capital goods", 17.6), ("Power", 12.9), ("Cement", 9.2), ("Logistics", 6.8)]
        case .multiAsset: hsbc.sectors
        }
    }

    /// Large, mid, small
    private static func caps(for kind: Kind) -> [Double] {
        switch kind {
        case .small: [8, 17, 75]
        case .mid: [14, 68, 18]
        case .large: [86, 10, 4]
        case .flexi: [62, 24, 14]
        case .contra: [58, 22, 20]
        case .sectoral: [48, 30, 22]
        case .multiAsset: hsbc.caps
        }
    }

    /// How bumpy a kind of fund's growth is
    private static func roughness(_ kind: Kind) -> Double {
        switch kind {
        case .small: 0.11
        case .sectoral: 0.1
        case .mid: 0.09
        case .contra: 0.08
        case .flexi: 0.07
        case .large, .multiAsset: 0.06
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
        let steps = drawnSeries.count
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

    /// The prices to mark for a curve: 100, where it started; its highest; and a round one about two thirds of
    /// the way up, as the frame's 130 is between 100 and 147
    static func ticks(for series: [Double]) -> [Double] {
        let low = series.min() ?? 100
        let high = series.max() ?? 100
        let between = ((low + (high - low) * 0.64) / 10).rounded() * 10
        return [100, between, high.rounded()]
    }
}

// MARK: Periods

extension MutualFund {
    /// A stretch of the fund's past the chart can show (37:3830)
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
        /// The line under the return, in the frame's wording: "3Y an returns"
        let caption: String
        /// The prices marked beside the curve, lowest first
        let ticks: [Double]
        /// How many decimals the marked prices are written to
        let decimals: Int
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
        let low = rebased.min() ?? 100
        let high = rebased.max() ?? 100
        return Chart(
            period: period, series: rebased, years: years, returned: returned,
            caption: years >= 1 ? "\(period.rawValue) an returns" : "\(period.rawValue) returns",
            ticks: period == .three ? ticks : Self.marks(low: low, high: high),
            decimals: high - low < 10 ? 1 : 0
        )
    }

    /// The prices to mark for any curve: 100 where the curve crosses it (its lowest where it does not), its
    /// highest, and a round price between them where there is room for one
    static func marks(low: Double, high: Double) -> [Double] {
        let span = max(high - low, 0.01)
        let base = (low...high).contains(100) ? 100 : low
        // A round step: 1, 2, 2.5 or 5 times a power of ten, about a third of the way up
        let rough = span / 3
        let power = pow(10, floor(log10(rough)))
        let step = [1, 2, 2.5, 5, 10].map { $0 * power }.first { $0 >= rough } ?? rough
        let between = ((low + span * 0.64) / step).rounded() * step
        let clear = span * 0.2
        return between - base > clear && high - between > clear ? [base, between, high] : [base, high]
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
