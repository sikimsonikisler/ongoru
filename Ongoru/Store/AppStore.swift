import Foundation
import SwiftUI
import Combine

@MainActor
final class AppStore: ObservableObject {

    @Published private(set) var state: AppState
    @Published private(set) var scoreCard: ScoreCard = ScoreCard()
    @Published private(set) var index: ExpectationSnapshot = ExpectationSnapshot()
    @Published var toast: String?

    let assistant: InsightProviding = HeuristicAssistant()

    private var timer: AnyCancellable?
    private var saveWork: DispatchWorkItem?

    init(preview: Bool = false) {
        if !preview, let saved = Persistence.load() {
            state = saved
        } else {
            state = AppState.empty
            state.markets = SeedMarkets.all.map { StateBuilder.market(from: $0, now: Date()) }
            state.traders = SeedPeople.traders
            state.theses = StateBuilder.theses(now: Date())
        }
        refreshDerived()
        if preview { state.onboarded = true }
    }

    // MARK: - Yaşam döngüsü

    func start() {
        resolveExpiredMarkets()
        timer?.cancel()
        timer = Timer.publish(every: 2.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    func stop() {
        timer?.cancel()
        timer = nil
        Persistence.save(state)
    }

    private func tick() {
        guard state.onboarded else { return }
        MarketSimulator.tick(markets: &state.markets)
        driftTraders()
        index = ExpectationIndexEngine.snapshot(markets: state.markets)
        scheduleSave()
    }

    /// Rakiplerin puanları da hafifçe oynasın — lig canlı görünsün.
    private func driftTraders() {
        guard !state.traders.isEmpty else { return }
        for _ in 0..<2 {
            let i = Int.random(in: 0..<state.traders.count)
            let delta = state.traders[i].cash * Double.random(in: -0.004...0.005)
            state.traders[i].cash = max(1_000, state.traders[i].cash + delta)
        }
    }

    private func refreshDerived() {
        scoreCard = ScoreEngine.card(from: state.settlements)
        index = ExpectationIndexEngine.snapshot(markets: state.markets)
        state.me.score = scoreCard.score
        state.me.resolvedCount = scoreCard.resolved
        state.me.correctCount = scoreCard.correct
        state.me.streak = scoreCard.streak
    }

    private func scheduleSave() {
        saveWork?.cancel()
        let snapshot = state
        let work = DispatchWorkItem { Persistence.save(snapshot) }
        saveWork = work
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 1.5, execute: work)
    }

    // MARK: - Onboarding

    func completeOnboarding(name: String, withSampleRecord: Bool) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        state.me.name = trimmed.isEmpty ? "Sen" : trimmed
        state.me.handle = (trimmed.isEmpty ? "sen" : trimmed.lowercased()
            .replacingOccurrences(of: " ", with: "")
            .folding(options: .diacriticInsensitive, locale: .current))
        state.onboarded = true
        state.seasonStart = Date()

        if withSampleRecord {
            let now = Date()
            state.settlements = SeedPeople.settlements.map { StateBuilder.settlement(from: $0, now: now) }
            state.me.cash = StateBuilder.demoStartingCash
            for (marketId, side, budget) in StateBuilder.demoPositions {
                execute(marketId: marketId, side: side, budget: budget, silent: true)
            }
        } else {
            state.me.cash = AppState.startingCash
        }
        refreshDerived()
        Persistence.save(state)
    }

    // MARK: - Türetilmiş veriler

    var me: Trader { state.me }
    var markets: [Market] { state.markets }

    func market(id: String) -> Market? { state.markets.first { $0.id == id } }

    var positions: [Position] {
        var map: [String: Position] = [:]
        for t in state.trades {
            var p = map[t.marketId] ?? Position(marketId: t.marketId, yesShares: 0, noShares: 0,
                                                yesCost: 0, noCost: 0)
            let signedShares = t.action == .buy ? t.shares : -t.shares
            switch t.side {
            case .yes:
                p.yesShares += signedShares
                p.yesCost += t.puan
            case .no:
                p.noShares += signedShares
                p.noCost += t.puan
            }
            map[t.marketId] = p
        }
        return map.values
            .filter { $0.yesShares > 0.01 || $0.noShares > 0.01 }
            .filter { m in market(id: m.marketId)?.status != .resolved }
            .sorted { a, b in
                let ma = market(id: a.marketId), mb = market(id: b.marketId)
                return (ma.map { a.value(at: $0) } ?? 0) > (mb.map { b.value(at: $0) } ?? 0)
            }
    }

    func position(for marketId: String) -> Position? {
        positions.first { $0.marketId == marketId }
    }

    var portfolioValue: Double {
        positions.reduce(0) { sum, p in
            guard let m = market(id: p.marketId) else { return sum }
            return sum + p.value(at: m)
        }
    }

    var totalPoints: Double { state.me.cash + portfolioValue }

