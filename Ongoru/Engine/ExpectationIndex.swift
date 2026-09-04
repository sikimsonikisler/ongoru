import Foundation

struct TopicReading: Identifiable, Hashable {
    var id: String { topic.rawValue }
    var topic: IndexTopic
    var current: Double      // 0...100 — kalabalığın bu beklentiye verdiği olasılık
    var delta: Double        // son 7 gündeki değişim (olasılık puanı)
    var marketIds: [String]
    var series: [PricePoint]

    var name: String { topic.title }
    var optimisticWhenUp: Bool { topic.optimisticWhenUp }
}

struct CategoryMood: Identifiable, Hashable {
    var id: String { category.rawValue }
    var category: Category
    var activity: Int
    var movement: Double
    var markets: Int
}

struct ExpectationSnapshot {
    var composite: Double = 50
    var compositeDelta: Double = 0
    var topics: [TopicReading] = []
    var moods: [CategoryMood] = []
    var totalVolume: Int = 0
    var totalParticipants: Int = 0

    var rising: [TopicReading] { topics.filter { $0.delta > 0 }.sorted { $0.delta > $1.delta } }
    var falling: [TopicReading] { topics.filter { $0.delta < 0 }.sorted { $0.delta < $1.delta } }

    var mood: String {
        switch composite {
        case 62...:   return L("İyimser", "Optimistic")
        case 54..<62: return L("Ölçülü iyimser", "Cautiously optimistic")
        case 46..<54: return L("Kararsız", "Undecided")
        case 38..<46: return L("Temkinli", "Guarded")
        default:      return L("Karamsar", "Pessimistic")
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

        let grouped = Dictionary(grouping: live.filter { $0.topic != nil }) { $0.topic! }
        snap.topics = grouped.map { topic, group in
            TopicReading(
                topic: topic,
                current: group.map(\.priceYes).reduce(0, +) / Double(group.count) * 100,
                delta: group.map { $0.changeSince(window) }.reduce(0, +) / Double(group.count),
                marketIds: group.map(\.id),
                series: mergedSeries(group))
        }
        .sorted { abs($0.delta) > abs($1.delta) }

        // Bileşik iyimserlik: karamsarlık yönündeki başlıklar (1 − p) katkı verir
        let contributions = live.compactMap { m -> Double? in
            guard let topic = m.topic else { return nil }
            return topic.optimisticWhenUp ? m.priceYes : (1 - m.priceYes)
        }
        if !contributions.isEmpty {
            snap.composite = contributions.reduce(0, +) / Double(contributions.count) * 100
        }
        let deltas = live.compactMap { m -> Double? in
            guard let topic = m.topic else { return nil }
            let d = m.changeSince(window)
            return topic.optimisticWhenUp ? d : -d
        }
        if !deltas.isEmpty {
            snap.compositeDelta = deltas.reduce(0, +) / Double(deltas.count)
        }

        snap.moods = Category.allCases.compactMap { cat in
            let subset = live.filter { $0.category == cat }
            guard !subset.isEmpty else { return nil }
            return CategoryMood(
                category: cat,
                activity: subset.reduce(0) { $0 + $1.volume },
                movement: subset.map { abs($0.changeSince(window)) }.reduce(0, +) / Double(subset.count),
                markets: subset.count)
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
