import SwiftUI

enum Palette {
    static let bg          = Color(red: 0.043, green: 0.047, blue: 0.058)
    static let surface     = Color(red: 0.078, green: 0.086, blue: 0.102)
    static let surfaceHigh = Color(red: 0.110, green: 0.122, blue: 0.145)
    static let stroke      = Color(red: 0.180, green: 0.196, blue: 0.227)
    static let text        = Color(red: 0.937, green: 0.945, blue: 0.960)
    static let muted       = Color(red: 0.545, green: 0.573, blue: 0.627)
    static let faint       = Color(red: 0.380, green: 0.404, blue: 0.451)

    static let yes         = Color(red: 0.196, green: 0.831, blue: 0.451)
    static let yesDim      = Color(red: 0.196, green: 0.831, blue: 0.451).opacity(0.14)
    static let no          = Color(red: 0.965, green: 0.325, blue: 0.396)
    static let noDim       = Color(red: 0.965, green: 0.325, blue: 0.396).opacity(0.14)
    static let gold        = Color(red: 0.972, green: 0.765, blue: 0.294)
    static let accent      = Color(red: 0.196, green: 0.831, blue: 0.451)
}

extension Side {
    var color: Color { self == .yes ? Palette.yes : Palette.no }
    var dimColor: Color { self == .yes ? Palette.yesDim : Palette.noDim }
}

extension Font {
    /// Fiyat ve puanlar için tabular monospace
    static func mono(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded).monospacedDigit()
    }
}

// MARK: - Türkçe sayı biçimleri

enum Fmt {
    static let tr = Locale(identifier: "tr_TR")

    static func puan(_ v: Double, decimals: Int = 0) -> String {
        let f = NumberFormatter()
        f.locale = tr
        f.numberStyle = .decimal
        f.maximumFractionDigits = decimals
        f.minimumFractionDigits = decimals
        return f.string(from: NSNumber(value: v)) ?? "0"
    }

    static func int(_ v: Int) -> String { puan(Double(v)) }

    static func signed(_ v: Double, decimals: Int = 0) -> String {
        (v >= 0 ? "+" : "−") + puan(abs(v), decimals: decimals)
    }

    static func cents(_ p: Double) -> String { "\(Int((p * 100).rounded()))¢" }

    /// "+5,2" / "−2,6" — Türkçe ondalık ayırıcıyla işaretli sayı
    static func signedDecimal(_ v: Double, decimals: Int = 1) -> String {
        (v >= 0 ? "+" : "−") + puan(abs(v), decimals: decimals)
    }

    static func decimal(_ v: Double, decimals: Int = 1) -> String { puan(v, decimals: decimals) }

    static func pct(_ p: Double) -> String { "%\(Int((p * 100).rounded()))" }

    static func compact(_ v: Int) -> String {
        switch v {
        case 1_000_000...: return puan(Double(v) / 1_000_000, decimals: 1) + "M"
        case 1_000...:     return puan(Double(v) / 1_000, decimals: 1) + "B"
        default:           return int(v)
        }
    }

    static func relative(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.locale = tr
        f.unitsStyle = .short
        return f.localizedString(for: date, relativeTo: Date())
    }

    static func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = tr
        f.dateFormat = "d MMM yyyy"
        return f.string(from: date)
    }

    static func kalan(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        if days < 0 { return "kapandı" }
        if days == 0 { return "bugün kapanıyor" }
        if days == 1 { return "1 gün" }
        if days < 30 { return "\(days) gün" }
        let months = days / 30
        return "\(months) ay"
    }
}