    var openPnL: Double {
        positions.reduce(0) { sum, p in
            guard let m = market(id: p.marketId) else { return sum }
            return sum + p.pnl(at: m)
        }
    }

    var settlements: [Settlement] { state.settlements.sorted { $0.date > $1.date } }

    var trades: [Trade] { state.trades.sorted { $0.date > $1.date } }

    func theses(for marketId: String) -> [Thesis] {
        state.theses.filter { $0.marketId == marketId }
            .sorted { ($0.upvotes + $0.quality * 2) > ($1.upvotes + $1.quality * 2) }
    }

    var myTheses: [Thesis] {
        state.theses.filter { $0.authorId == "me" }.sorted { $0.date > $1.date }
    }

    var watchlist: [Market] {
        state.markets.filter { state.watchlist.contains($0.id) }
    }

    func isWatched(_ id: String) -> Bool { state.watchlist.contains(id) }

    // MARK: - Lig

    struct Rank: Identifiable, Hashable {
        var id: String
        var name: String
        var handle: String
        var points: Double
        var score: Int
        var accuracy: Double
        var resolved: Int
        var streak: Int
        var title: String?
        var isMe: Bool
        var position: Int
    }

    enum LeagueKind { case points, score }

    func league(_ kind: LeagueKind) -> [Rank] {
        var all: [Rank] = state.traders.map {
            Rank(id: $0.id, name: $0.name, handle: $0.handle, points: $0.cash, score: $0.score,
                 accuracy: $0.accuracy, resolved: $0.resolvedCount, streak: $0.streak,
                 title: $0.title, isMe: false, position: 0)
        }
        all.append(Rank(id: "me", name: state.me.name, handle: state.me.handle,
                        points: totalPoints, score: scoreCard.score, accuracy: scoreCard.accuracy,
                        resolved: scoreCard.resolved, streak: scoreCard.streak,
                        title: scoreCard.resolved > 0 ? scoreCard.grade : "Yeni", isMe: true, position: 0))

        switch kind {
        case .points: all.sort { $0.points > $1.points }
        case .score:  all.sort { ($0.score, $0.resolved) > ($1.score, $1.resolved) }
        }
        for i in all.indices { all[i].position = i + 1 }
        return all
    }

    var myRank: Int { league(.points).first(where: { $0.isMe })?.position ?? 0 }

    // MARK: - İşlemler

    @discardableResult
    func execute(marketId: String, side: Side, budget: Double, silent: Bool = false) -> Trade? {
        guard let idx = state.markets.firstIndex(where: { $0.id == marketId }) else { return nil }
        var market = state.markets[idx]
        guard market.isTradable else {
            if !silent { toast = "Bu piyasa işleme kapalı." }
            return nil
        }
        guard budget > 0, budget <= state.me.cash + 0.01 else {
            if !silent { toast = "Yetersiz puan." }
            return nil
        }

        let shares = LMSR.shares(forBudget: budget, market: market, side: side)
        guard shares > 0.01 else {
            if !silent { toast = "Miktar çok küçük." }
            return nil
        }
        let cost = LMSR.tradeCost(market: market, side: side, shares: shares)
        let avg = cost / (shares * 100)

        switch side {
        case .yes: market.qYes += shares
        case .no:  market.qNo += shares
        }
        market.volume += Int(shares)
        market.participants += (position(for: marketId) == nil ? 1 : 0)
        MarketSimulator.appendHistory(&market, price: market.priceYes, at: Date())
        state.markets[idx] = market

        state.me.cash -= cost
        let trade = Trade(marketId: marketId, marketQuestion: market.question, category: market.category,
                          side: side, action: .buy, shares: shares, avgPrice: avg, puan: cost, date: Date())
        state.trades.append(trade)

        if !silent {
            toast = "\(Fmt.puan(shares, decimals: 0)) sözleşme · \(side.title) · ort. \(Fmt.cents(avg))"
        }
        scheduleSave()
        return trade
    }

    @discardableResult
    func closePosition(marketId: String, fraction: Double = 1.0) -> Double? {
        guard let idx = state.markets.firstIndex(where: { $0.id == marketId }),
              let pos = position(for: marketId), let side = pos.netSide else { return nil }
        var market = state.markets[idx]
        guard market.isTradable else { toast = "Bu piyasa işleme kapalı."; return nil }

        let shares = pos.shares * min(max(fraction, 0), 1)
        guard shares > 0.01 else { return nil }

        let proceeds = -LMSR.tradeCost(market: market, side: side, shares: -shares)
        switch side {
        case .yes: market.qYes -= shares
        case .no:  market.qNo -= shares
        }
        market.volume += Int(shares)
        MarketSimulator.appendHistory(&market, price: market.priceYes, at: Date())
        state.markets[idx] = market

        state.me.cash += proceeds
        let avg = proceeds / (shares * 100)
        state.trades.append(Trade(marketId: marketId, marketQuestion: market.question,
                                  category: market.category, side: side, action: .sell,
                                  shares: shares, avgPrice: avg, puan: -proceeds, date: Date()))
        toast = "Pozisyon kapatıldı · \(Fmt.puan(proceeds)) puan"
        scheduleSave()
        return proceeds
    }

