import Foundation

struct IndexTheme: Identifiable, Hashable {
    var id: String { name }
    var name: String
    var symbol: String
    var current: Double      // 0...100 — kalabalığın bu beklentiye verdiği olasılık
    var delta: Double        // son 7 gündeki değişim (puan)
    var marketIds: [String]
    var series: [PricePoint]
    /// Yükselmesi iyimserlik mi demek
    var optimisticWhenUp: Bool
}

struct CategoryMood: Identifiable, Hashable {
    var id: String { category.rawValue }
    var category: Category
    var activity: Int        // toplam işlem
    var movement: Double     // ortalama mutlak 7 günlük hareket
    var markets: Int
}

struct ExpectationSnapshot {
    var composite: Double = 50      // 0–100 iyimserlik bileşiği
    var compositeDelta: Double = 0
    var themes: [IndexTheme] = []
    var moods: [CategoryMood] = []
    var totalVolume: Int = 0
    var totalParticipants: Int = 0

    var rising: [IndexTheme] { themes.filter { $0.delta > 0 }.sorted { $0.delta > $1.delta } }
    var falling: [IndexTheme] { themes.filter { $0.delta < 0 }.sorted { $0.delta < $1.delta } }

    var mood: String {
        switch composite {
        case 62...:   return "İyimser"
        case 54..<62: return "Ölçülü iyimser"
        case 46..<54: return "Kararsız"
        case 38..<46: return "Temkinli"
        default:      return "Karamsar"
        }
    }
}

/// Kullanıcıların fiyatladığı olasılıkları toplulaştırıp
/// "Türkiye geleceği nasıl görüyor?" sorusuna sayısal cevap üretir.
///
/// Bu bir yatırım tavsiyesi değil; katılımcı tahminlerinin istatistiksel
/// ortalamasıdır.
enum ExpectationIndexEngine {

    static let window: TimeInterval = 7 * 24 * 3600

    static func snapshot(markets: [Market]) -> ExpectationSnapshot {
        var snap = ExpectationSnapshot()
        let live = markets.filter { $0.status != .resolved }

        snap.totalVolume = markets.reduce(0) { $0 + $1.volume }
        snap.totalParticipants = markets.reduce(0) { $0 + $1.participants }

        // Başlıklar
        let grouped = Dictionary(grouping: live.filter { $0.indexTheme != nil }) { $0.indexTheme! }
        snap.themes = grouped.map { name, group in
            let current = group.map(\.priceYes).reduce(0, +) / Double(group.count) * 100
            let delta = group.map { $0.changeSince(window) }.reduce(0, +) / Double(group.count)
            let inverted = group.first?.indexInverted ?? false
            return IndexTheme(
                name: name,
                symbol: group.first?.category.icon ?? "circle",
                current: current,
                delta: delta,
                marketIds: group.map(\.id),
                series: mergedSeries(group),
                optimisticWhenUp: !inverted
            )
        }
        .sorted { abs($0.delta) > abs($1.delta) }

        // Bileşik iyimserlik: ters başlıklarda (1 − p) katkı verir
        let contributions = live.compactMap { m -> Double? in
            guard m.indexTheme != nil else { return nil }
            return m.indexInverted ? (1 - m.priceYes) : m.priceYes
        }
        if !contributions.isEmpty {
            snap.composite = contributions.reduce(0, +) / Double(contributions.count) * 100
        }
        let deltas = live.compactMap { m -> Double? in
            guard m.indexTheme != nil else { return nil }
            let d = m.changeSince(window)
            return m.indexInverted ? -d : d
        }
        if !deltas.isEmpty {
            snap.compositeDelta = deltas.reduce(0, +) / Double(deltas.count)
        }

        // Kategori nabzı
        snap.moods = Category.allCases.compactMap { cat in
            let subset = live.filter { $0.category == cat }
            guard !subset.isEmpty else { return nil }
            return CategoryMood(
                category: cat,
                activity: subset.reduce(0) { $0 + $1.volume },
                movement: subset.map { abs($0.changeSince(window)) }.reduce(0, +) / Double(subset.count),
                markets: subset.count
            )
        }
        .sorted { $0.activity > $1.activity }

        return snap
    }

    /// Bir başlıktaki piyasaların fiyat serilerini ortak zaman ızgarasında birleştirir.
    private static func mergedSeries(_ markets: [Market]) -> [PricePoint] {
        guard let longest = markets.max(by: { $0.history.count < $1.history.count }) else { return [] }
        return longest.history.map { point in
            let values = markets.compactMap { m -> Double? in
                m.history.last(where: { $0.t <= point.t })?.p ?? m.history.first?.p
            }
            let avg = values.isEmpty ? point.p : values.reduce(0, +) / Double(values.count)
            return PricePoint(t: point.t, p: avg)
        }
    }
}
