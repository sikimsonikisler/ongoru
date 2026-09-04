import SwiftUI
import Charts

struct ProfileView: View {
    @EnvironmentObject var store: AppStore
    @State private var showSettings = false
    @State private var showResolver = false

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
                    myTheses
                    Color.clear.frame(height: 20)
                }
                .padding(.horizontal, 14)
                .padding(.top, 4)
            }
            .background(Palette.bg)
            .navigationTitle("Sicil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape").font(.system(size: 15))
                    }
                }
            }
            .sheet(isPresented: $showSettings) { SettingsSheet(showResolver: $showResolver) }
            .sheet(isPresented: $showResolver) { ResolverSheet() }
        }
    }

    // MARK: Başlık

    private var header: some View {
        HStack(spacing: 13) {
            Avatar(initials: store.me.initials, seed: 0, size: 52)
            VStack(alignment: .leading, spacing: 3) {
                Text(store.me.name).font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Palette.text)
                Text("@\(store.me.handle)").font(.system(size: 12))
                    .foregroundStyle(Palette.faint)
                HStack(spacing: 5) {
                    Text(card.grade).font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Palette.bg)
                        .padding(.horizontal, 7).padding(.vertical, 2)
                        .background(Palette.accent).clipShape(Capsule())
                    Text("Ligde \(store.myRank). sıra").font(.system(size: 10))
                        .foregroundStyle(Palette.muted)
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
                ScoreRing(score: card.score, size: 112, label: "ÖNGÖRÜ")
                VStack(alignment: .leading, spacing: 9) {
                    Text("Son \(card.resolved) tahminde")
                        .font(.system(size: 12)).foregroundStyle(Palette.muted)
                    tally("\(card.correct) doğru", Palette.yes)
                    tally("\(card.wrong) yanlış", Palette.no)
                    tally("%\(Int(card.accuracy * 100)) isabet", Palette.text)
                }
                Spacer()
            }
            Text(card.resolved > 0
                 ? "Skor puanını değil kalibrasyonunu ölçer: %70 dediğin şeylerin gerçekten %70'i olduysa yüksek çıkar."
                 : "Henüz sonuçlanmış tahminin yok. İlk piyasan kapandığında skorun oluşmaya başlar.")
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
            StatTile(label: "Brier", value: Fmt.decimal(card.brier, decimals: 3),
                     accent: card.brier < 0.25 ? Palette.yes : Palette.no, sub: "yazı tura 0,250")
            StatTile(label: "Seri", value: "\(card.streak)", accent: Palette.gold, sub: "doğru üst üste")
            StatTile(label: "Net kâr", value: Fmt.signed(card.netProfit),
                     accent: card.netProfit >= 0 ? Palette.yes : Palette.no, sub: "sonuçlananlardan")
        }
        .card()
    }

    // MARK: Kategori kırılımı

    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Kategori kırılımı", sub: "hangi konuda gerçekten iyisin")
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
            StatTile(label: "Kısa vade (≤30g)",
                     value: card.shortTerm.n > 0 ? "%\(Int(card.shortTerm.accuracy * 100))" : "—",
                     accent: Palette.text, sub: "\(card.shortTerm.n) tahmin")
            StatTile(label: "Uzun vade (>30g)",
                     value: card.longTerm.n > 0 ? "%\(Int(card.longTerm.accuracy * 100))" : "—",
                     accent: Palette.text, sub: "\(card.longTerm.n) tahmin")
            StatTile(label: "Kalabalığa karşı",
                     value: card.contrarian.n > 0 ? "\(card.contrarian.correct)/\(card.contrarian.n)" : "—",
                     accent: Palette.gold, sub: "45¢ altı girişler")
        }
        .card()
    }

    // MARK: Kalibrasyon

    private var calibrationBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Kalibrasyon", sub: "“%70” dediklerinin gerçekten %70'i oldu mu?")
            VStack(spacing: 10) {
                Chart {
                    ForEach(card.calibration) { b in
                        BarMark(x: .value("Dilim", b.label),
                                y: .value("Gerçekleşme", b.hitRate * 100))
                            .foregroundStyle(Palette.accent.opacity(0.85))
                            .cornerRadius(3)
                    }
                    ForEach(card.calibration) { b in
                        PointMark(x: .value("Dilim", b.label),
                                  y: .value("Söylenen", b.midpoint * 100))
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
                                Text("%\(n)").font(.system(size: 9)).foregroundStyle(Palette.faint)
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
                    legend(Palette.accent, "Gerçekleşme oranı")
                    legend(Palette.gold, "Senin dediğin")
                    Spacer()
                }
                Text(card.bias > 0.05
                     ? "Ortalama olarak gerçekleşenden \(Int(card.bias * 100)) puan fazla iyimsersin."
                     : (card.bias < -0.05
                        ? "Ortalama olarak gerçekleşenden \(Int(abs(card.bias) * 100)) puan fazla temkinlisin."
                        : "Verdiğin olasılıklar gerçekleşmeyle büyük ölçüde örtüşüyor."))
                    .font(.system(size: 11)).foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .card(padding: 14)
        }
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
                Text("Sicil analizi").font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Palette.text)
                Spacer()
                Text("cihaz üstü").font(.system(size: 9)).foregroundStyle(Palette.faint)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Palette.surfaceHigh).clipShape(Capsule())
            }
            ForEach(store.trackRecordInsights()) { InsightRow(insight: $0) }
        }
        .card(padding: 15)
    }

    // MARK: Gerekçelerim

    @ViewBuilder
    private var myTheses: some View {
        if !store.myTheses.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Gerekçelerim", sub: "\(store.myTheses.count) yazı")
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
                            Text("Kalite \(t.quality)/100").font(.mono(10))
                                .foregroundStyle(Palette.muted)
                        }
                        if let m = store.market(id: t.marketId) {
                            Text(m.question).font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Palette.muted).lineLimit(2)
                        }
                        Text(t.text).font(.system(size: 12))
                            .foregroundStyle(Palette.text.opacity(0.85)).lineLimit(3)
                    }
                    .card(padding: 13)
                }
            }
        }
    }
}

