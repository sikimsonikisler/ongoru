import SwiftUI

struct IndexView: View {
    @EnvironmentObject var store: AppStore
    @State private var showMethod = false
    @State private var path: [String] = []

    private var snap: ExpectationSnapshot { store.index }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 16) {
                    composite
                    disclaimer
                    themeSection(L("En çok yükselen beklentiler", "Fastest rising expectations"), snap.rising, up: true)
                    themeSection(L("En çok gerileyen beklentiler", "Fastest falling expectations"), snap.falling, up: false)
                    moodSection
                    activity
                    Color.clear.frame(height: 20)
                }
                .padding(.horizontal, 14)
                .padding(.top, 4)
            }
            .background(Palette.bg)
            .navigationTitle(L("Beklenti Endeksi", "Expectations Index"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showMethod = true } label: {
                        Image(systemName: "info.circle").font(.system(size: 15))
                    }
                }
            }
            .sheet(isPresented: $showMethod) { MethodSheet() }
            .navigationDestination(for: String.self) { MarketDetailView(marketId: $0) }
        }
    }

    // MARK: Bileşik endeks

    private var composite: some View {
        VStack(spacing: 14) {
            HStack(spacing: 7) {
                Text("🇹🇷").font(.system(size: 15))
                Text(L("Türkiye Kolektif Beklenti Endeksi", "Türkiye Collective Expectations Index"))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Palette.text)
                Spacer()
            }
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(Fmt.decimal(snap.composite))
                    .font(.mono(44, .bold))
                    .foregroundStyle(gaugeColor)
                    .contentTransition(.numericText())
                VStack(alignment: .leading, spacing: 2) {
                    ChangeTag(value: snap.compositeDelta)
                    Text(L("7 günde", "over 7 days")).font(.system(size: 9)).foregroundStyle(Palette.faint)
                }
                Spacer()
                Text(snap.mood)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(gaugeColor)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(gaugeColor.opacity(0.13))
                    .clipShape(Capsule())
            }
            gauge
            HStack {
                Text(L("Karamsar", "Pessimistic")).font(.system(size: 9)).foregroundStyle(Palette.no)
                Spacer()
                Text(L("Kararsız", "Undecided")).font(.system(size: 9)).foregroundStyle(Palette.faint)
                Spacer()
                Text(L("İyimser", "Optimistic")).font(.system(size: 9)).foregroundStyle(Palette.yes)
            }
            Text(L("\(Fmt.compact(snap.totalVolume)) işlem ve \(Fmt.compact(snap.totalParticipants)) piyasa katılımı toplulaştırıldı.",
                   "Aggregated from \(Fmt.compact(snap.totalVolume)) trades and \(Fmt.compact(snap.totalParticipants)) market participations."))
                .font(.system(size: 10)).foregroundStyle(Palette.faint)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .card(padding: 16)
    }

    private var gauge: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(LinearGradient(colors: [Palette.no.opacity(0.55), Palette.gold.opacity(0.5),
                                                  Palette.yes.opacity(0.6)],
                                         startPoint: .leading, endPoint: .trailing))
                Capsule()
                    .fill(Palette.text)
                    .frame(width: 3, height: 22)
                    .offset(x: max(0, min(geo.size.width - 3, geo.size.width * snap.composite / 100)))
                    .animation(.easeOut(duration: 0.5), value: snap.composite)
            }
        }
        .frame(height: 10)
    }

    private var gaugeColor: Color {
        switch snap.composite {
        case 56...: return Palette.yes
        case 44..<56: return Palette.gold
        default: return Palette.no
        }
    }

    private var disclaimer: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.circle").font(.system(size: 11))
                .foregroundStyle(Palette.faint)
            Text(L("Bu sayılar katılımcı tahminlerinin istatistiksel ortalamasıdır; yatırım tavsiyesi değildir.",
                   "These figures are a statistical average of participant forecasts, not investment advice."))
                .font(.system(size: 10)).foregroundStyle(Palette.faint)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    // MARK: Başlıklar

    @ViewBuilder
    private func themeSection(_ title: String, _ themes: [TopicReading], up: Bool) -> some View {
        if !themes.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: title,
                              sub: L("son 7 gündeki değişim, olasılık puanı cinsinden",
                                     "change over the last 7 days, in probability points"))
                VStack(spacing: 8) {
                    ForEach(themes.prefix(5)) { t in themeRow(t) }
                }
            }
        }
    }

    private func themeRow(_ t: TopicReading) -> some View {
        Button {
            if let first = t.marketIds.first { path.append(first) }
        } label: {
            HStack(spacing: 11) {
                Text(t.delta >= 0 ? "📈" : "📉").font(.system(size: 15))
                VStack(alignment: .leading, spacing: 3) {
                    Text(t.name).font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Palette.text)
                    Text(L("kalabalık \(Fmt.pctInt(Int(t.current))) diyor · \(t.marketIds.count) piyasa",
                           "crowd says \(Fmt.pctInt(Int(t.current))) · \(t.marketIds.count) market\(t.marketIds.count == 1 ? "" : "s")"))
                        .font(.system(size: 10)).foregroundStyle(Palette.faint)
                }
                Spacer(minLength: 6)
                Sparkline(points: Array(t.series.suffix(36)),
                          color: seriesTrend(t) >= 0 ? Palette.yes : Palette.no, lineWidth: 1.3)
                    .frame(width: 54, height: 22)
                Text(Fmt.signedDecimal(t.delta, decimals: 0) + "p")
                    .font(.mono(13, .bold))
                    .foregroundStyle(t.delta >= 0 ? Palette.yes : Palette.no)
                    .frame(width: 52, alignment: .trailing)
            }
            .card(padding: 12)
        }
        .buttonStyle(.plain)
    }

    private func seriesTrend(_ t: TopicReading) -> Double {
        let slice = Array(t.series.suffix(36))
        guard let first = slice.first, let last = slice.last else { return t.delta }
        return last.p - first.p
    }

    // MARK: Kategori nabzı

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: L("Kategori nabzı", "Category pulse"),
                          sub: L("nerede en çok fikir değişiyor", "where opinion is moving most"))
            VStack(spacing: 8) {
                ForEach(snap.moods) { m in
                    HStack(spacing: 10) {
                        Image(systemName: m.category.icon)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(m.category.tint)
                            .frame(width: 28, height: 28)
                            .background(m.category.tint.opacity(0.13))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(m.category.title).font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Palette.text)
                            Text(L("\(m.markets) piyasa · \(Fmt.compact(m.activity)) işlem",
                                   "\(m.markets) markets · \(Fmt.compact(m.activity)) trades"))
                                .font(.system(size: 10)).foregroundStyle(Palette.faint)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(Fmt.decimal(m.movement) + "p")
                                .font(.mono(12, .bold)).foregroundStyle(Palette.text)
                            Text(L("ort. hareket", "avg move")).font(.system(size: 9))
                                .foregroundStyle(Palette.faint)
                        }
                    }
                    .card(padding: 11)
                }
            }
        }
    }

    private var activity: some View {
        HStack(spacing: 0) {
            StatTile(label: L("Aktif piyasa", "Active markets"),
                     value: "\(store.markets.filter { $0.status == .open }.count)")
            StatTile(label: L("Toplam işlem", "Total trades"), value: Fmt.compact(snap.totalVolume))
            StatTile(label: L("Katılımcı", "Participants"), value: Fmt.compact(snap.totalParticipants))
            StatTile(label: L("Başlık", "Topics"), value: "\(snap.topics.count)")
        }
        .card()
    }
}

