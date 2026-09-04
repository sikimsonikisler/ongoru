import Foundation
import SwiftUI

// MARK: - Kategoriler

enum Category: String, Codable, CaseIterable, Identifiable, Hashable {
    case ekonomi, siyaset, spor, teknoloji, sirketler, kultur, hava

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ekonomi:    return L("Ekonomi", "Economy")
        case .siyaset:    return L("Siyaset", "Politics")
        case .spor:       return L("Spor", "Sports")
        case .teknoloji:  return L("Teknoloji", "Tech")
        case .sirketler:  return L("Şirketler", "Companies")
        case .kultur:     return L("Kültür", "Culture")
        case .hava:       return L("Hava", "Weather")
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

// MARK: - Beklenti Endeksi başlıkları
//
// Başlık, "yükselmesi iyimserlik mi" bilgisini kendi taşır; böylece her
// piyasada ayrı bir ters çevirme bayrağı tutmaya gerek kalmaz.

enum IndexTopic: String, Codable, CaseIterable, Identifiable, Hashable {
    case faizDusecek, enflasyonDusecek, dovizYukselecek, altinYukselecek
    case konutArtacak, borsaYukselecek, issizlikArtacak, asgariReel, ekonomiBuyuyecek

    var id: String { rawValue }

    var title: String {
        switch self {
        case .faizDusecek:      return L("Faiz düşecek", "Rates will fall")
        case .enflasyonDusecek: return L("Enflasyon düşecek", "Inflation will fall")
        case .dovizYukselecek:  return L("Döviz yükselecek", "FX will rise")
        case .altinYukselecek:  return L("Altın yükselecek", "Gold will rise")
        case .konutArtacak:     return L("Konut fiyatları artacak", "Housing prices will rise")
        case .borsaYukselecek:  return L("Borsa yükselecek", "Equities will rise")
        case .issizlikArtacak:  return L("İşsizlik artacak", "Unemployment will rise")
        case .asgariReel:       return L("Asgari ücret reel artacak", "Minimum wage will beat inflation")
        case .ekonomiBuyuyecek: return L("Ekonomi büyüyecek", "The economy will grow")
        }
    }

    /// Bu başlığın yükselmesi iyimserlik mi sayılır?
    var optimisticWhenUp: Bool {
        switch self {
        case .faizDusecek, .enflasyonDusecek, .borsaYukselecek,
             .asgariReel, .ekonomiBuyuyecek:
            return true
        case .dovizYukselecek, .altinYukselecek, .konutArtacak, .issizlikArtacak:
            return false
        }
    }
}

// MARK: - Taraf

enum Side: String, Codable, Hashable, CaseIterable {
    case yes, no

    var title: String { self == .yes ? L("EVET", "YES") : L("HAYIR", "NO") }
    var other: Side { self == .yes ? .no : .yes }

    /// Renk körlüğüne karşı ikinci ipucu
    var glyph: String { self == .yes ? "arrow.up.right" : "arrow.down.right" }
}

// MARK: - Piyasa

enum MarketStatus: String, Codable, Hashable {
    case open, closed, resolved
}

/// Piyasayı kim açtı
enum MarketOrigin: String, Codable, Hashable {
    case seed        // uygulamayla gelen
    case community   // kullanıcı önerisi
}

struct PricePoint: Codable, Hashable, Identifiable {
    var t: Date
    var p: Double
    var id: Date { t }
}

struct Market: Identifiable, Codable, Hashable {
    var id: String
    var question: LText
    var detail: LText
    var resolutionSource: LText
    var category: Category
    var createdAt: Date
    var closeDate: Date

    var liquidity: Double
    var qYes: Double
    var qNo: Double

    var volume: Int
    var participants: Int
    var history: [PricePoint]

    var status: MarketStatus
    var resolvedOutcome: Bool?
    var resolvedAt: Date?

    var latentProbability: Double
    var topic: IndexTopic?

    var origin: MarketOrigin = .seed
    var authorName: String? = nil

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

    var change24h: Double { changeSince(24 * 3600) }

    func changeSince(_ interval: TimeInterval) -> Double {
        guard let last = history.last else { return 0 }
        let cutoff = last.t.addingTimeInterval(-interval)
        guard let ref = history.last(where: { $0.t <= cutoff }) ?? history.first else { return 0 }
        return (last.p - ref.p) * 100
    }