// MARK: - Ayarlar

struct SettingsSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Binding var showResolver: Bool
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    group("Demo araçları") {
                        actionRow("bolt.badge.clock", "Bir piyasayı şimdi sonuçlandır",
                                  "Sonuç açıklandığında ödemenin ve sicilin nasıl güncellendiğini gör.") {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showResolver = true }
                        }
                    }
                    group("Hesap") {
                        actionRow("arrow.counterclockwise", "Her şeyi sıfırla",
                                  "Puanlar, pozisyonlar ve sicil silinir; piyasalar yeniden kurulur.",
                                  tint: Palette.no) { confirmReset = true }
                    }
                    group("Öngörü hakkında") {
                        infoRow("Bu uygulamada gerçek para yoktur. Para yatırma, çekme veya nakde çevirme yoktur; puanlar yalnızca sıralama ve sicil içindir.")
                        infoRow("Toplulaştırılmış beklentiler yatırım tavsiyesi değildir.")
                        infoRow("Öngörü Asistanı tamamen cihaz üstünde, kural tabanlı çalışır; hiçbir veri dışarı gönderilmez.")
                        infoRow("Piyasa fiyatları LMSR otomatik piyasa yapıcısıyla belirlenir; demo kalabalığı fiyatları canlı tutar.")
                    }
                }
                .padding(16)
            }
            .background(Palette.bg)
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Kapat") { dismiss() } }
            }
            .alert("Her şey sıfırlansın mı?", isPresented: $confirmReset) {
                Button("Vazgeç", role: .cancel) {}
                Button("Sıfırla", role: .destructive) { store.resetEverything(); dismiss() }
            } message: {
                Text("Puanların, pozisyonların ve sicilin silinecek.")
            }
        }
        .presentationBackground(Palette.bg)
    }

    private func group<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title.uppercased()).font(.system(size: 9, weight: .bold)).kerning(0.7)
                .foregroundStyle(Palette.faint)
            content()
        }
    }

    private func actionRow(_ icon: String, _ title: String, _ sub: String,
                           tint: Color = Palette.accent, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 11) {
                Image(systemName: icon).font(.system(size: 14)).foregroundStyle(tint).frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.text)
                    Text(sub).font(.system(size: 11)).foregroundStyle(Palette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Palette.faint)
            }
            .card(padding: 13)
        }
        .buttonStyle(.plain)
    }

    private func infoRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle().fill(Palette.faint).frame(width: 4, height: 4).padding(.top, 6)
            Text(text).font(.system(size: 11)).foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Demo çözümleyici

struct ResolverSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    private var candidates: [Market] {
        store.markets.filter { $0.status == .open }
            .sorted { $0.closeDate < $1.closeDate }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Bir piyasayı seçip sonucu belirle. Pozisyonun varsa ödeme yapılır ve sicilin güncellenir.")
                        .font(.system(size: 12)).foregroundStyle(Palette.muted)
                        .fixedSize(horizontal: false, vertical: true)

                    ForEach(candidates.prefix(12)) { m in
                        VStack(alignment: .leading, spacing: 9) {
                            HStack {
                                CategoryBadge(category: m.category)
                                Spacer()
                                if store.position(for: m.id) != nil {
                                    Text("pozisyonun var").font(.system(size: 9, weight: .semibold))
                                        .foregroundStyle(Palette.gold)
                                }
                            }
                            Text(m.question).font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Palette.text)
                                .fixedSize(horizontal: false, vertical: true)
                            HStack(spacing: 8) {
                                ForEach(Side.allCases, id: \.self) { s in
                                    Button {
                                        store.forceResolve(marketId: m.id, outcome: s == .yes)
                                        dismiss()
                                    } label: {
                                        Text("Sonuç: \(s.title)")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(s.color)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 9)
                                            .background(s.dimColor)
                                            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .card(padding: 13)
                    }
                }
                .padding(16)
            }
            .background(Palette.bg)
            .navigationTitle("Piyasa sonuçlandır")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Kapat") { dismiss() } } }
        }
        .presentationBackground(Palette.bg)
    }
}
