import Foundation

struct CategoryStat: Identifiable, Hashable {
    var category: Category
    var resolved: Int
    var correct: Int
    var brier: Double
    var score: Int
    var id: String { category.rawValue }
    var accuracy: Double { resolved > 0 ? Double(correct) / Double(resolved) : 0 }
}

struct CalibrationBucket: Identifiable, Hashable {
    var lower: Int          // %
    var upper: Int
    var count: Int
    var hitRate: Double     // gerçekleşme oranı
    var id: Int { lower }
    /// Türkçede yüzde işareti önde, İngilizcede arkada
    var label: String {
        I18N.lang == .tr ? "%\(lower)–\(upper)" : "\(lower)–\(upper)%"
    }
    var midpoint: Double { Double(lower + upper) / 200 }
}

struct ScoreCard {
    var score: Int = 50
    var resolved: Int = 0
    var correct: Int = 0
    var wrong: Int = 0
    var brier: Double = 0.25
    var accuracy: Double = 0
    var categories: [CategoryStat] = []
    var shortTerm: (n: Int, accuracy: Double) = (0, 0)
    var longTerm: (n: Int, accuracy: Double) = (0, 0)
    var calibration: [CalibrationBucket] = []
    var streak: Int = 0
    var contrarian: (n: Int, correct: Int) = (0, 0)
    var bias: Double = 0        // + fazla iyimser, − fazla temkinli
    var netProfit: Double = 0

    var best: CategoryStat? { categories.filter { $0.resolved >= 2 }.max(by: { $0.score < $1.score }) }
    var worst: CategoryStat? { categories.filter { $0.resolved >= 2 }.min(by: { $0.score < $1.score }) }

    var grade: String {
        switch score {
        case 80...:   return L("Kâhin", "Oracle")
        case 70..<80: return L("Keskin", "Sharp")
        case 60..<70: return L("İyi", "Good")
        case 50..<60: return L("Ortalama", "Average")
        case 40..<50: return L("Zayıf", "Weak")
        default:      return L("Yazı tura", "Coin flip")
        }
    }
}

/// Öngörü Skoru: para değil, isabet ölçer.
///
/// Temel ölçüt Brier skoru — tahmin ettiğin olasılık ile gerçekleşen sonuç
/// arasındaki karesel hata. Yazı-tura (her şeye %50 demek) 0.25 verir.
/// Skoru 0–100'e şöyle taşıyoruz:  50 + 50·(1 − Brier/0.25)
/// Yani 50 = yazı tura, 100 = kusursuz, 0 = sistematik olarak yanlış.
enum ScoreEngine {

    static let baseline = 0.25

    static func score(fromBrier brier: Double) -> Int {
        let skill = 1 - brier / baseline
        return Int(min(100, max(0, (50 + 50 * skill).rounded())))
    }

    /// Az örnekte skoru 50'ye doğru çeker (küçük sayı yanılgısına karşı).
    static func shrunkScore(brier: Double, n: Int, k: Double = 3) -> Int {
        let raw = Double(score(fromBrier: brier))
        let shrunk = (Double(n) * raw + k * 50) / (Double(n) + k)
        return Int(shrunk.rounded())
    }

    static func card(from settlements: [Settlement]) -> ScoreCard {
        var card = ScoreCard()
        guard !settlements.isEmpty else { return card }

        let sorted = settlements.sorted { $0.date > $1.date }
        card.resolved = sorted.count
        card.correct = sorted.filter(\.correct).count
        card.wrong = card.resolved - card.correct
        card.accuracy = Double(card.correct) / Double(card.resolved)
        card.brier = sorted.map(\.brier).reduce(0, +) / Double(card.resolved)
        card.score = shrunkScore(brier: card.brier, n: card.resolved)
        card.netProfit = sorted.map(\.profit).reduce(0, +)

        // Kategori kırılımı
        card.categories = Category.allCases.compactMap { cat in
            let subset = sorted.filter { $0.category == cat }
            guard !subset.isEmpty else { return nil }
            let b = subset.map(\.brier).reduce(0, +) / Double(subset.count)
            return CategoryStat(
                category: cat,
                resolved: subset.count,
                correct: subset.filter(\.correct).count,
                brier: b,
                score: shrunkScore(brier: b, n: subset.count)
            )
        }
        .sorted { $0.score > $1.score }

        // Vade kırılımı (≤30 gün kısa)
        let short = sorted.filter { $0.horizonDays <= 30 }
        let long = sorted.filter { $0.horizonDays > 30 }
        if !short.isEmpty {
            card.shortTerm = (short.count, Double(short.filter(\.correct).count) / Double(short.count))
        }
        if !long.isEmpty {
            card.longTerm = (long.count, Double(long.filter(\.correct).count) / Double(long.count))
        }

        // Kalibrasyon: "%X derim" dediklerinin kaçı gerçekleşti
        let bounds = [(0, 20), (20, 40), (40, 60), (60, 80), (80, 100)]
        card.calibration = bounds.compactMap { lo, hi in
            let subset = sorted.filter {
                let pct = Int($0.entryProbability * 100)
                return pct >= lo && (hi == 100 ? pct <= hi : pct < hi)
            }
            guard !subset.isEmpty else { return nil }
            let hits = subset.filter { $0.outcome }.count
            return CalibrationBucket(lower: lo, upper: hi, count: subset.count,
                                     hitRate: Double(hits) / Double(subset.count))
        }

        // Seri
        var streak = 0
        for s in sorted {
            if s.correct { streak += 1 } else { break }
        }
        card.streak = streak

        // Kalabalığa karşı gitme (kendi tarafını 45¢ altından almak)
        let contrarians = sorted.filter { s in
            let myPrice = s.mySide == .yes ? s.entryProbability : 1 - s.entryProbability
            return myPrice < 0.45
        }
        card.contrarian = (contrarians.count, contrarians.filter(\.correct).count)

        // Yanlılık: ortalama söylenen olasılık − gerçekleşme oranı
        let meanStated = sorted.map(\.entryProbability).reduce(0, +) / Double(sorted.count)
        let meanOutcome = Double(sorted.filter(\.outcome).count) / Double(sorted.count)
        card.bias = meanStated - meanOutcome

        return card
    }
}
