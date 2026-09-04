import Foundation

// MARK: - Sonuç

enum ModerationSeverity: String, Codable, Hashable {
    case allowed     // sorun yok
    case flagged     // gönderilebilir ama işaretlenir / incelemeye düşer
    case blocked     // gönderilemez
}

struct ModerationResult: Hashable {
    var severity: ModerationSeverity = .allowed
    var ruleId: String = ""
    var title: String = ""
    var explanation: String = ""
    /// Kullanıcıya "şu ifade" diye gösterilecek eşleşme (küfür ise maskelenir)
    var evidence: String = ""

    var isBlocked: Bool { severity == .blocked }
    var isClean: Bool { severity == .allowed }
}

enum ContentKind {
    case thesis          // gerekçe yazısı
    case marketQuestion  // kullanıcının önerdiği piyasa sorusu
    case displayName     // profil adı
}

// MARK: - Motor

/// Kural tabanlı içerik denetimi.
///
/// İki katman:
///   1. **Sert engel** — küfür/hakaret kökleri, nefret söylemi, tehdit,
///      kişisel veri. Eşleşirse gönderi hiç oluşmaz.
///   2. **İşaretleme** — adı geçen bir kişiye suç isnadı, cinsel içerik,
///      sağlık/ölüm bahsi. Piyasa önerisinde engel, gerekçede uyarıdır.
///
/// Türkçede kaçırma (leetspeak, harf tekrarı, araya nokta koyma) yaygın
/// olduğu için metin önce normalleştirilir. Yanlış pozitifleri kesmek için
/// bir güvenli kelime listesi tutulur — "sikke", "amaç", "kasık" gibi
/// kelimeler yasaklı kökleri içerdiği hâlde masumdur.
enum ContentModerator {

    // MARK: Normalleştirme

    private static let leet: [Character: Character] = [
        "0": "o", "1": "i", "3": "e", "4": "a", "5": "s", "7": "t",
        "@": "a", "$": "s", "£": "e", "!": "i", "*": "a"
    ]

    private static let fold: [Character: Character] = [
        "ç": "c", "ğ": "g", "ı": "i", "î": "i", "ö": "o", "ş": "s",
        "ü": "u", "û": "u", "â": "a", "é": "e"
    ]

    /// Küçük harfe indirir, rakam/simge kaçırmalarını açar, Türkçe
    /// aksanları düzler ve tekrar eden harfleri teke indirir
    /// ("siiiiktir" → "siktir").
    ///
    /// Tam çökertme yapılıyor çünkü kısmi çökertme ("siiktir") kaçırmayı
    /// engellemiyordu. Bu, "dikkat" → "dikat" gibi masum kelimeleri de
    /// bozar; sorun olmaması için yasaklı kökler ve güvenli kelimeler de
    /// aynı normalleştirmeden geçirilip öyle karşılaştırılır.
    static func normalize(_ text: String) -> String {
        let lowered = text.lowercased(with: Locale(identifier: "tr_TR"))
        var out = ""
        out.reserveCapacity(lowered.count)
        var previous: Character? = nil

        for raw in lowered {
            var ch = raw
            if let mapped = leet[ch] { ch = mapped }
            if let folded = fold[ch] { ch = folded }
            if ch == previous, ch.isLetter { continue }
            previous = ch
            out.append(ch)
        }
        return out
    }

    /// Kökler ve güvenli kelimeler, metinle aynı ölçekte olsun diye
    /// bir kez normalleştirilip saklanır.
    static let normalizedRoots: [String] = {
        var seen = Set<String>()
        return profanityRoots.compactMap { root in
            let n = normalize(root)
            return seen.insert(n).inserted ? n : nil
        }
    }()

    static let normalizedSafeWords: Set<String> = Set(safeWords.map { normalize($0) })

    /// Harf dışındaki her şeyi atar: "s.i.k t i r" -> "siktir"
    static func squeeze(_ normalized: String) -> String {
        String(normalized.unicodeScalars.filter { CharacterSet.letters.contains($0) })
    }

