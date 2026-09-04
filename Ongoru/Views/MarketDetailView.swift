import SwiftUI

struct MarketDetailView: View {
    @EnvironmentObject var store: AppStore
    let marketId: String

    @State private var range: Range = .ay
    @State private var tradeSide: Side? = nil
    @State private var showComposer = false
    @State private var showCriteria = false
    @State private var confirmClose = false
    @State private var reportTarget: String? = nil

    enum Range: String, CaseIterable, Identifiable {
        case gun, hafta, ay, tum
        var id: String { rawValue }
        var label: String {
            switch self {
            case .gun:   return L("1G", "1D")
            case .hafta: return L("1H", "1W")
            case .ay:    return L("1A", "1M")
            case .tum:   return L("Tümü", "All")
            }
        }
        var interval: TimeInterval? {
            switch self {
            case .gun: return 86_400
            case .hafta: return 7 * 86_400
            case .ay: return 30 * 86_400
            case .tum: return nil
            }
        }
    }

    private var market: Market? { store.market(id: marketId) }

    var body: some View {
        Group {
            if let market {
                content(market)
            } else {
                EmptyState(icon: "questionmark.circle",
                           title: L("Piyasa bulunamadı", "Market not found"), message: "")
            }
        }
        .background(Palette.bg)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        store.toggleWatch(marketId)
                    } label: {
                        Label(store.isWatched(marketId)
                              ? L("Takipten çıkar", "Remove from watchlist")
                              : L("Takibe al", "Add to watchlist"),
                              systemImage: store.isWatched(marketId) ? "bookmark.slash" : "bookmark")
                    }
                    if let market {
                        ShareLink(item: shareText(market)) {
                            Label(L("Paylaş", "Share"), systemImage: "square.and.arrow.up")
                        }
                    }
                    Divider()
                    Button(role: .destructive) {
                        reportTarget = marketId
                    } label: {
                        Label(L("Bildir", "Report"), systemImage: "flag")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 15, weight: .semibold))
                }
                .accessibilityLabel(L("Daha fazla", "More"))
            }
        }
        .sheet(item: $tradeSide) { side in
            TradeSheet(marketId: marketId, initialSide: side).environmentObject(store)
        }
        .sheet(isPresented: $showComposer) {
            ThesisComposerView(marketId: marketId).environmentObject(store)
        }
        .sheet(item: Binding(get: { reportTarget.map { ReportTarget(id: $0) } },
                             set: { reportTarget = $0?.id })) { target in
            ReportSheet(targetKind: "market", targetId: target.id).environmentObject(store)
        }
    }

    struct ReportTarget: Identifiable { var id: String }

    private func shareText(_ m: Market) -> String {
        L("“\(m.question.s)” — kalabalık \(Fmt.pctInt(m.centsYes)) diyor. Öngörü'de tahminini yaz.",
          "“\(m.question.s)” — the crowd says \(Fmt.pctInt(m.centsYes)). Make your call on Öngörü.")
    }

    @ViewBuilder
    private func content(_ market: Market) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headline(market)
                chartBlock(market)
                if market.isTradable {
                    YesNoButtons(market: market) { side in
                        Haptics.tap()
                        tradeSide = side
                    }
                    spreadRow(market)
                } else {
                    resolvedBanner(market)
                }
                if let pos = store.position(for: marketId) { positionCard(pos, market) }
                statsGrid(market)
                criteria(market)
                briefing(market)
                thesesSection(market)
                Color.clear.frame(height: 24)
            }
            .padding(.horizontal, 14)
            .padding(.top, 6)
        }
    }

    // MARK: Başlık

    private func headline(_ m: Market) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                CategoryBadge(category: m.category)
                if m.origin == .community, let author = m.authorName {
                    Text(L("\(author) açtı", "opened by \(author)"))
                        .font(.system(size: 10)).foregroundStyle(Palette.gold)
                }
                Spacer()
                Text(m.status == .resolved
                     ? L("sonuçlandı", "resolved")
                     : (m.daysLeft == 0 ? Fmt.kalan(m.closeDate)
                        : L("\(Fmt.kalan(m.closeDate)) kaldı", "\(Fmt.kalan(m.closeDate)) left")))
                    .font(.system(size: 11)).foregroundStyle(Palette.faint)
            }
            Text(m.question.s)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(Palette.text)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .firstTextBaseline, spacing: 9) {
                Text("\(m.centsYes)¢")
                    .font(.mono(38, .bold))
                    .foregroundStyle(m.sliceTrend() >= 0 ? Palette.yes : Palette.no)
                    .contentTransition(.numericText())
                if m.status == .resolved {
                    Text(L("kapanış fiyatı", "closing price"))
                        .font(.system(size: 10)).foregroundStyle(Palette.faint)
                } else {
                    VStack(alignment: .leading, spacing: 1) {
                        ChangeTag(value: m.change24h)
                        Text(L("son 24 saat", "last 24 hours"))
                            .font(.system(size: 9)).foregroundStyle(Palette.faint)
                    }
                }
                Spacer()
            }
            ProbabilityBar(p: m.priceYes)
            HStack {
                Text("\(Side.yes.title) \(Fmt.pctInt(m.centsYes))")
                    .font(.system(size: 10, weight: .semibold)).foregroundStyle(Palette.yes)
                Spacer()
                Text("\(Side.no.title) \(Fmt.pctInt(m.centsNo))")
                    .font(.system(size: 10, weight: .semibold)).foregroundStyle(Palette.no)
            }
        }
    }

    // MARK: Grafik

    private func chartBlock(_ m: Market) -> some View {
        VStack(spacing: 10) {
            PriceChart(points: visiblePoints(m),
                       color: rangeTrend(m) >= 0 ? Palette.yes : Palette.no)
                .frame(height: 168)
                .accessibilityLabel(L("Fiyat grafiği", "Price chart"))
            Picker("", selection: $range) {
                ForEach(Range.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)
        }
        .card(padding: 12)
    }

    private func rangeTrend(_ m: Market) -> Double {
        let pts = visiblePoints(m)
        guard let first = pts.first, let last = pts.last else { return 0 }
        return last.p - first.p
    }

    private func visiblePoints(_ m: Market) -> [PricePoint] {
        guard let interval = range.interval, let last = m.history.last else { return m.history }
        let cutoff = last.t.addingTimeInterval(-interval)
        let subset = m.history.filter { $0.t >= cutoff }
        return subset.count >= 2 ? subset : Array(m.history.suffix(2))
    }

    // MARK: Alış / satış farkı

    private func spreadRow(_ m: Market) -> some View {
        let s = m.spread()
        return HStack(spacing: 0) {
            StatTile(label: L("Alış", "Bid"), value: Fmt.cents(s.bid), accent: Palette.muted)
            StatTile(label: L("Satış", "Ask"), value: Fmt.cents(s.ask), accent: Palette.muted)
            StatTile(label: L("Fark", "Spread"),
                     value: Fmt.decimal((s.ask - s.bid) * 100, decimals: 1) + "¢",
                     accent: Palette.muted,
                     sub: L("50 sözleşmede", "at 50 contracts"))
        }
        .card(padding: 12)
    }

    // MARK: Çözümlenmiş bant

    private func resolvedBanner(_ m: Market) -> some View {
        let outcome = m.resolvedOutcome ?? false
        return HStack(spacing: 10) {
            Image(systemName: outcome ? "checkmark.seal.fill" : "xmark.seal.fill")
                .font(.system(size: 17))
                .foregroundStyle(outcome ? Palette.yes : Palette.no)
            VStack(alignment: .leading, spacing: 2) {
                Text(L("Sonuç: ", "Result: ") + (outcome ? Side.yes.title : Side.no.title))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(outcome ? Palette.yes : Palette.no)
                Text(m.resolvedAt.map { L("Çözüm tarihi \(Fmt.shortDate($0))",
                                          "Resolved on \(Fmt.shortDate($0))") } ?? "")
                    .font(.system(size: 11)).foregroundStyle(Palette.muted)
            }
            Spacer()
        }
        .card()
    }

    // MARK: Pozisyon

    private func positionCard(_ pos: Position, _ m: Market) -> some View {
        let side = pos.netSide ?? .yes
        let pnl = pos.pnl(at: m)
        return VStack(alignment: .leading, spacing: 11) {
            HStack {
                Text(L("POZİSYONUN", "YOUR POSITION"))
                    .font(.system(size: 9, weight: .bold)).kerning(0.7)
                    .foregroundStyle(Palette.faint)
                Spacer()
                HStack(spacing: 3) {
                    Image(systemName: side.glyph).font(.system(size: 8, weight: .bold))
                    Text(side.title).font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(side.color)
                .padding(.horizontal, 7).padding(.vertical, 2)
                .background(side.dimColor).clipShape(Capsule())
            }
            HStack(spacing: 0) {
                StatTile(label: L("Sözleşme", "Contracts"), value: Fmt.puan(pos.shares))
                StatTile(label: L("Ort. maliyet", "Avg cost"), value: Fmt.cents(pos.avgPrice(for: side)))
                StatTile(label: L("Değer", "Value"), value: Fmt.puan(pos.value(at: m)))
                StatTile(label: L("K/Z", "P&L"), value: Fmt.signed(pnl),
                         accent: pnl >= 0 ? Palette.yes : Palette.no)
            }
            HStack(spacing: 8) {
                Button {
                    store.closePosition(marketId: marketId, fraction: 0.5)
                } label: { smallButton(L("Yarısını sat", "Sell half"), Palette.muted) }
                Button {
                    confirmClose = true
                } label: { smallButton(L("Pozisyonu kapat", "Close position"), Palette.no) }
            }
            Text(L("Kazanırsan \(Fmt.puan(pos.shares * 100)) puan ödenir.",
                   "Pays \(Fmt.puan(pos.shares * 100)) points if you're right."))
                .font(.system(size: 10)).foregroundStyle(Palette.faint)
        }
        .card()
        .confirmationDialog(L("Pozisyonu tamamen kapat?", "Close the whole position?"),
                            isPresented: $confirmClose, titleVisibility: .visible) {
            Button(L("Kapat", "Close"), role: .destructive) {
                store.closePosition(marketId: marketId)
            }
            Button(L("Vazgeç", "Cancel"), role: .cancel) {}
        } message: {
            Text(L("Güncel fiyattan satılır; sonuç açıklanmadan çıktığın için ödeme almazsın.",
                   "Sold at the current price. You exit before resolution, so you receive no payout."))
        }
    }

    private func smallButton(_ title: String, _ color: Color) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    // MARK: İstatistik

    private func statsGrid(_ m: Market) -> some View {
        HStack(spacing: 0) {
            StatTile(label: L("İşlem", "Trades"), value: Fmt.compact(m.volume))
            StatTile(label: L("Katılımcı", "Traders"), value: Fmt.compact(m.participants))
            StatTile(label: L("Kapanış", "Closes"), value: Fmt.shortDate(m.closeDate))
            StatTile(label: L("7 gün", "7 days"),
                     value: Fmt.signedDecimal(m.changeSince(7 * 86_400)) + "p",
                     accent: m.changeSince(7 * 86_400) >= 0 ? Palette.yes : Palette.no)
        }
        .card()
    }

    // MARK: Çözüm kriteri

    private func criteria(_ m: Market) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Button { withAnimation(.easeInOut(duration: 0.2)) { showCriteria.toggle() } } label: {
                HStack {
                    Text(L("Çözüm kriteri", "Resolution criteria"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Palette.text)
                    Spacer()
                    Image(systemName: showCriteria ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .bold)).foregroundStyle(Palette.faint)
                }
            }
            .buttonStyle(.plain)
            if showCriteria {
                Text(m.detail.s)
                    .font(.system(size: 12)).foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 5) {
                    Image(systemName: "link").font(.system(size: 9))
                    Text(m.resolutionSource.s).font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(Palette.accent)
            }
        }
        .card()
    }

    // MARK: Asistan

    private func briefing(_ m: Market) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles").font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Palette.accent)
                Text(L("Öngörü Asistanı", "Öngörü Assistant"))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Palette.text)
                Spacer()
                Text(L("cihaz üstü", "on-device")).font(.system(size: 9))
                    .foregroundStyle(Palette.faint)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Palette.surfaceHigh).clipShape(Capsule())
            }
            ForEach(store.briefing(for: m)) { InsightRow(insight: $0) }
        }
        .card()
    }

    // MARK: Gerekçeler

    private func thesesSection(_ m: Market) -> some View {
        let list = store.theses(for: marketId)
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: L("Gerekçeler", "Rationales"),
                          sub: L("\(list.count) katılımcı neden böyle düşündüğünü yazdı",
                                 "\(list.count) traders explained their reasoning"))
            Button {
                Haptics.tap()
                showComposer = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.pencil").font(.system(size: 12, weight: .semibold))
                    Text(L("Gerekçeni yaz", "Write your rationale"))
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(Palette.accent)
                .padding(.horizontal, 13).padding(.vertical, 11)
                .background(Palette.accent.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            }
            .buttonStyle(.plain)

            if list.isEmpty {
                Text(L("Henüz gerekçe yok. İlk yazan sen ol.",
                       "No rationales yet. Be the first."))
                    .font(.system(size: 12)).foregroundStyle(Palette.faint)
                    .padding(.vertical, 8)
            } else {
                ForEach(list) { t in ThesisCard(thesis: t) }
            }
        }
    }
}

