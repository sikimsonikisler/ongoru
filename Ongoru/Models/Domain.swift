import Foundation
import SwiftUI

// MARK: - Kategoriler

enum Category: String, Codable, CaseIterable, Identifiable, Hashable {
    case ekonomi, siyaset, spor, teknoloji, sirketler, kultur, hava

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ekonomi:    return "Ekonomi"
        case .siyaset:    return "Siyaset"
        case .spor:       return "Spor"
        case .teknoloji:  return "Teknoloji"
        case .sirketler:  return "Şirketler"
        case .kultur:     return "Kültür"
        case .hava:       return "Hava"
        }
    }

    var icon: String {
        switch self {
        case .ekonomi:    return "chart.line.uptrend.xyaxis"
        case .siyaset:    return "building.columns"
        case .spor:       return "sportscourt"
        case .teknoloji:  return "cpu"
        case .sirketler:  return "briefcase"
        case .kultur:     return "theatermasks"
        case .hava:       return "cloud.sun"
        }
    }

    var tint: Color {
        switch self {
        case .ekonomi:    return Color(red: 0.20, green: 0.83, blue: 0.45)
        case .siyaset:    return Color(red: 0.85, green: 0.55, blue: 0.25)
        case .spor:       return Color(red: 0.30, green: 0.65, blue: 0.95)
        case .teknoloji:  return Color(red: 0.62, green: 0.45, blue: 0.95)
        case .sirketler:  return Color(red: 0.95, green: 0.75, blue: 0.30)
        case .kultur:     return Color(red: 0.95, green: 0.42, blue: 0.62)
        case .hava:       return Color(red: 0.40, green: 0.80, blue: 0.85)
        }
    }
}

// MARK: - Taraf

enum Side: String, Codable, Hashable, CaseIterable {
    case yes, no

    var title: String { self == .yes ? "EVET" : "HAYIR" }
    var short: String { self == .yes ? "E" : "H" }
    var other: Side { self == .yes ? .no : .yes }
}

// MARK: - Piyasa durumu

enum MarketStatus: String, Codable, Hashable {
    case open       // işlem görüyor
    case closed     // süresi doldu, çözüm bekliyor
    case resolved   // sonuçlandı
}

struct PricePoint: Codable, Hashable, Identifiable {
    var t: Date
    var p: Double          // 0...1 EVET olasılığı
    var id: Date { t }
}

// MARK: - Piyasa

struct Market: Identifiable, Codable, Hashable {
    var id: String
    var question: String
    var detail: String                 // çözüm kriteri
    var resolutionSource: String       // "TCMB PPK kararı"
    var category: Category
    var createdAt: Date
    var closeDate: Date

    // LMSR durum
    var liquidity: Double              // b parametresi
    var qYes: Double
    var qNo: Double

    var volume: Int                    // toplam işlem adedi
    var participants: Int
    var history: [PricePoint]

    var status: MarketStatus
    var resolvedOutcome: Bool?
    var resolvedAt: Date?

    /// Simülasyon motorunun etrafında dolaştığı gizli "gerçek" olasılık.
    /// Gerçek bir üründe bunun yerine kalabalığın kendi emirleri olur.
    var latentProbability: Double

    /// Beklenti Endeksi'nde hangi başlığa katkı verdiği (varsa)
    var indexTheme: String?
    /// Endekse katkısı ters yönlüyse (örn. "faiz düşecek mi" → iyimserlik)
    var indexInverted: Bool = false

    var priceYes: Double { LMSR.priceYes(qYes: qYes, qNo: qNo, b: liquidity) }
    var priceNo: Double { 1 - priceYes }

    func price(for side: Side) -> Double { side == .yes ? priceYes : priceNo }

    var centsYes: Int { Int((priceYes * 100).rounded()) }
    var centsNo: Int { 100 - centsYes }

    var isTradable: Bool { status == .open }

    var daysLeft: Int {
        max(0, Calendar.current.dateComponents([.day], from: Date(), to: closeDate).day ?? 0)
    }

    var horizonDays: Int {
        max(1, Calendar.current.dateComponents([.day], from: createdAt, to: closeDate).day ?? 1)
    }

