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
                    themeSection("En çok yükselen beklentiler", snap.rising, up: true)
                    themeSection("En çok gerileyen beklentiler", snap.falling, up: false)
                    moodSection
                    activity
                    Color.clear.frame(height: 20)
                }
                .padding(.horizontal, 14)
                .padding(.top, 4)
            }
            .background(Palette.bg)
            .navigationTitle("Beklenti Endeksi")
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
                Text("Türkiye Kolektif Beklenti Endeksi")
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
                    Text("7 günde").font(.system(size: 9)).foregroundStyle(Palette.faint)
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
                Text("Karamsar").font(.system(size: 9)).foregroundStyle(Palette.no)
                Spacer()
                Text("Kararsız").font(.system(size: 9)).foregroundStyle(Palette.faint)
                Spacer()
                Text("İyimser").font(.system(size: 9)).foregroundStyle(Palette.yes)
            }
            Text("\(Fmt.compact(snap.totalVolume)) işlem ve \(Fmt.compact(snap.totalParticipants)) piyasa katılımı toplulaştırıldı.")
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
            Text("Bu sayılar katılımcı tahminlerinin istatistiksel ortalamasıdır; yatırım tavsiyesi değildir.")
                .font(.system(size: 10)).foregroundStyle(Palette.faint)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    // MARK: Başlıklar

    @ViewBuilder
    private func themeSection(_ title: String, _ themes: [IndexTheme], up: Bool) -> some View {
        if !themes.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: title, sub: "son 7 gündeki değişim, olasılık puanı cinsinden")
                VStack(spacing: 8) {
                    ForEach(themes.prefix(5)) { t in themeRow(t) }
                }
            }
        }
    }

    private func themeRow(_ t: IndexTheme) -> some View {
        Button {
            if let first = t.marketIds.first { path.append(first) }
        } label: {
            HStack(spacing: 11) {
                Text(t.delta >= 0 ? "📈" : "📉").font(.system(size: 15))
                VStack(alignment: .leading, spacing: 3) {
                    Text(t.name).font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Palette.text)
                    Text("kalabalık %\(Int(t.current)) diyor · \(t.marketIds.count) piyasa")
                        .font(.system(size: 10)).foregroundStyle(Palette.faint)
                }
                Spacer(minLength: 6)
                Sparkline(points: Array(t.series.suffix(36)),
                          color: t.delta >= 0 ? Palette.yes : Palette.no, lineWidth: 1.3)
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

    // MARK: Kategori nabzı

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Kategori nabzı", sub: "nerede en çok fikir değişiyor")
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
                            Text("\(m.markets) piyasa · \(Fmt.compact(m.activity)) işlem")
                                .font(.system(size: 10)).foregroundStyle(Palette.faint)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(Fmt.decimal(m.movement) + "p")
                                .font(.mono(12, .bold)).foregroundStyle(Palette.text)
                            Text("ort. hareket").font(.system(size: 9))
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
            StatTile(label: "Aktif piyasa",
                     value: "\(store.markets.filter { $0.status == .open }.count)")
            StatTile(label: "Toplam işlem", value: Fmt.compact(snap.totalVolume))
            StatTile(label: "Katılımcı", value: Fmt.compact(snap.totalParticipants))
            StatTile(label: "Başlık", value: "\(snap.themes.count)")
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
                    block("Fiyat neden olasılık?",
                          "Her piyasada EVET ve HAYIR sözleşmelerinin fiyatı toplamda 100¢ eder. Doğru tahmin eden her sözleşme 100 puana döner. Bu yüzden 63¢, kalabalığın o sonuca %63 ihtimal verdiği anlamına gelir.")
                    block("Fiyatı ne hareket ettiriyor?",
                          "Otomatik piyasa yapıcı (LMSR). Bir tarafa ne kadar çok alım gelirse o tarafın fiyatı o kadar yükselir; büyük likiditeli piyasalarda fiyat daha az oynar.")
                    block("Bileşik endeks nasıl hesaplanıyor?",
                          "Endekse dahil her piyasanın olasılığı iyimserlik yönüne çevrilip ortalanır. “Enflasyon düşecek”, “faiz düşecek”, “borsa yükselecek” gibi başlıklarda yükseliş iyimserlik sayılır; “döviz yükselecek”, “konut fiyatları artacak”, “altın yükselecek”, “işsizlik artacak” başlıklarında ise tersi. 50 nötr çizgidir.")
                    block("Öngörü Skoru nedir?",
                          "Brier skoru: verdiğin olasılık ile gerçekleşen sonuç arasındaki karesel hata. Her şeye %50 demek 0,250 verir. Skor = 50 + 50·(1 − Brier/0,25). Yani 50 yazı tura, 100 kusursuz, 0 sistematik yanlış demektir. Az sayıda tahminde skor 50'ye doğru çekilir.")
                    block("Para nerede?",
                          "Hiçbir yerde. Öngörü'de para yatırma, çekme veya nakde çevirme yoktur; puanlar yalnızca sıralama ve sicil içindir. Toplulaştırılmış beklentiler yatırım tavsiyesi değildir.")
                }
                .padding(18)
            }
            .background(Palette.bg)
            .navigationTitle("Nasıl hesaplanıyor?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
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