// MARK: - Gerekçe kartı

struct ThesisCard: View {
    @EnvironmentObject var store: AppStore
    var thesis: Thesis
    @State private var expanded = false
    @State private var showReport = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 9) {
                Avatar(initials: initials, seed: thesis.authorName.hashValue, size: 30)
                VStack(alignment: .leading, spacing: 1) {
                    Text(thesis.authorName).font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Palette.text)
                    HStack(spacing: 5) {
                        Text(L("Skor \(thesis.authorScore)", "Score \(thesis.authorScore)"))
                            .font(.mono(10, .semibold))
                            .foregroundStyle(thesis.authorScore >= 70 ? Palette.yes : Palette.muted)
                        Text("·").foregroundStyle(Palette.faint)
                        Text(Fmt.relative(thesis.date)).font(.system(size: 10))
                            .foregroundStyle(Palette.faint)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 3) {
                        Image(systemName: thesis.side.glyph).font(.system(size: 7, weight: .bold))
                        Text(thesis.side.title).font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(thesis.side.color)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(thesis.side.dimColor).clipShape(Capsule())
                    Text(L("\(Fmt.cents(thesis.priceAtPost))'ten", "from \(Fmt.cents(thesis.priceAtPost))"))
                        .font(.mono(9, .medium)).foregroundStyle(Palette.faint)
                }
            }

            if thesis.underReview {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 9))
                    Text(L("İncelemede", "Under review")).font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(Palette.gold)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Palette.gold.opacity(0.12))
                .clipShape(Capsule())
            }

            Text(thesis.text.s)
                .font(.system(size: 13))
                .foregroundStyle(Palette.text.opacity(0.88))
                .lineLimit(expanded ? nil : 3)
                .fixedSize(horizontal: false, vertical: true)
                .onTapGesture { withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() } }

            if !thesis.sources.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(thesis.sources) { s in
                        HStack(spacing: 6) {
                            Image(systemName: "doc.text").font(.system(size: 9))
                                .foregroundStyle(Palette.faint)
                            Text(s.title.s).font(.system(size: 11))
                                .foregroundStyle(Palette.muted)
                        }
                    }
                }
                .padding(9)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.surfaceHigh.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            }

            HStack(spacing: 12) {
                Button { store.toggleUpvote(thesis.id) } label: {
                    HStack(spacing: 4) {
                        Image(systemName: thesis.iUpvoted ? "arrow.up.circle.fill" : "arrow.up.circle")
                            .font(.system(size: 12))
                        Text(Fmt.int(thesis.upvotes)).font(.mono(11, .semibold))
                    }
                    .foregroundStyle(thesis.iUpvoted ? Palette.accent : Palette.muted)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L("Beğen", "Upvote"))

                HStack(spacing: 4) {
                    Image(systemName: "checkmark.shield").font(.system(size: 10))
                    Text(L("Kalite \(thesis.quality)/100 · \(ThesisAnalyzer.qualityLabel(thesis.quality))",
                           "Quality \(thesis.quality)/100 · \(ThesisAnalyzer.qualityLabel(thesis.quality))"))
                        .font(.system(size: 10))
                }
                .foregroundStyle(qualityColor)
                Spacer()
                Button { showReport = true } label: {
                    Image(systemName: "flag").font(.system(size: 11))
                        .foregroundStyle(Palette.faint)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L("Bildir", "Report"))
            }
        }
        .card()
        .sheet(isPresented: $showReport) {
            ReportSheet(targetKind: "thesis", targetId: thesis.id).environmentObject(store)
        }
    }

    private var initials: String {
        let parts = thesis.authorName.split(separator: " ")
        let a = parts.first?.first.map(String.init) ?? "?"
        let b = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (a + b).uppercased()
    }

    private var qualityColor: Color {
        switch thesis.quality {
        case 75...: return Palette.yes
        case 50..<75: return Palette.gold
        default: return Palette.faint
        }
    }
}

extension Side: Identifiable {
    public var id: String { rawValue }
}
