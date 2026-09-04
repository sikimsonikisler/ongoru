import Foundation

/// Logaritmik Piyasa Skorlama Kuralı (Hanson LMSR).
///
/// Gerçek tahmin borsalarındaki otomatik piyasa yapıcının aynısı:
/// her işlem fiyatı hareket ettirir, fiyatlar her zaman 0-1 arasında kalır
/// ve EVET + HAYIR = 100¢ olur. `b` likidite parametresi — büyükse fiyat
/// daha az oynar.
enum LMSR {

    /// C(q) = b · ln(e^(qY/b) + e^(qN/b))   — sayısal olarak kararlı hâli
    static func cost(qYes: Double, qNo: Double, b: Double) -> Double {
        let a = qYes / b
        let c = qNo / b
        let m = max(a, c)
        return b * (m + log(exp(a - m) + exp(c - m)))
    }

    /// Anlık EVET fiyatı (0...1). Softmax.
    static func priceYes(qYes: Double, qNo: Double, b: Double) -> Double {
        let a = qYes / b
        let c = qNo / b
        let m = max(a, c)
        let ea = exp(a - m)
        let ec = exp(c - m)
        return ea / (ea + ec)
    }

    /// `shares` adet sözleşme almanın maliyeti (puan cinsinden, 1 sözleşme = 100 puan ödeme).
    /// Negatif `shares` satış demektir; sonuç negatif çıkarsa kasaya puan girer.
    static func tradeCost(market: Market, side: Side, shares: Double) -> Double {
        let before = cost(qYes: market.qYes, qNo: market.qNo, b: market.liquidity)
        let after: Double
        switch side {
        case .yes: after = cost(qYes: market.qYes + shares, qNo: market.qNo, b: market.liquidity)
        case .no:  after = cost(qYes: market.qYes, qNo: market.qNo + shares, b: market.liquidity)
        }
        return (after - before) * 100
    }

    /// Verilen puan bütçesiyle kaç sözleşme alınabilir (ikili arama).
    static func shares(forBudget budget: Double, market: Market, side: Side) -> Double {
        guard budget > 0 else { return 0 }
        var lo = 0.0
        var hi = max(1.0, budget / 100 * 4)
        // Üst sınırı bütçeyi aşana kadar büyüt
        var guard_ = 0
        while tradeCost(market: market, side: side, shares: hi) < budget && guard_ < 60 {
            hi *= 2
            guard_ += 1
        }
        for _ in 0..<60 {
            let mid = (lo + hi) / 2
            if tradeCost(market: market, side: side, shares: mid) < budget { lo = mid } else { hi = mid }
        }
        return lo
    }

    /// Bir işlemin ortalama dolum fiyatı (0...1).
    static func averageFillPrice(market: Market, side: Side, shares: Double) -> Double {
        guard shares > 0 else { return market.price(for: side) }
        return tradeCost(market: market, side: side, shares: shares) / (shares * 100)
    }

    /// Fiyatı hedeflenen olasılığa taşımak için gereken q farkı.
    /// p = σ((qY - qN)/b)  ⇒  qY - qN = b·ln(p/(1-p))
    static func qSpread(forPrice p: Double, b: Double) -> Double {
        let clamped = min(max(p, 0.005), 0.995)
        return b * log(clamped / (1 - clamped))
    }
}
