import SwiftUI

struct MarketDetailView: View {
    @EnvironmentObject var store: AppStore
    let marketId: String

    @State private var range: Range = .ay
    @State private var tradeSide: Side? = nil
    @State private var showComposer = false
    @State private var showCriteria = false

    enum Range: String, CaseIterable, Identifiable {
        case gun = "1G", hafta = "1H", ay = "1A", tum = "Tümü"
        var id: String { rawValue }
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
                EmptyState(icon: "questionmark.circle", title: "Piyasa bulunamadı", message: "")
            }
        }
        .background(Palette.bg)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.toggleWatch(marketId)
                } label: {
                    Image(systemName: store.isWatched(marketId) ? "bookmark.fill" : "bookmark")
                        .foregroundStyle(store.isWatched(marketId) ? Palette.gold : Palette.muted)
                }
            }
        }
        .sheet(item: $tradeSide) { side in
            TradeSheet(marketId: marketId, initialSide: side)
                .environmentObject(store)
        }
        .sheet(isPresented: $showComposer) {
            ThesisComposerView(marketId: marketId)
                .environmentObject(store)
        }
    }

    @ViewBuilder
    private func content(_ market: Market) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headline(market)
                chartBlock(market)
                if market.isTradable {
                    YesNoButtons(market: market) { tradeSide = $0 }
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
            HStack {
                CategoryBadge(category: m.category)
                Spacer()
                Text(m.status == .resolved
                     ? "sonuçlandı"
                     : (m.daysLeft == 0 ? Fmt.kalan(m.closeDate) : Fmt.kalan(m.closeDate) + " kaldı"))
                    .font(.system(size: 11)).foregroundStyle(Palette.faint)
            }
            Text(m.question)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(Palette.text)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .firstTextBaseline, spacing: 9) {
                Text("\(m.centsYes)¢")
                    .font(.mono(38, .bold))
                    .foregroundStyle(m.change24h >= 0 ? Palette.yes : Palette.no)
                    .contentTransition(.numericText())
                if m.status == .resolved {
                    Text("kapanış fiyatı").font(.system(size: 10))
                        .foregroundStyle(Palette.faint)
                } else {
                    VStack(alignment: .leading, spacing: 1) {
                        ChangeTag(value: m.change24h)
                        Text("son 24 saat").font(.system(size: 9)).foregroundStyle(Palette.faint)
                    }
                }
                Spacer()
            }
            ProbabilityBar(p: m.priceYes)
            HStack {
                Text("EVET %\(m.centsYes)").font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Palette.yes)
                Spacer()
                Text("HAYIR %\(m.centsNo)").font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Palette.no)
            }
        }
    }

    // MARK: Grafik

    private func chartBlock(_ m: Market) -> some View {
        VStack(spacing: 10) {
            PriceChart(points: visiblePoints(m), color: rangeTrend(m) >= 0 ? Palette.yes : Palette.no)
                .frame(height: 168)
            Picker("", selection: $range) {
                ForEach(Range.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
        }
        .card(padding: 12)
    }

    /// Seçili aralıktaki eğim — grafiğin rengi bununla belirlenir.
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

    // MARK: Çözümlenmiş bant

    private func resolvedBanner(_ m: Market) -> some View {
        let outcome = m.resolvedOutcome ?? false
        return HStack(spacing: 10) {
            Image(systemName: outcome ? "checkmark.seal.fill" : "xmark.seal.fill")
                .font(.system(size: 17))
                .foregroundStyle(outcome ? Palette.yes : Palette.no)
            VStack(alignment: .leading, spacing: 2) {
                Text("Sonuç: \(outcome ? "EVET" : "HAYIR")")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(outcome ? Palette.yes : Palette.no)
                Text(m.resolvedAt.map { "Çözüm tarihi " + Fmt.shortDate($0) } ?? "")
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
                Text("POZİSYONUN").font(.system(size: 9, weight: .bold)).kerning(0.7)
                    .foregroundStyle(Palette.faint)
                Spacer()
                Text(side.title).font(.system(size: 10, weight: .bold))
                    .foregroundStyle(side.color)
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .background(side.dimColor).clipShape(Capsule())
            }
            HStack(spacing: 0) {
                StatTile(label: "Sözleşme", value: Fmt.puan(pos.shares))
                StatTile(label: "Ort. maliyet", value: Fmt.cents(pos.avgPrice(for: side)))
                StatTile(label: "Değer", value: Fmt.puan(pos.value(at: m)))
                StatTile(label: "K/Z", value: Fmt.signed(pnl),
                         accent: pnl >= 0 ? Palette.yes : Palette.no)
            }
            HStack(spacing: 8) {
                Button {
                    store.closePosition(marketId: marketId, fraction: 0.5)
                } label: { smallButton("Yarısını sat", Palette.muted) }
                Button {
                    store.closePosition(marketId: marketId)
                } label: { smallButton("Pozisyonu kapat", Palette.no) }
            }
            Text("Kazanırsan \(Fmt.puan(pos.shares * 100)) puan ödenir.")
                .font(.system(size: 10)).foregroundStyle(Palette.faint)
        }
        .card()
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
            StatTile(label: "İşlem", value: Fmt.compact(m.volume))
            StatTile(label: "Katılımcı", value: Fmt.compact(m.participants))
            StatTile(label: "Kapanış", value: Fmt.shortDate(m.closeDate))
            StatTile(label: "7 gün", value: Fmt.signedDecimal(m.changeSince(7 * 86_400)) + "p",
                     accent: m.changeSince(7 * 86_400) >= 0 ? Palette.yes : Palette.no)
        }
        .card()
    }

    // MARK: Çözüm kriteri

    private func criteria(_ m: Market) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Button { withAnimation(.easeInOut(duration: 0.2)) { showCriteria.toggle() } } label: {
                HStack {
                    Text("Çözüm kriteri").font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Palette.text)
                    Spacer()
                    Image(systemName: showCriteria ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .bold)).foregroundStyle(Palette.faint)
                }
            }
            .buttonStyle(.plain)
            if showCriteria {
                Text(m.detail)
                    .font(.system(size: 12)).foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 5) {
                    Image(systemName: "link").font(.system(size: 9))
                    Text(m.resolutionSource).font(.system(size: 11, weight: .medium))
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
                Text("Öngörü Asistanı").font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Palette.text)
                Spacer()
                Text("cihaz üstü").font(.system(size: 9))
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
            SectionHeader(title: "Gerekçeler", sub: "\(list.count) katılımcı neden böyle düşündüğünü yazdı")
            Button { showComposer = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.pencil").font(.system(size: 12, weight: .semibold))
                    Text("Gerekçeni yaz").font(.system(size: 13, weight: .semibold))
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
                Text("Henüz gerekçe yok. İlk yazan sen ol.")
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

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 9) {
                Avatar(initials: initials, seed: thesis.authorName.hashValue, size: 30)
                VStack(alignment: .leading, spacing: 1) {
                    Text(thesis.authorName).font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Palette.text)
                    HStack(spacing: 5) {
                        Text("Skor \(thesis.authorScore)").font(.mono(10, .semibold))
                            .foregroundStyle(thesis.authorScore >= 70 ? Palette.yes : Palette.muted)
                        Text("·").foregroundStyle(Palette.faint)
                        Text(Fmt.relative(thesis.date)).font(.system(size: 10))
                            .foregroundStyle(Palette.faint)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(thesis.side.title).font(.system(size: 9, weight: .bold))
                        .foregroundStyle(thesis.side.color)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(thesis.side.dimColor).clipShape(Capsule())
                    Text("\(Fmt.cents(thesis.priceAtPost))'ten")
                        .font(.mono(9, .medium)).foregroundStyle(Palette.faint)
                }
            }

            Text(thesis.text)
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
                            Text(s.title).font(.system(size: 11))
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

                HStack(spacing: 4) {
                    Image(systemName: "checkmark.shield").font(.system(size: 10))
                    Text("Kalite \(thesis.quality)/100 · \(ThesisAnalyzer.qualityLabel(thesis.quality))")
                        .font(.system(size: 10))
                }
                .foregroundStyle(qualityColor)
                Spacer()
            }
        }
        .card()
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
