import Foundation

struct AppState: Codable {
    var me: Trader
    var markets: [Market] = []
    var traders: [Trader] = []
    var trades: [Trade] = []
    var settlements: [Settlement] = []
    var theses: [Thesis] = []
    var watchlist: [String] = []
    var onboarded: Bool = false
    var seasonStart: Date = Date()

    static let startingCash: Double = 10_000

    static var empty: AppState {
        AppState(me: Trader(id: "me", name: "Sen", handle: "sen", avatarSeed: 0,
                            cash: startingCash, score: 50, resolvedCount: 0,
                            correctCount: 0, streak: 0, title: nil, isMe: true))
    }
}

// MARK: - Kurulum

enum StateBuilder {

    static func market(from s: MarketSeed, now: Date) -> Market {
        let spread = LMSR.qSpread(forPrice: s.price, b: s.b)
        let created = now.addingTimeInterval(-Double(s.openedDaysAgo) * 86_400)
        let span = min(Double(s.openedDaysAgo) * 86_400, 30 * 86_400)
        let history = MarketSimulator.syntheticHistory(
            points: 80, end: s.price,
            volatility: 0.016 + Double((abs(s.id.hashValue) % 10)) * 0.001,
            span: max(span, 3 * 86_400), until: now)

        return Market(
            id: s.id, question: s.q, detail: s.detail, resolutionSource: s.source,
            category: s.cat, createdAt: created,
            closeDate: now.addingTimeInterval(Double(s.closesInDays) * 86_400),
            liquidity: s.b, qYes: spread / 2, qNo: -spread / 2,
            volume: s.volume, participants: s.participants, history: history,
            status: .open, resolvedOutcome: nil, resolvedAt: nil,
            latentProbability: s.price, indexTheme: s.theme, indexInverted: s.inverted)
    }

    static func settlement(from s: SettlementSeed, now: Date) -> Settlement {
        let myPrice = s.side == .yes ? s.entryYes : 1 - s.entryYes
        let invested = s.shares * myPrice * 100
        let correct = (s.side == .yes) == s.outcome
        return Settlement(
            marketId: "past-" + UUID().uuidString.prefix(6),
            question: s.q, category: s.cat, outcome: s.outcome, mySide: s.side,
            shares: s.shares, invested: invested,
            payout: correct ? s.shares * 100 : 0,
            entryProbability: s.entryYes, horizonDays: s.horizon,
            date: now.addingTimeInterval(-Double(s.daysAgo) * 86_400))
    }

    static func theses(now: Date) -> [Thesis] {
        SeedPeople.theses.map { t in
            let author = SeedPeople.traders.first { $0.name == t.author }
            return Thesis(
                marketId: t.marketId, authorId: author?.id ?? "t0",
                authorName: t.author, authorScore: t.score, side: t.side,
                priceAtPost: t.price, text: t.text,
                sources: t.sources.map { EvidenceSource(title: $0, detail: nil) },
                upvotes: t.upvotes,
                date: now.addingTimeInterval(-Double(t.hoursAgo) * 3600))
        }
    }

    /// Demo hesabındaki açık pozisyonlar — (piyasa, taraf, bütçe)
    static let demoPositions: [(String, Side, Double)] = [
        ("eko-faiz-30", .yes, 6_500),
        ("tek-iphone-100k", .yes, 9_200),
        ("spor-gs-lig", .yes, 5_400),
        ("eko-enf-20", .no, 7_800),
        ("hava-kar", .yes, 3_100),
        ("tek-togg", .no, 4_000),
    ]

    static let demoStartingCash: Double = 128_000
}