    static func tokens(_ normalized: String) -> [String] {
        normalized.split(whereSeparator: { !$0.isLetter }).map(String.init)
    }

    // MARK: Listeler

    /// Küfür ve hakaret kökleri (normalleştirilmiş hâlleriyle).
    /// 4 harf ve üzeri kökler ön ek olarak da eşleşir ("siktir", "sikeyim");
    /// 3 harf ve altı yalnızca tam kelime eşleşir, yoksa "amaç" gibi
    /// masum kelimeler yanar.
    static let profanityRoots: [String] = [
        "amk", "aq", "awk", "amcik", "amina", "aminakoyayim", "amina koyayim",
        "sik", "siktir", "sikeyim", "sikik", "sikim", "sikis", "sikerim",
        "yarrak", "yarram", "yarag", "yaraga", "yaragi",
        "got", "gotveren", "gotlek", "gotoglani",
        "orospu", "orospucocugu", "kahpe", "kaltak", "surtuk", "fahise",
        "pic", "picler", "piclik",
        "gavat", "pezevenk", "kevase", "kerhane",
        "ibne", "ibnelik", "top", "nonos",
        "bok", "boktan", "bokum", "hassiktir", "hasiktir",
        "sirkaf", "sirtlan",
        "salak", "aptal", "gerizekali", "geri zekali", "mal herif", "dangalak",
        "serefsiz", "namussuz", "haysiyetsiz", "alcak", "sefil",
        "pust", "kodumun", "koduğum", "kodugum",
        "fuck", "fucking", "shit", "bitch", "asshole", "bastard", "cunt", "whore",
        "dick", "motherfucker", "retard", "faggot"
    ]

    /// Yasaklı kökleri içeren ama masum kelimeler. Yanlış pozitif kalkanı.
    static let safeWords: Set<String> = [
        "sikke", "sikkeler", "sikkenin", "siklet", "sikletinde",
        "gotur", "goturmek", "goturur", "gotur",
        "topu", "toplam", "toplanti", "toplum", "toplumsal", "topluluk",
        "toplama", "toplamak", "topluca", "toparlama", "topraga", "toprak",
        "topluluklar", "topluluğun", "toplulugun", "topolojik",
        "bokser", "bokeuvr",
        "picture", "top10", "topten",
        "amac", "amacli", "amaci", "amacina", "ama", "aman", "amir",
        "kasik", "kasigi", "asik", "asiklar",
        "salakca",
        "malzeme", "maliyet", "mali", "malin", "malum",
        "gorunum", "gotur"
    ]

    /// Nefret söylemi / ayrımcılık işaretçileri — hedef grup + aşağılama.
    static let hateMarkers: [String] = [
        "gebertelim", "gebersin", "olsunler", "yok edelim", "temizleyelim",
        "kahrolsun", "asalak", "hepsi olsun", "surgun edilsin",
        "should be killed", "gas them", "exterminate"
    ]

    /// Tehdit kalıpları
    static let threatMarkers: [String] = [
        "olduruleecek", "oldurulecek", "oldururum", "olduruecegim", "oldurecegim",
        "kafani kopar", "bombalayacagim", "evini basacagim", "adresini biliyorum",
        "i will kill", "will be killed", "bomb the"
    ]

    /// Suç isnadı sözcükleri — adı geçen bir kişiyle birleşince engel.
    static let accusationMarkers: [String] = [
        "hirsiz", "hirsizlik", "rusvet", "yolsuzluk", "dolandirici",
        "dolandiricilik", "sahtekar", "kacakci", "tefeci", "katil",
        "tecavuzcu", "sapik", "pedofil", "terorist", "hain", "casus",
        "uyusturucu satici", "kara para", "zimmet", "irtikap",
        "thief", "fraudster", "corrupt", "criminal", "rapist", "pedophile"
    ]

