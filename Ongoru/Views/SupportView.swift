import SwiftUI
import StoreKit

// MARK: - Satın alma katmanı

/// StoreKit 2 sarmalayıcısı.
///
/// Ürün kimlikleri App Store Connect'te tanımlanana kadar `products` boş
/// döner; ekran bunu gizlemek yerine açıkça söyler. Kod tarafında eksik bir
/// şey yok — ürünler tanımlandığı an çalışır.
@MainActor
final class SupportStore: ObservableObject {

    static let ids = [
        "com.ongoru.tahmin.support.tea",
        "com.ongoru.tahmin.support.coffee",
        "com.ongoru.tahmin.pro.monthly",
        "com.ongoru.tahmin.pro.yearly"
    ]

    @Published var products: [Product] = []
    @Published var loading = true
    @Published var purchasing: String?
    @Published var lastError: String?

    func load() async {
        loading = true
        defer { loading = false }
        do {
            let fetched = try await Product.products(for: Self.ids)
            products = fetched.sorted { $0.price < $1.price }
        } catch {
            lastError = error.localizedDescription
        }
    }

    func purchase(_ product: Product, onSuccess: (String) -> Void) async {
        purchasing = product.id
        defer { purchasing = nil }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    onSuccess(product.id)
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            lastError = error.localizedDescription
            Haptics.error()
        }
    }
}

// MARK: - Ekran

struct SupportView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var shop = SupportStore()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    hero
                    whyNoAds
                    if shop.loading {
                        ProgressView().frame(maxWidth: .infinity).padding(.vertical, 20)
                    } else if shop.products.isEmpty {
                        notConfigured
                    } else {
                        tiers
                    }
                    proPerks
                    freeForever
                    Color.clear.frame(height: 20)
                }
                .padding(16)
            }
            .background(Palette.bg)
            .navigationTitle(L("Öngörü'yü destekle", "Support Öngörü"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("Kapat", "Close")) { dismiss() }
                }
            }
            .task { await shop.load() }
        }
        .presentationBackground(Palette.bg)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 9) {
            Image(systemName: "heart.fill")
                .font(.system(size: 20))
                .foregroundStyle(Palette.no)
                .frame(width: 40, height: 40)
                .background(Palette.no.opacity(0.13))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            Text(L("Reklamsız kalmak istiyoruz", "We'd rather stay ad-free"))
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Palette.text)
            Text(L("Öngörü'nün değeri, kalabalığın beklentisini bozulmadan ölçmesinde. Ekranı reklamla doldurmak hem o ölçümü hem güveni zedeler.",
                   "Öngörü's value is in measuring the crowd's expectations without distortion. Filling the screen with ads damages both that measurement and the trust behind it."))
                .font(.system(size: 13)).foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var whyNoAds: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(L("NEDEN REKLAM DEĞİL", "WHY NOT ADS"))
                .font(.system(size: 9, weight: .bold)).kerning(0.7)
                .foregroundStyle(Palette.faint)
            reason("exclamationmark.shield",
                   L("Politika riski", "Policy risk"),
                   L("Tahmin piyasası arayüzü, para olmasa bile reklam ağlarının kumar politikalarına takılabilir.",
                     "A prediction-market interface can trip ad networks' gambling policies even with no money involved."))
            reason("chart.line.downtrend.xyaxis",
                   L("Düşük getiri", "Weak economics"),
                   L("Bu ölçekte reklam geliri kullanıcı başına kuruşlarla ölçülür; ürünü bozma maliyeti gelirden büyük.",
                     "At this scale ad revenue is pennies per user; the cost of degrading the product exceeds it."))
            reason("eye.slash",
                   L("Veri baskısı", "Data pressure"),
                   L("Reklam, izleme ve profil çıkarma baskısı getirir. Asistanı cihaz üstünde tutma kararıyla çelişir.",
                     "Ads bring pressure to track and profile users, which conflicts with keeping the assistant on-device."))
        }
        .card(padding: 14)
    }

    private func reason(_ icon: String, _ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: icon).font(.system(size: 13))
                .foregroundStyle(Palette.gold).frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.text)
                Text(text).font(.system(size: 12)).foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var notConfigured: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                Image(systemName: "wrench.and.screwdriver").font(.system(size: 13))
                    .foregroundStyle(Palette.gold)
                Text(L("Ürünler henüz tanımlı değil", "Products aren't configured yet"))
                    .font(.system(size: 14, weight: .bold)).foregroundStyle(Palette.text)
            }
            Text(L("Satın alma akışı (StoreKit 2) hazır ama App Store Connect'te ürün tanımlanmadığı için mağaza boş dönüyor. Şu kimliklerle uygulama içi satın alma oluşturulduğunda bu bölüm kendiliğinden dolar:",
                   "The purchase flow (StoreKit 2) is ready, but the store returns nothing because no products are defined in App Store Connect. This section fills itself in once in-app purchases with these IDs exist:"))
                .font(.system(size: 12)).foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: 4) {
                ForEach(SupportStore.ids, id: \.self) { id in
                    Text("· " + id).font(.mono(10)).foregroundStyle(Palette.faint)
                }
            }
            if let err = shop.lastError {
                Text(err).font(.system(size: 11)).foregroundStyle(Palette.no.opacity(0.9))
            }
        }
        .card(padding: 14)
    }

    private var tiers: some View {
        VStack(spacing: 9) {
            ForEach(shop.products, id: \.id) { product in
                Button {
                    Task {
                        await shop.purchase(product) { id in
                            store.recordSupport(tier: id)
                        }
                    }
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(product.displayName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Palette.text)
                            Text(product.description)
                                .font(.system(size: 11)).foregroundStyle(Palette.muted)
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer(minLength: 6)
                        if shop.purchasing == product.id {
                            ProgressView()
                        } else {
                            Text(product.displayPrice)
                                .font(.mono(14, .bold)).foregroundStyle(Palette.accent)
                        }
                    }
                    .card(padding: 14)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var proPerks: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(L("ÖNGÖRÜ PRO'DA NE VAR", "WHAT ÖNGÖRÜ PRO ADDS"))
                .font(.system(size: 9, weight: .bold)).kerning(0.7)
                .foregroundStyle(Palette.faint)
            perk("chart.dots.scatter", L("Derin kalibrasyon analizi",
                                          "Deep calibration analytics"))
            perk("clock.arrow.circlepath", L("Geçmiş fiyat verisini dışa aktarma",
                                             "Export historical price data"))
            perk("bell.badge", L("Fiyat uyarıları", "Price alerts"))
            perk("rosette", L("Ligde destekçi rozeti", "Supporter badge on the leaderboard"))
        }
        .card(padding: 14)
    }

    private func perk(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 12))
                .foregroundStyle(Palette.accent).frame(width: 20)
            Text(text).font(.system(size: 13)).foregroundStyle(Palette.text)
            Spacer()
        }
    }

    private var freeForever: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 7) {
                Image(systemName: "lock.open").font(.system(size: 12))
                    .foregroundStyle(Palette.yes)
                Text(L("Tahmin etmek her zaman ücretsiz", "Forecasting is always free"))
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.text)
            }
            Text(L("Piyasalar, gerekçeler, lig ve Öngörü Skoru destekten bağımsız olarak herkese açık kalır. Destek yalnızca sunucu ve veri maliyetini karşılamak içindir.",
                   "Markets, rationales, the league and the Forecast Score stay open to everyone regardless of support. Support only covers server and data costs."))
                .font(.system(size: 11)).foregroundStyle(Palette.faint)
                .fixedSize(horizontal: false, vertical: true)
        }
        .card(padding: 13)
    }
}
