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
    let auth = AuthService()

    private var timer: AnyCancellable?
    private var saveWork: DispatchWorkItem?

    init(preview: Bool = false) {
        if !preview, let saved = Persistence.load() {
            state = saved
        } else {
            state = AppState.empty
            I18N.lang = state.language.resolved
            state.markets = SeedMarkets.all.map { StateBuilder.market(from: $0, now: Date()) }
            state.traders = SeedPeople.traders
            state.theses = StateBuilder.theses(now: Date())
        }
        I18N.lang = state.language.resolved
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

    /// Aşağı çekerek yenileme — kalabalığı bir tik ileri alır.
    func refreshNow() {
        MarketSimulator.tick(markets: &state.markets)
        index = ExpectationIndexEngine.snapshot(markets: state.markets)
        scheduleSave()
    }

    // MARK: - Dil

    var language: AppLanguage { state.language }

    func setLanguage(_ lang: AppLanguage) {
        state.language = lang
        I18N.lang = lang.resolved
        Haptics.select()
        Persistence.save(state)
    }

    // MARK: - Hesap

    var account: Account? { state.account }

    /// Girişten sonra hesabı bağlar ve oturumu başlatır.
    func completeSignIn(account: Account, withSampleRecord sample: Bool) {
        state.account = account
        state.me.name = account.displayName
        state.me.handle = Self.handle(from: account.displayName)
        state.onboarded = true
        state.seasonStart = Date()

        if sample {
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
        Haptics.success()
        Persistence.save(state)
    }

    func signOut() {
        stop()
        Persistence.wipe()
        var fresh = AppState.empty
        fresh.language = state.language
        fresh.markets = SeedMarkets.all.map { StateBuilder.market(from: $0, now: Date()) }
        fresh.traders = SeedPeople.traders
        fresh.theses = StateBuilder.theses(now: Date())
        state = fresh
        refreshDerived()
        start()
    }

    func rename(_ newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let check = ContentModerator.check(trimmed, kind: .displayName)
        guard !check.isBlocked else {
            toast = check.title
            Haptics.error()
            return
        }
        state.me.name = trimmed
        state.me.handle = Self.handle(from: trimmed)
        state.account?.displayName = trimmed
        Persistence.save(state)
    }

    private static func handle(from name: String) -> String {
        let base = name.lowercased(with: Locale(identifier: "tr_TR"))
            .folding(options: .diacriticInsensitive, locale: Locale(identifier: "en_US"))
            .replacingOccurrences(of: " ", with: "")
            .filter { $0.isLetter || $0.isNumber }
        return base.isEmpty ? "kullanici" : String(base.prefix(18))
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
    var proposals: [MarketProposal] { state.proposals.sorted { $0.createdAt > $1.createdAt } }

    func theses(for marketId: String) -> [Thesis] {
        state.theses
            .filter { $0.marketId == marketId }
            .filter { !state.hiddenThesisIds.contains($0.id) }
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
                 title: $0.title?.s, isMe: false, position: 0)
        }
        all.append(Rank(id: "me", name: state.me.name, handle: state.me.handle,
                        points: totalPoints, score: scoreCard.score, accuracy: scoreCard.accuracy,
                        resolved: scoreCard.resolved, streak: scoreCard.streak,
                        title: scoreCard.resolved > 0 ? scoreCard.grade : L("Yeni", "New"),
                        isMe: true, position: 0))

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
            if !silent { toast = L("Bu piyasa işleme kapalı.", "This market is closed for trading.") }
            return nil
        }
        guard budget > 0, budget <= state.me.cash + 0.01 else {
            if !silent { toast = L("Yetersiz puan.", "Not enough points."); Haptics.error() }
            return nil
        }

        let shares = LMSR.shares(forBudget: budget, market: market, side: side)
        guard shares > 0.01 else {
            if !silent { toast = L("Miktar çok küçük.", "Amount is too small.") }
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
            Haptics.success()
            toast = L("\(Fmt.puan(shares)) sözleşme · \(side.title) · ort. \(Fmt.cents(avg))",
                      "\(Fmt.puan(shares)) contracts · \(side.title) · avg \(Fmt.cents(avg))")
        }
        scheduleSave()
        return trade
    }

    @discardableResult
    func closePosition(marketId: String, fraction: Double = 1.0) -> Double? {
        guard let idx = state.markets.firstIndex(where: { $0.id == marketId }),
              let pos = position(for: marketId), let side = pos.netSide else { return nil }
        var market = state.markets[idx]
        guard market.isTradable else {
            toast = L("Bu piyasa işleme kapalı.", "This market is closed for trading.")
            return nil
        }

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
        Haptics.success()
        toast = L("Pozisyon kapatıldı · \(Fmt.puan(proceeds)) puan",
                  "Position closed · \(Fmt.puan(proceeds)) points")
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
        let result = outcome ? L("EVET", "YES") : L("HAYIR", "NO")
        if let last = state.settlements.last, last.marketId == marketId {
            Haptics.success()
            toast = last.correct
                ? L("Sonuç \(result) · haklı çıktın, \(Fmt.puan(payout)) puan ödendi",
                    "Result \(result) · you were right, \(Fmt.puan(payout)) points paid")
                : L("Sonuç \(result) · yanıldın, \(Fmt.puan(last.invested)) puan gitti",
                    "Result \(result) · you were wrong, \(Fmt.puan(last.invested)) points lost")
        } else {
            toast = L("Sonuç \(result) · bu piyasada pozisyonun yoktu",
                      "Result \(result) · you had no position here")
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

        let myAvg = pos.avgPrice(for: side)
        let entryYes = side == .yes ? myAvg : 1 - myAvg

        state.settlements.append(Settlement(
            marketId: m.id, question: m.question, category: m.category, outcome: outcome,
            mySide: side, shares: shares, invested: invested, payout: payout,
            entryProbability: min(max(entryYes, 0.01), 0.99),
            horizonDays: m.horizonDays, date: date))
    }

    // MARK: - Gerekçeler

    /// Moderasyondan geçerse yayımlar. Engellenirse `nil` döner ve sebebi
    /// çağıran tarafa `result` ile bildirilir.
    func postThesis(marketId: String, side: Side, text: String,
                    sources: [EvidenceSource]) -> (thesis: Thesis?, moderation: ModerationResult) {
        let verdict = ContentModerator.check(text, kind: .thesis)
        guard !verdict.isBlocked else {
            Haptics.error()
            return (nil, verdict)
        }
        guard let m = market(id: marketId) else { return (nil, verdict) }

        let t = Thesis(marketId: marketId, authorId: "me", authorName: state.me.name,
                       authorScore: scoreCard.score, side: side, priceAtPost: m.price(for: side),
                       text: LText(text), sources: sources, upvotes: 0, date: Date(),
                       underReview: verdict.severity == .flagged)
        state.theses.append(t)
        Haptics.success()
        toast = verdict.severity == .flagged
            ? L("Gerekçen yayımlandı, incelemeye alındı", "Your rationale was published and flagged for review")
            : L("Gerekçen yayımlandı", "Your rationale was published")
        scheduleSave()
        return (t, verdict)
    }

    func toggleUpvote(_ thesisId: String) {
        guard let i = state.theses.firstIndex(where: { $0.id == thesisId }) else { return }
        state.theses[i].iUpvoted.toggle()
        state.theses[i].upvotes += state.theses[i].iUpvoted ? 1 : -1
        Haptics.tap()
        scheduleSave()
    }

    func toggleWatch(_ marketId: String) {
        if let i = state.watchlist.firstIndex(of: marketId) {
            state.watchlist.remove(at: i)
        } else {
            state.watchlist.append(marketId)
            toast = L("Takibe alındı", "Added to your watchlist")
        }
        Haptics.tap()
        scheduleSave()
    }

    // MARK: - Topluluk piyasaları

    /// Kullanıcının önerdiği piyasayı denetimden geçirip yayına alır.
    @discardableResult
    func propose(question: String, detail: String, source: String, category: Category,
                 closeDate: Date, probability: Double) -> ModerationResult {
        let combined = question + "\n" + detail
        let verdict = ContentModerator.check(combined, kind: .marketQuestion)

        var proposal = MarketProposal(
            question: question.trimmingCharacters(in: .whitespacesAndNewlines),
            detail: detail.trimmingCharacters(in: .whitespacesAndNewlines),
            resolutionSource: source.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category, closeDate: closeDate,
            initialProbability: probability, createdAt: Date(),
            status: .review, moderationNote: nil)

        switch verdict.severity {
        case .blocked:
            proposal.status = .rejected
            proposal.moderationNote = verdict.title
            state.proposals.append(proposal)
            Haptics.error()
        case .flagged:
            proposal.status = .review
            proposal.moderationNote = verdict.title
            state.proposals.append(proposal)
            Haptics.warning()
            toast = L("Piyasan incelemeye alındı", "Your market was sent for review")
        case .allowed:
            let market = StateBuilder.communityMarket(from: proposal, author: state.me.name, now: Date())
            proposal.status = .live
            proposal.marketId = market.id
            state.proposals.append(proposal)
            state.markets.insert(market, at: 0)
            Haptics.success()
            toast = L("Piyasan yayında", "Your market is live")
        }
        refreshDerived()
        Persistence.save(state)
        return verdict
    }

    // MARK: - Bildirimler

    func report(targetKind: String, targetId: String, reason: ReportReason, note: String?) {
        state.reports.append(Report(targetKind: targetKind, targetId: targetId,
                                    reason: reason, note: note, date: Date()))
        if targetKind == "thesis" {
            state.hiddenThesisIds.append(targetId)
        }
        Haptics.success()
        toast = L("Bildirimin alındı, içerik senden gizlendi",
                  "Report received — the content is now hidden for you")
        scheduleSave()
    }

    // MARK: - Destek

    func recordSupport(tier: String) {
        state.supporterTier = tier
        Haptics.success()
        Persistence.save(state)
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

    func resetEverything() { signOut() }
}