    /// Yumuşak risk: kişi + sağlık/ölüm/cinsellik
    static let sensitiveMarkers: [String] = [
        "olecek mi", "olur mu diye", "kanser", "hastaligi", "intihar",
        "bosanacak mi", "aldatiyor", "hamile mi", "cinsel",
        "will die", "cancer", "suicide", "affair"
    ]

    // MARK: Denetim

    static func check(_ text: String, kind: ContentKind) -> ModerationResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return ModerationResult() }

        let norm = normalize(trimmed)
        let squeezed = squeeze(norm)
        let toks = tokens(norm)

        // 1) Küfür / hakaret
        if let hit = profanityHit(tokens: toks, squeezed: squeezed) {
            return ModerationResult(
                severity: .blocked,
                ruleId: "profanity",
                title: L("Bu ifadeyle gönderemezsin",
                         "You can't post with this wording"),
                explanation: L("Küfür, hakaret ve aşağılayıcı ifadeler Öngörü'de yasak. İfadeyi çıkarıp tekrar dene.",
                               "Profanity, insults and degrading language are not allowed on Öngörü. Remove it and try again."),
                evidence: mask(hit))
        }

        // 2) Nefret söylemi
        if let hit = firstMatch(hateMarkers, in: squeezed) {
            return ModerationResult(
                severity: .blocked,
                ruleId: "hate",
                title: L("Nefret söylemi", "Hate speech"),
                explanation: L("Bir gruba yönelik aşağılama veya şiddet çağrısı içeren içerik yayımlanamaz.",
                               "Content degrading a group or calling for violence cannot be published."),
                evidence: hit)
        }

        // 3) Tehdit
        if let hit = firstMatch(threatMarkers, in: squeezed) {
            return ModerationResult(
                severity: .blocked,
                ruleId: "threat",
                title: L("Tehdit içeriği", "Threatening content"),
                explanation: L("Şiddet tehdidi içeren içerik yayımlanamaz.",
                               "Content containing threats of violence cannot be published."),
                evidence: hit)
        }

        // 4) Kişisel veri
        if let pii = personalDataHit(trimmed) {
            return ModerationResult(
                severity: .blocked,
                ruleId: "pii",
                title: L("Kişisel veri paylaşma", "Don't share personal data"),
                explanation: L("Telefon, e-posta, TC kimlik numarası veya adres gibi kişisel veriler paylaşılamaz.",
                               "Phone numbers, e-mails, national ID numbers and addresses cannot be shared."),
                evidence: pii)
        }

        // 5) İtibar suikastı: adı geçen kişi + suç isnadı
        let named = properNames(in: trimmed)
        if let accusation = firstMatch(accusationMarkers, in: norm), let person = named.first {
            let blocking = kind != .thesis
            return ModerationResult(
                severity: blocking ? .blocked : .flagged,
                ruleId: "defamation",
                title: L("Kişiye suç isnadı", "Accusation against a person"),
                explanation: blocking
                    ? L("“\(person)” adına suç isnadı içeren bir piyasa açılamaz. Bir kurumun kararı veya resmî bir sürecin sonucu hakkında soru sorabilirsin — kişiyi suçlayan bir soru soramazsın.",
                        "A market accusing “\(person)” of a crime cannot be opened. You may ask about an institution's decision or the outcome of an official process — not a question that accuses a person.")
                    : L("Bu gerekçe “\(person)” hakkında suç isnadı içeriyor gibi görünüyor. Yayımlarsan incelemeye düşer; iddianı kaynağa dayandırmanı öneririz.",
                        "This rationale appears to accuse “\(person)” of a crime. If you publish it, it will be reviewed; we suggest backing the claim with a source."),
                evidence: accusation)
        }

        // 6) Yumuşak risk
        if let hit = firstMatch(sensitiveMarkers, in: norm), !named.isEmpty {
            return ModerationResult(
                severity: .flagged,
                ruleId: "sensitive",
                title: L("Hassas içerik", "Sensitive content"),
                explanation: L("Belirli bir kişinin sağlığı, ölümü veya özel hayatı hakkında piyasa açmak hem etik hem hukuki risk taşır.",
                               "Opening a market about a specific person's health, death or private life carries both ethical and legal risk."),
                evidence: hit)
        }

        return ModerationResult()
    }

    // MARK: Yardımcılar

    private static func profanityHit(tokens: [String], squeezed: String) -> String? {
        for token in tokens {
            if normalizedSafeWords.contains(token) { continue }
            for root in normalizedRoots where !root.contains(" ") {
                // Kısa kökler ("sik", "got", "top") yalnızca tam kelime
                // eşleşir; ön ek olarak arasak "gotur", "toplam" gibi
                // masum kelimeler yanardı.
                if root.count <= 3 {
                    if token == root { return root }
                } else if token.hasPrefix(root) {
                    return root
                }
            }
        }
        // Araya işaret sıkıştırarak kaçırma: yalnızca uzun, ayırt edici kökler
        for root in normalizedRoots where root.count >= 6 && !root.contains(" ") {
            if squeezed.contains(root) { return root }
        }
        for root in normalizedRoots where root.contains(" ") {
            let joined = root.replacingOccurrences(of: " ", with: "")
            if squeezed.contains(joined) { return root }
        }
        return nil
    }

    private static func firstMatch(_ list: [String], in haystack: String) -> String? {
        let squeezedHay = squeeze(haystack)
        for needle in list {
            if haystack.contains(needle) { return needle }
            let joined = needle.replacingOccurrences(of: " ", with: "")
            if joined.count >= 6 && squeezedHay.contains(joined) { return needle }
        }
        return nil
    }

    /// Telefon, e-posta, TC kimlik no ve IBAN
    private static func personalDataHit(_ text: String) -> String? {
        let patterns: [(String, String)] = [
            ("[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}", "e-posta"),
            ("(?<!\\d)(?:0|\\+90)?\\s?5\\d{2}[\\s.-]?\\d{3}[\\s.-]?\\d{2}[\\s.-]?\\d{2}(?!\\d)", "telefon"),
            ("(?<!\\d)[1-9]\\d{10}(?!\\d)", "TC kimlik no"),
            ("TR\\d{2}[\\s]?(?:\\d{4}[\\s]?){5}\\d{2}", "IBAN")
        ]
        for (pattern, label) in patterns {
            if let re = try? NSRegularExpression(pattern: pattern),
               re.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil {
                return label
            }
        }
        return nil
    }

    /// Ardışık iki büyük harfli kelime → özel isim adayı.
    /// "Galatasaray 2025-26" gibi tek kelimelik kurum adlarını kasten
    /// yakalamaz; hedef, gerçek kişi adlarıdır.
    static func properNames(in text: String) -> [String] {
        let stop: Set<String> = ["Türkiye", "İstanbul", "Ankara", "İzmir", "Avrupa", "Süper",
                                 "Dünya", "Merkez", "Resmî", "Aralık", "Ocak", "Şubat", "Mart",
                                 "Nisan", "Mayıs", "Haziran", "Temmuz", "Ağustos", "Eylül",
                                 "Ekim", "Kasım", "Borsa", "Yeni", "Bir", "Milli", "Millî"]
        let words = text.split(whereSeparator: { !$0.isLetter && $0 != "İ" && $0 != "ı" })
            .map(String.init)
        var names: [String] = []
        var i = 0
        while i < words.count - 1 {
            let a = words[i], b = words[i + 1]
            if isCapitalized(a), isCapitalized(b), !stop.contains(a), !stop.contains(b),
               a.count > 1, b.count > 1 {
                names.append("\(a) \(b)")
                i += 2
            } else {
                i += 1
            }
        }
        return names
    }

    private static func isCapitalized(_ w: String) -> Bool {
        guard let first = w.first else { return false }
        return first.isUppercase
    }

    /// Küfrü kullanıcıya geri gösterirken maskele
    private static func mask(_ word: String) -> String {
        guard word.count > 2 else { return String(repeating: "•", count: word.count) }
        let first = word.prefix(1)
        return first + String(repeating: "•", count: word.count - 1)
    }
}
