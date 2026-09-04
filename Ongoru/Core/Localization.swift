import Foundation
import SwiftUI

// MARK: - Dil

enum Lang: String, Codable, Hashable {
    case tr, en
}

enum AppLanguage: String, Codable, CaseIterable, Identifiable, Hashable {
    case system, tr, en
    var id: String { rawValue }

    var resolved: Lang {
        switch self {
        case .tr: return .tr
        case .en: return .en
        case .system:
            let code = (Locale.preferredLanguages.first ?? "tr").prefix(2).lowercased()
            return code == "tr" ? .tr : .en
        }
    }

    var label: String {
        switch self {
        case .system: return L("Sistem dili", "System")
        case .tr: return "Türkçe"
        case .en: return "English"
        }
    }

    var flag: String {
        switch self {
        case .system: return "⚙︎"
        case .tr: return "🇹🇷"
        case .en: return "🇬🇧"
        }
    }
}

/// Etkin dil. `AppStore` bunu ayarlar; arayüz `AppState.language` değiştiğinde
/// kök görünüm `.id(...)` ile yeniden kurulduğu için tüm metinler tazelenir.
enum I18N {
    static var lang: Lang = .tr

    static var locale: Locale {
        lang == .tr ? Locale(identifier: "tr_TR") : Locale(identifier: "en_US")
    }
}

/// Satır içi iki dilli metin. Uygulamada tek çeviri mekanizması budur:
/// `L("Piyasalar", "Markets")`.
///
/// `.xcstrings` yerine bunun seçilmesinin sebebi, uygulama içinden dil
/// değiştirilebilmesi — String Catalog yalnızca sistem diline uyar.
func L(_ tr: String, _ en: String) -> String {
    I18N.lang == .tr ? tr : en
}

/// Veride saklanan iki dilli metin (seed piyasalar, gerekçeler…).
/// Kullanıcı üretimi içerikte iki alan da aynı olur.
struct LText: Codable, Hashable {
    var tr: String
    var en: String

    init(_ tr: String, _ en: String) { self.tr = tr; self.en = en }
    init(_ both: String) { self.tr = both; self.en = both }

    var s: String { I18N.lang == .tr ? tr : en }

    /// Arama iki dilde birden yapılsın
    var searchable: String { (tr + " " + en).lowercased() }
}

extension LText: CustomStringConvertible {
    var description: String { s }
}