    // MARK: - Sonuçlanma

    func resolveExpiredMarkets() {
        let now = Date()
        for i in state.markets.indices where state.markets[i].status == .open {
            if state.markets[i].closeDate <= now {
                let outcome = Double.random(in: 0...1) < state.markets[i].latentProbability
                resolve(index: i, outcome: outcome, at: now)
            }
        }
        refreshDerived()
    }

    /// Demo amaçlı: bir piyasayı hemen sonuçlandırır.
    func forceResolve(marketId: String, outcome: Bool) {
        guard let i = state.markets.firstIndex(where: { $0.id == marketId }) else { return }
        let before = state.me.cash
        resolve(index: i, outcome: outcome, at: Date())
        refreshDerived()
        Persistence.save(state)

        let payout = state.me.cash - before
        let sonuc = outcome ? "EVET" : "HAYIR"
        if let last = state.settlements.last, last.marketId == marketId {
            toast = last.correct
                ? "Sonuç \(sonuc) · haklı çıktın, \(Fmt.puan(payout)) puan ödendi"
                : "Sonuç \(sonuc) · yanıldın, \(Fmt.puan(last.invested)) puan gitti"
        } else {
            toast = "Sonuç \(sonuc) · bu piyasada pozisyonun yoktu"
        }
    }

    private func resolve(index i: Int, outcome: Bool, at date: Date) {
        let m = state.markets[i]
        // Pozisyonu piyasayı kapatmadan ÖNCE oku: `positions` sonuçlanmış
        // piyasaları eler, sonra bakarsak ödeme yapılmadan çıkarız.
        let existing = position(for: m.id)

        state.markets[i].status = .resolved
        state.markets[i].resolvedOutcome = outcome
        state.markets[i].resolvedAt = date

        guard let pos = existing, let side = pos.netSide else { return }
        let shares = pos.shares
        let invested = pos.cost
        let correct = (side == .yes) == outcome
        let payout = correct ? shares * 100 : 0
        state.me.cash += payout

        // Giriş anındaki EVET olasılığım
        let myAvg = pos.avgPrice(for: side)
        let entryYes = side == .yes ? myAvg : 1 - myAvg

        state.settlements.append(Settlement(
            marketId: m.id, question: m.question, category: m.category, outcome: outcome,
            mySide: side, shares: shares, invested: invested, payout: payout,
            entryProbability: min(max(entryYes, 0.01), 0.99),
            horizonDays: m.horizonDays, date: date))
    }

    // MARK: - Gerekçeler

    @discardableResult
    func postThesis(marketId: String, side: Side, text: String, sources: [EvidenceSource]) -> Thesis? {
        guard let m = market(id: marketId) else { return nil }
        let t = Thesis(marketId: marketId, authorId: "me", authorName: state.me.name,
                       authorScore: scoreCard.score, side: side, priceAtPost: m.price(for: side),
                       text: text, sources: sources, upvotes: 0, date: Date())
        state.theses.append(t)
        toast = "Gerekçen yayımlandı"
        scheduleSave()
        return t
    }

    func toggleUpvote(_ thesisId: String) {
        guard let i = state.theses.firstIndex(where: { $0.id == thesisId }) else { return }
        state.theses[i].iUpvoted.toggle()
        state.theses[i].upvotes += state.theses[i].iUpvoted ? 1 : -1
        scheduleSave()
    }

    func toggleWatch(_ marketId: String) {
        if let i = state.watchlist.firstIndex(of: marketId) {
            state.watchlist.remove(at: i)
        } else {
            state.watchlist.append(marketId)
            toast = "Takibe alındı"
        }
        scheduleSave()
    }

    // MARK: - Asistan

    func trackRecordInsights() -> [Insight] {
        assistant.trackRecord(card: scoreCard, name: state.me.name)
    }

    func briefing(for market: Market) -> [Insight] {
        assistant.marketBriefing(market: market, theses: theses(for: market.id))
    }

    func thesisPrompts(market: Market, side: Side, text: String, sources: [EvidenceSource]) -> [Insight] {
        assistant.thesisPrompts(market: market, side: side, text: text, sources: sources)
    }

    // MARK: - Sıfırlama

    func resetEverything() {
        stop()
        Persistence.wipe()
        var fresh = AppState.empty
        fresh.markets = SeedMarkets.all.map { StateBuilder.market(from: $0, now: Date()) }
        fresh.traders = SeedPeople.traders
        fresh.theses = StateBuilder.theses(now: Date())
        state = fresh
        refreshDerived()
        start()
    }
}