    /// Kartlardaki mini grafiğin gösterdiği son dilim
    func recentSlice(_ count: Int = 48) -> [PricePoint] { Array(history.suffix(count)) }

    /// O dilimin kendi eğimi — mini grafiğin rengi buradan gelir.
    func sliceTrend(_ count: Int = 48) -> Double {
        let slice = recentSlice(count)
        guard let first = slice.first, let last = slice.last else { return 0 }
        return (last.p - first.p) * 100
    }

    /// LMSR'de emir defteri yok; yine de küçük bir işlem büyüklüğünde
    /// oluşacak alış/satış farkını göstererek gerçek borsa hissini veriyoruz.
    func spread(size: Double = 50) -> (bid: Double, ask: Double) {
        let ask = LMSR.averageFillPrice(market: self, side: .yes, shares: size)
        let bidCost = LMSR.averageFillPrice(market: self, side: .yes, shares: -size)
        return (bid: min(bidCost, ask), ask: max(bidCost, ask))
    }
}

// MARK: - İşlem

enum TradeAction: String, Codable, Hashable { case buy, sell }

struct Trade: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var marketId: String
    var marketQuestion: LText
    var category: Category
    var side: Side
    var action: TradeAction
    var shares: Double
    var avgPrice: Double
    var puan: Double
    var date: Date
    var thesisId: String?
}

// MARK: - Pozisyon

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

// MARK: - Sonuçlanma

struct Settlement: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var marketId: String
    var question: LText
    var category: Category
    var outcome: Bool
    var mySide: Side
    var shares: Double
    var invested: Double
    var payout: Double
    var entryProbability: Double
    var horizonDays: Int
    var date: Date

    var correct: Bool { (mySide == .yes) == outcome }
    var profit: Double { payout - invested }
    var brier: Double {
        let o = outcome ? 1.0 : 0.0
        return pow(entryProbability - o, 2)
    }
}

// MARK: - Gerekçe

struct EvidenceSource: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var title: LText
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
    var text: LText
    var sources: [EvidenceSource]
    var upvotes: Int
    var date: Date
    var iUpvoted: Bool = false
    /// Moderasyonun işaretlediği içerik incelemeye düşer
    var underReview: Bool = false

    var quality: Int { ThesisAnalyzer.quality(text: text.s, sources: sources) }
}

// MARK: - Katılımcı

struct Trader: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var handle: String
    var avatarSeed: Int
    var cash: Double
    var score: Int
    var resolvedCount: Int
    var correctCount: Int
    var streak: Int
    var title: LText?
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

// MARK: - Topluluk piyasası önerisi

enum ProposalStatus: String, Codable, Hashable {
    case live, review, rejected

    var label: String {
        switch self {
        case .live:     return L("Yayında", "Live")
        case .review:   return L("İncelemede", "Under review")
        case .rejected: return L("Reddedildi", "Rejected")
        }
    }

    var color: Color {
        switch self {
        case .live:     return Palette.yes
        case .review:   return Palette.gold
        case .rejected: return Palette.no
        }
    }
}

struct MarketProposal: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var question: String
    var detail: String
    var resolutionSource: String
    var category: Category
    var closeDate: Date
    var initialProbability: Double
    var createdAt: Date
    var status: ProposalStatus
    var moderationNote: String?
    var marketId: String?
}

// MARK: - Bildirim (report)

enum ReportReason: String, Codable, CaseIterable, Identifiable, Hashable {
    case hakaret, yanlisBilgi, kisiselVeri, spam, diger
    var id: String { rawValue }

    var label: String {
        switch self {
        case .hakaret:     return L("Hakaret veya nefret söylemi", "Insult or hate speech")
        case .yanlisBilgi: return L("Yanlış veya yanıltıcı bilgi", "False or misleading claim")
        case .kisiselVeri: return L("Kişisel veri paylaşımı", "Shares personal data")
        case .spam:        return L("Spam veya reklam", "Spam or advertising")
        case .diger:       return L("Diğer", "Other")
        }
    }
}

struct Report: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var targetKind: String     // "thesis" | "market"
    var targetId: String
    var reason: ReportReason
    var note: String?
    var date: Date
}

// MARK: - Asistan çıktıları

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