    /// Son 24 saatlik fiyat değişimi (yüzde puan)
    var change24h: Double {
        guard let last = history.last else { return 0 }
        let cutoff = last.t.addingTimeInterval(-24 * 3600)
        let ref = history.last(where: { $0.t <= cutoff }) ?? history.first
        guard let ref else { return 0 }
        return (last.p - ref.p) * 100
    }

    func changeSince(_ interval: TimeInterval) -> Double {
        guard let last = history.last else { return 0 }
        let cutoff = last.t.addingTimeInterval(-interval)
        guard let ref = history.last(where: { $0.t <= cutoff }) ?? history.first else { return 0 }
        return (last.p - ref.p) * 100
    }
}

// MARK: - İşlem kaydı

enum TradeAction: String, Codable, Hashable {
    case buy, sell
}

struct Trade: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var marketId: String
    var marketQuestion: String
    var category: Category
    var side: Side
    var action: TradeAction
    var shares: Double
    var avgPrice: Double        // 0...1
    var puan: Double            // harcanan (+) / alınan (-) puan
    var date: Date
    var thesisId: String?
}

// MARK: - Pozisyon (işlemlerden türetilir)

struct Position: Identifiable, Hashable {
    var marketId: String
    var yesShares: Double
    var noShares: Double
    var yesCost: Double
    var noCost: Double

    var id: String { marketId }

    var netSide: Side? {
        if yesShares > noShares + 0.0001 { return .yes }
        if noShares > yesShares + 0.0001 { return .no }
        return nil
    }

    var shares: Double { max(yesShares, noShares) }
    var cost: Double { yesCost + noCost }

    /// Sözleşme başına ortalama maliyet, 0...1 fiyat ölçeğinde
    /// (1 sözleşme = 100 puan ödediği için puanı 100'e böleriz).
    func avgPrice(for side: Side) -> Double {
        let s = side == .yes ? yesShares : noShares
        let c = side == .yes ? yesCost : noCost
        return s > 0.0001 ? c / (s * 100) : 0
    }

    func value(at market: Market) -> Double {
        yesShares * market.priceYes * 100 + noShares * market.priceNo * 100
    }

    func pnl(at market: Market) -> Double { value(at: market) - cost }
}

// MARK: - Sonuçlanma kaydı

struct Settlement: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var marketId: String
    var question: String
    var category: Category
    var outcome: Bool                  // EVET mi çıktı
    var mySide: Side
    var shares: Double
    var invested: Double
    var payout: Double
    var entryProbability: Double       // benim EVET'e biçtiğim ortalama olasılık (0...1)
    var horizonDays: Int
    var date: Date

    var correct: Bool { (mySide == .yes) == outcome }
    var profit: Double { payout - invested }
    /// Brier skoru: (tahmin - sonuç)²  — düşük olan iyi
    var brier: Double {
        let o = outcome ? 1.0 : 0.0
        return pow(entryProbability - o, 2)
    }
}

// MARK: - Gerekçe (tez) ve kaynaklar

struct EvidenceSource: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var title: String
    var detail: String?
}

struct Thesis: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var marketId: String
    var authorId: String
    var authorName: String
    var authorScore: Int
    var side: Side
    var priceAtPost: Double
    var text: String
    var sources: [EvidenceSource]
    var upvotes: Int
    var date: Date
    var iUpvoted: Bool = false

    var quality: Int { ThesisAnalyzer.quality(text: text, sources: sources) }
}

// MARK: - Katılımcı

struct Trader: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var handle: String
    var avatarSeed: Int
    var cash: Double
    var score: Int                     // Öngörü Skoru 0...100
    var resolvedCount: Int
    var correctCount: Int
    var streak: Int
    var title: String?                 // "Ekonomi uzmanı" gibi
    var isMe: Bool = false

    var accuracy: Double {
        resolvedCount > 0 ? Double(correctCount) / Double(resolvedCount) : 0
    }

    var initials: String {
        let parts = name.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? "?"
        let second = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + second).uppercased()
    }
}

// MARK: - Öngörü Asistanı çıktıları

enum InsightTone: String, Codable, Hashable {
    case positive, negative, neutral, warning
}

struct Insight: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var icon: String
    var title: String
    var body: String
    var tone: InsightTone
}
