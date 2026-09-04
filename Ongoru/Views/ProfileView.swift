import SwiftUI
import Charts

struct ProfileView: View {
    @EnvironmentObject var store: AppStore
    @State private var showSettings = false
    @State private var showResolver = false
    @State private var showSupport = false

    private var card: ScoreCard { store.scoreCard }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    scoreBlock
                    statGrid
                    if !card.categories.isEmpty { categoryBreakdown }
                    if card.shortTerm.n > 0 || card.longTerm.n > 0 { horizonBlock }
                    if card.calibration.count >= 2 { calibrationBlock }
                    insights
                    myProposals
                    myTheses
                    supportBanner
                    Color.clear.frame(height: 20)
                }
                .padding(.horizontal, 14)
                .padding(.top, 4)
            }
            .background(Palette.bg)
            .navigationTitle(L("Sicil", "Record"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape").font(.system(size: 15))
                    }
                    .accessibilityLabel(L("Ayarlar", "Settings"))
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsSheet(showResolver: $showResolver, showSupport: $showSupport)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showResolver) { ResolverSheet().environmentObject(store) }
            .sheet(isPresented: $showSupport) { SupportView().environmentObject(store) }
        }
    }

    // MARK: Başlık

    private var header: some View {
        HStack(spacing: 13) {
            Avatar(initials: store.me.initials, seed: 0, size: 52)
            VStack(alignment: .leading, spacing: 3) {
                Text(store.me.name).font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Palette.text)
                HStack(spacing: 6) {
                    Text("@\(store.me.handle)").font(.system(size: 12))
                        .foregroundStyle(Palette.faint)
                    if let provider = store.account?.provider {
                        HStack(spacing: 3) {
                            Image(systemName: provider.icon).font(.system(size: 8))
                            Text(provider.label).font(.system(size: 9))
                        }
                        .foregroundStyle(Palette.faint)
                    }
                }
                HStack(spacing: 5) {
                    Text(card.grade).font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Palette.bg)
                        .padding(.horizontal, 7).padding(.vertical, 2)
                        .background(Palette.accent).clipShape(Capsule())
                    Text(L("Ligde \(store.myRank). sıra", "Rank \(store.myRank) in the league"))
                        .font(.system(size: 10)).foregroundStyle(Palette.muted)
                    if store.state.supporterTier != nil {
                        Image(systemName: "heart.fill").font(.system(size: 9))
                            .foregroundStyle(Palette.no)
                    }
                }
            }
            Spacer()
        }
        .card(padding: 15)
    }

    // MARK: Skor

    private var scoreBlock: some View {
        VStack(spacing: 14) {
            HStack(spacing: 18) {
                ScoreRing(score: card.score, size: 112, label: L("ÖNGÖRÜ", "FORECAST"))
                VStack(alignment: .leading, spacing: 9) {
                    Text(L("Son \(card.resolved) tahminde", "Across \(card.resolved) resolved"))
                        .font(.system(size: 12)).foregroundStyle(Palette.muted)
                    tally(L("\(card.correct) doğru", "\(card.correct) right"), Palette.yes)
                    tally(L("\(card.wrong) yanlış", "\(card.wrong) wrong"), Palette.no)
                    tally(L("\(Fmt.pctInt(Int(card.accuracy * 100))) isabet",
                            "\(Fmt.pctInt(Int(card.accuracy * 100))) accurate"), Palette.text)
                }
                Spacer()
            }
            Text(card.resolved > 0
                 ? L("Skor puanını değil kalibrasyonunu ölçer: %70 dediğin şeylerin gerçekten %70'i olduysa yüksek çıkar.",
                     "The score measures calibration, not points: it is high when the things you called at 70% happened 70% of the time.")
                 : L("Henüz sonuçlanmış tahminin yok. İlk piyasan kapandığında skorun oluşmaya başlar.",
                     "No resolved predictions yet. Your score starts forming once your first market closes."))
                .font(.system(size: 11)).foregroundStyle(Palette.faint)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .card(padding: 16)
    }

    private func tally(_ text: String, _ color: Color) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(text).font(.mono(13, .semibold)).foregroundStyle(Palette.text)
        }
    }

    private var statGrid: some View {
        HStack(spacing: 0) {
            StatTile(label: L("Brier", "Brier"), value: Fmt.decimal(card.brier, decimals: 3),
                     accent: card.brier < 0.25 ? Palette.yes : Palette.no,
                     sub: L("yazı tura 0,250", "coin flip 0.250"))
            StatTile(label: L("Seri", "Streak"), value: "\(card.streak)", accent: Palette.gold,
                     sub: L("doğru üst üste", "right in a row"))
            StatTile(label: L("Net kâr", "Net gain"), value: Fmt.signed(card.netProfit),
                     accent: card.netProfit >= 0 ? Palette.yes : Palette.no,
                     sub: L("sonuçlananlardan", "from resolved"))
        }
        .card()
    }

    // MARK: Kategori kırılımı

    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: L("Kategori kırılımı", "By category"),
                          sub: L("hangi konuda gerçekten iyisin", "where you're genuinely good"))
            VStack(spacing: 10) {
                ForEach(card.categories) { s in
                    VStack(spacing: 5) {
                        HStack(spacing: 7) {
                            Image(systemName: s.category.icon).font(.system(size: 10))
                                .foregroundStyle(s.category.tint).frame(width: 16)
                            Text(s.category.title).font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Palette.text)
                            Spacer()
                            Text("\(s.correct)/\(s.resolved)").font(.mono(11))
                                .foregroundStyle(Palette.faint)
                            Text("\(s.score)").font(.mono(13, .bold))
                                .foregroundStyle(scoreColor(s.score))
                                .frame(width: 28, alignment: .trailing)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Palette.stroke)
                                Capsule().fill(scoreColor(s.score))
                                    .frame(width: max(3, geo.size.width * CGFloat(s.score) / 100))
                            }
                        }
                        .frame(height: 5)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .card(padding: 14)
        }
    }

    private func scoreColor(_ s: Int) -> Color {
        switch s {
        case 68...: return Palette.yes
        case 52..<68: return Palette.gold
        default: return Palette.no
        }
    }

    // MARK: Vade

    private var horizonBlock: some View {
        HStack(spacing: 0) {
            StatTile(label: L("Kısa vade (≤30g)", "Short (≤30d)"),
                     value: card.shortTerm.n > 0
                        ? Fmt.pctInt(Int(card.shortTerm.accuracy * 100)) : "—",
                     accent: Palette.text,
                     sub: L("\(card.shortTerm.n) tahmin", "\(card.shortTerm.n) calls"))
            StatTile(label: L("Uzun vade (>30g)", "Long (>30d)"),
                     value: card.longTerm.n > 0
                        ? Fmt.pctInt(Int(card.longTerm.accuracy * 100)) : "—",
                     accent: Palette.text,
                     sub: L("\(card.longTerm.n) tahmin", "\(card.longTerm.n) calls"))
            StatTile(label: L("Kalabalığa karşı", "Contrarian"),
                     value: card.contrarian.n > 0
                        ? "\(card.contrarian.correct)/\(card.contrarian.n)" : "—",
                     accent: Palette.gold,
                     sub: L("45¢ altı girişler", "entries below 45¢"))
        }
        .card()
    }

    // MARK: Kalibrasyon

    private var calibrationBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: L("Kalibrasyon", "Calibration"),
                          sub: L("“%70” dediklerinin gerçekten %70'i oldu mu?",
                                 "did the things you called at 70% happen 70% of the time?"))
            VStack(spacing: 10) {
                Chart {
                    ForEach(card.calibration) { b in
                        BarMark(x: .value("", b.label), y: .value("", b.hitRate * 100))
                            .foregroundStyle(Palette.accent.opacity(0.85))
                            .cornerRadius(3)
                    }
                    ForEach(card.calibration) { b in
                        PointMark(x: .value("", b.label), y: .value("", b.midpoint * 100))
                            .foregroundStyle(Palette.gold)
                            .symbol(.diamond)
                            .symbolSize(70)
                    }
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [0, 50, 100]) { v in
                        AxisGridLine().foregroundStyle(Palette.stroke.opacity(0.4))
                        AxisValueLabel {
                            if let n = v.as(Int.self) {
                                Text(Fmt.pctInt(n)).font(.system(size: 9))
                                    .foregroundStyle(Palette.faint)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel().font(.system(size: 9)).foregroundStyle(Palette.faint)
                    }
                }
                .frame(height: 140)

                HStack(spacing: 14) {
                    legend(Palette.accent, L("Gerçekleşme oranı", "Actual rate"))
                    legend(Palette.gold, L("Senin dediğin", "What you said"))
                    Spacer()
                }
                Text(biasText)
                    .font(.system(size: 11)).foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .card(padding: 14)
        }
    }

    private var biasText: String {
        let points = Int(abs(card.bias) * 100)
        if card.bias > 0.05 {
            return L("Ortalama olarak gerçekleşenden \(points) puan fazla iyimsersin.",
                     "On average you run \(points) points more optimistic than reality.")
        } else if card.bias < -0.05 {
            return L("Ortalama olarak gerçekleşenden \(points) puan fazla temkinlisin.",
                     "On average you run \(points) points more cautious than reality.")
        }
        return L("Verdiğin olasılıklar gerçekleşmeyle büyük ölçüde örtüşüyor.",
                 "Your stated probabilities line up closely with what happened.")
    }

    private func legend(_ color: Color, _ text: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 9, height: 9)
            Text(text).font(.system(size: 10)).foregroundStyle(Palette.faint)
        }
    }

    // MARK: Asistan

    private var insights: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles").font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Palette.accent)
                Text(L("Sicil analizi", "Record analysis")).font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Palette.text)
                Spacer()
                Text(L("cihaz üstü", "on-device")).font(.system(size: 9))
                    .foregroundStyle(Palette.faint)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Palette.surfaceHigh).clipShape(Capsule())
            }
            ForEach(store.trackRecordInsights()) { InsightRow(insight: $0) }
        }
        .card(padding: 15)
    }

    // MARK: Önerdiğim piyasalar

    @ViewBuilder
    private var myProposals: some View {
        if !store.proposals.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: L("Önerdiğim piyasalar", "Markets I proposed"),
                              sub: L("\(store.proposals.count) öneri", "\(store.proposals.count) proposals"))
                ForEach(store.proposals) { p in
                    VStack(alignment: .leading, spacing: 7) {
                        HStack(spacing: 6) {
                            Text(p.status.label)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(p.status.color)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(p.status.color.opacity(0.13))
                                .clipShape(Capsule())
                            CategoryBadge(category: p.category)
                            Spacer()
                            Text(Fmt.relative(p.createdAt)).font(.system(size: 10))
                                .foregroundStyle(Palette.faint)
                        }
                        Text(p.question).font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Palette.text)
                            .fixedSize(horizontal: false, vertical: true)
                        if let note = p.moderationNote {
                            Text(note).font(.system(size: 11))
                                .foregroundStyle(p.status.color)
                        }
                    }
                    .card(padding: 13)
                }
            }
        }
    }

    // MARK: Gerekçelerim

    @ViewBuilder
    private var myTheses: some View {
        if !store.myTheses.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: L("Gerekçelerim", "My rationales"),
                              sub: L("\(store.myTheses.count) yazı", "\(store.myTheses.count) posts"))
                ForEach(store.myTheses) { t in
                    VStack(alignment: .leading, spacing: 7) {
                        HStack(spacing: 6) {
                            Text(t.side.title).font(.system(size: 9, weight: .bold))
                                .foregroundStyle(t.side.color)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(t.side.dimColor).clipShape(Capsule())
                            Text(Fmt.relative(t.date)).font(.system(size: 10))
                                .foregroundStyle(Palette.faint)
                            Spacer()
                            Text(L("Kalite \(t.quality)/100", "Quality \(t.quality)/100"))
                                .font(.mono(10)).foregroundStyle(Palette.muted)
                        }
                        if let m = store.market(id: t.marketId) {
                            Text(m.question.s).font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Palette.muted).lineLimit(2)
                        }
                        Text(t.text.s).font(.system(size: 12))
                            .foregroundStyle(Palette.text.opacity(0.85)).lineLimit(3)
                    }
                    .card(padding: 13)
                }
            }
        }
    }

    private var supportBanner: some View {
        Button {
            Haptics.tap()
            showSupport = true
        } label: {
            HStack(spacing: 11) {
                Image(systemName: "heart.fill").font(.system(size: 14))
                    .foregroundStyle(Palette.no)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("Öngörü reklamsız", "Öngörü runs ad-free"))
                        .font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.text)
                    Text(L("Nasıl ayakta kaldığını gör", "See how it stays that way"))
                        .font(.system(size: 11)).foregroundStyle(Palette.faint)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Palette.faint)
            }
            .card(padding: 14)
        }
        .buttonStyle(.plain)
    }
}