// MARK: - Yöntem

struct MethodSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    block(L("Fiyat neden olasılık?", "Why is price a probability?"),
                          L("Her piyasada EVET ve HAYIR sözleşmelerinin fiyatı toplamda 100¢ eder. Doğru tahmin eden her sözleşme 100 puana döner. Bu yüzden 63¢, kalabalığın o sonuca %63 ihtimal verdiği anlamına gelir.",
                            "In every market the YES and NO contracts add up to 100¢, and each winning contract pays 100 points. So 63¢ means the crowd puts the outcome at 63%."))
                    block(L("Fiyatı ne hareket ettiriyor?", "What moves the price?"),
                          L("Otomatik piyasa yapıcı (LMSR). Bir tarafa ne kadar çok alım gelirse o tarafın fiyatı o kadar yükselir; büyük likiditeli piyasalarda fiyat daha az oynar.",
                            "An automated market maker (LMSR). The more buying on one side, the higher that side's price; markets with deeper liquidity move less."))
                    block(L("Bileşik endeks nasıl hesaplanıyor?", "How is the composite computed?"),
                          L("Endekse dahil her piyasanın olasılığı iyimserlik yönüne çevrilip ortalanır. “Enflasyon düşecek”, “faiz düşecek”, “borsa yükselecek” gibi başlıklarda yükseliş iyimserlik sayılır; “döviz yükselecek”, “konut fiyatları artacak”, “altın yükselecek”, “işsizlik artacak” başlıklarında ise tersi. 50 nötr çizgidir.",
                            "Each included market's probability is turned toward the optimism direction and averaged. Topics like “inflation will fall”, “rates will fall” and “equities will rise” count upward moves as optimism; “FX will rise”, “housing prices will rise”, “gold will rise” and “unemployment will rise” count the opposite. 50 is the neutral line."))
                    block(L("Öngörü Skoru nedir?", "What is the Forecast Score?"),
                          L("Brier skoru: verdiğin olasılık ile gerçekleşen sonuç arasındaki karesel hata. Her şeye %50 demek 0,250 verir. Skor = 50 + 50·(1 − Brier/0,25). Yani 50 yazı tura, 100 kusursuz, 0 sistematik yanlış demektir. Az sayıda tahminde skor 50'ye doğru çekilir.",
                            "The Brier score: the squared error between your stated probability and the outcome. Saying 50% to everything yields 0.250. Score = 50 + 50·(1 − Brier/0.25). So 50 is a coin flip, 100 is perfect and 0 is systematically wrong. With few predictions the score is pulled toward 50."))
                    block(L("Para nerede?", "Where's the money?"),
                          L("Hiçbir yerde. Öngörü'de para yatırma, çekme veya nakde çevirme yoktur; puanlar yalnızca sıralama ve sicil içindir. Toplulaştırılmış beklentiler yatırım tavsiyesi değildir.",
                            "Nowhere. There are no deposits, withdrawals or cash-outs on Öngörü; points exist only for ranking and record-keeping. Aggregated expectations are not investment advice."))
                }
                .padding(18)
            }
            .background(Palette.bg)
            .navigationTitle(L("Nasıl hesaplanıyor?", "How it's calculated"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("Kapat", "Close")) { dismiss() }
                }
            }
        }
        .presentationBackground(Palette.bg)
    }

    private func block(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 14, weight: .bold)).foregroundStyle(Palette.text)
            Text(text).font(.system(size: 13)).foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
