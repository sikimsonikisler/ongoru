import Foundation

/// Kalabalığın işlem akışını taklit eden motor.
///
/// Gerçek üründe fiyatı diğer kullanıcıların emirleri hareket ettirir.
/// Burada her piyasa, gizli bir `latentProbability` etrafında ortalamaya
/// dönen (Ornstein–Uhlenbeck benzeri) bir süreçle dolaşır; böylece
/// uygulama açıkken fiyatlar canlı görünür.
struct MarketSimulator {

    /// Bir tik: piyasaların bir bölümünü hareket ettirir.
    static func tick(markets: inout [Market], now: Date = Date()) {
        for i in markets.indices {
            guard markets[i].status == .open else { continue }
            // Her tikte piyasaların ~%45'i hareket eder
            guard Double.random(in: 0...1) < 0.45 else { continue }
            step(&markets[i], now: now)
        }
    }

    private static func step(_ m: inout Market, now: Date) {
        // 1) Gizli olasılık yavaşça yürür
        m.latentProbability = clamp(m.latentProbability + gauss() * 0.004, 0.03, 0.97)

        // 2) Fiyat gizli olasılığa doğru çekilir + gürültü
        let p = m.priceYes
        let pull = 0.06
        let noise = gauss() * 0.012
        let target = clamp(p + (m.latentProbability - p) * pull + noise, 0.02, 0.98)

        // 3) Hedef fiyatı q'ya çevir (toplam q sabit kalsın, sadece fark değişsin)
        let spread = LMSR.qSpread(forPrice: target, b: m.liquidity)
        let total = m.qYes + m.qNo
        m.qYes = (total + spread) / 2
        m.qNo = (total - spread) / 2

        // 4) Hacim ve katılımcı
        let traded = Int(abs(target - p) * 900) + Int.random(in: 3...28)
        m.volume += traded
        if Int.random(in: 0...9) == 0 { m.participants += Int.random(in: 1...3) }

        // 5) Geçmişe nokta ekle (en çok 180 nokta tut)
        appendHistory(&m, price: m.priceYes, at: now)
    }

    static func appendHistory(_ m: inout Market, price: Double, at date: Date) {
        if let last = m.history.last, date.timeIntervalSince(last.t) < 20 {
            m.history[m.history.count - 1] = PricePoint(t: date, p: price)
        } else {
            m.history.append(PricePoint(t: date, p: price))
        }
        if m.history.count > 180 { m.history.removeFirst(m.history.count - 180) }
    }

    /// Kutu-Muller ile standart normal
    static func gauss() -> Double {
        let u1 = Double.random(in: 0.0001...0.9999)
        let u2 = Double.random(in: 0.0001...0.9999)
        return sqrt(-2 * log(u1)) * cos(2 * .pi * u2)
    }

    static func clamp(_ v: Double, _ lo: Double, _ hi: Double) -> Double { min(max(v, lo), hi) }

    /// Geçmiş fiyat serisi üretir (seed verisi için) — sondaki değer `end`.
    static func syntheticHistory(points: Int, end: Double, volatility: Double,
                                 span: TimeInterval, until: Date) -> [PricePoint] {
        var values = [Double](repeating: end, count: points)
        // Sondan geriye doğru rastgele yürüyüş
        for i in stride(from: points - 2, through: 0, by: -1) {
            let next = values[i + 1] + gauss() * volatility
            values[i] = clamp(next, 0.04, 0.96)
        }
        // Ortalamaya dönüş için hafif düzeltme
        let step = span / Double(max(1, points - 1))
        return values.enumerated().map { idx, v in
            PricePoint(t: until.addingTimeInterval(-span + step * Double(idx)), p: v)
        }
    }
}
