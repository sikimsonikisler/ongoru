import Foundation

/// Öngörü Asistanı'nın sözleşmesi.
///
/// Şu anki uygulama tamamen cihaz üstünde, kural tabanlı çalışır — hiçbir
/// veri dışarı çıkmaz. Gerçek bir dil modeline (ör. Claude API) geçmek
/// istendiğinde tek yapılacak bu protokolü uygulayan yeni bir tip yazıp
/// `AppStore.assistant`'ı değiştirmek.
protocol InsightProviding {
    func thesisPrompts(market: Market, side: Side, text: String, sources: [EvidenceSource]) -> [Insight]
    func trackRecord(card: ScoreCard, name: String) -> [Insight]
    func marketBriefing(market: Market, theses: [Thesis]) -> [Insight]
}

// MARK: - Gerekçe kalitesi

enum ThesisAnalyzer {

    static var causalWords: [String] {
        I18N.lang == .tr
            ? ["çünkü", "zira", "nedeniyle", "dolayısıyla", "bu yüzden",
               "sebebiyle", "olduğu için", "sonucunda", "buna karşın", "ancak"]
            : ["because", "since", "therefore", "as a result", "due to",
               "hence", "which means", "however", "although"]
    }

    static var hedgeWords: [String] {
        I18N.lang == .tr
            ? ["ancak", "fakat", "riski", "aksi", "yanılırsam", "buna karşın"]
            : ["however", "but", "risk", "unless", "if i'm wrong", "on the other hand"]
    }

    /// 0–100 arası gerekçe kalitesi. Uzunluk, sayısal eşik, kaynak ve
    /// nedensellik bağlacı arar. Ne kadar "argüman" gibi göründüğünü ölçer,
    /// doğruluğunu değil.
    static func quality(text: String, sources: [EvidenceSource]) -> Int {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return 0 }
        var q = 14.0
        let lower = t.lowercased()

        q += min(28, Double(t.count) / 240 * 28)
        if t.rangeOfCharacter(from: .decimalDigits) != nil { q += 13 }
        if causalWords.contains(where: { lower.contains($0) }) { q += 10 }
        if hedgeWords.contains(where: { lower.contains($0) }) { q += 8 }
        q += min(27, Double(sources.count) * 9)

        return Int(min(100, q.rounded()))
    }

    static func qualityLabel(_ q: Int) -> String {
        switch q {
        case 80...:   return L("Sağlam", "Solid")
        case 60..<80: return L("İyi", "Good")
        case 40..<60: return L("Orta", "Fair")
        case 20..<40: return L("Zayıf", "Weak")
        default:      return L("Taslak", "Draft")
        }
    }

    /// Kategoriye göre "şuna bakabilirsin" listesi
    static func suggestedSources(for category: Category) -> [String] {
        switch category {
        case .ekonomi:
            return [L("TÜİK enflasyon bülteni", "TurkStat inflation bulletin"),
                    L("TCMB Piyasa Katılımcıları Anketi", "CBRT Market Participants Survey"),
                    L("TCMB PPK özeti", "CBRT MPC summary"),
                    L("Hazine iç borçlanma takvimi", "Treasury domestic borrowing calendar")]
        case .siyaset:
            return [L("Resmî Gazete", "Official Gazette"),
                    L("TBMM komisyon takvimi", "Parliamentary committee calendar"),
                    L("Anket ortalaması", "Polling average"),
                    L("Bütçe sunumu", "Budget presentation")]
        case .spor:
            return [L("TFF fikstürü", "TFF fixture list"),
                    L("Sakatlık/ceza listesi", "Injury and suspension list"),
                    L("Son 5 maç formu", "Last 5 matches form"),
                    L("Kadro değeri", "Squad market value")]
        case .teknoloji:
            return [L("Şirketin yatırımcı sunumu", "Company investor deck"),
                    L("Tedarik zinciri raporu", "Supply chain report"),
                    L("Gümrük ve ÖTV mevzuatı", "Customs and excise regulation"),
                    L("Ürün lansman takvimi", "Product launch calendar")]
        case .sirketler:
            return [L("KAP bildirimi", "Public disclosure filing"),
                    L("Son çeyrek bilanço", "Latest quarterly results"),
                    L("Analist konsensüsü", "Analyst consensus"),
                    L("Sektör kapasite raporu", "Sector capacity report")]
        case .kultur:
            return [L("Box Office Türkiye", "Box Office Türkiye"),
                    L("Yayın takvimi", "Release calendar"),
                    L("Platform açıklaması", "Platform announcement"),
                    L("Festival programı", "Festival programme")]
        case .hava:
            return [L("MGM tahmini", "Met Service forecast"),
                    L("ECMWF model çıktısı", "ECMWF model output"),
                    L("Son 10 yıl ortalaması", "10-year average")]
        }
    }
}

// MARK: - Cihaz üstü asistan

struct HeuristicAssistant: InsightProviding {

    // Gerekçe yazarken
    func thesisPrompts(market: Market, side: Side, text: String, sources: [EvidenceSource]) -> [Insight] {
        var out: [Insight] = []
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = t.lowercased()

        if t.isEmpty {
            let bare = market.question.s.replacingOccurrences(of: "?", with: "")
            out.append(Insight(
                icon: "sparkles",
                title: L("Neden böyle düşünüyorsun?", "Why do you think so?"),
                body: L("Tek cümlelik bir mekanizma yaz: “\(bare)” sonucunu getirecek olan ne?",
                        "Write a one-sentence mechanism: what would bring about “\(bare)”?"),
                tone: .neutral))
        } else if t.count < 60 {
            out.append(Insight(
                icon: "text.alignleft",
                title: L("Gerekçeni biraz aç", "Expand your rationale"),
                body: L("Şu an \(t.count) karakter. Hangi mekanizmanın bu sonuca yol açacağını bir cümle daha ekle.",
                        "Currently \(t.count) characters. Add one more sentence on the mechanism behind this outcome."),
                tone: .neutral))
        }

        if sources.count < 3 {
            let missing = 3 - sources.count
            let hint = ThesisAnalyzer.suggestedSources(for: market.category).prefix(3).joined(separator: ", ")
            out.append(Insight(
                icon: "doc.text.magnifyingglass",
                title: L("Bu tahmini destekleyen \(missing) veri eklemek ister misin?",
                         "Want to add \(missing) data source\(missing == 1 ? "" : "s") to back this up?"),
                body: L("Bu kategoride sık kullanılanlar: \(hint).",
                        "Commonly used in this category: \(hint)."),
                tone: .neutral))
        }

        if !t.isEmpty && t.rangeOfCharacter(from: .decimalDigits) == nil {
            out.append(Insight(
                icon: "number",
                title: L("Sayısal bir eşik koy", "Set a numeric threshold"),
                body: L("“Artar/azalır” yerine bir rakam söyle. Hangi değerin üstü seni haklı, altı haksız çıkarır?",
                        "Instead of “rises/falls”, name a number. Above what value are you right, and below it wrong?"),
                tone: .neutral))
        }

        let myPrice = market.price(for: side)
        if !t.isEmpty && myPrice < 0.35 {
            out.append(Insight(
                icon: "arrow.triangle.branch",
                title: L("Kalabalıkla ters düşüyorsun", "You're going against the crowd"),
                body: L("Piyasa \(side.title) tarafına yalnızca \(Int(myPrice * 100))¢ veriyor. Diğerlerinin gördüğü ama senin katılmadığın argüman ne?",
                        "The market prices \(side.title) at just \(Int(myPrice * 100))¢. What argument do others see that you disagree with?"),
                tone: .warning))
        }

        if !t.isEmpty && !ThesisAnalyzer.causalWords.contains(where: { lower.contains($0) }) && t.count >= 60 {
            out.append(Insight(
                icon: "arrow.right.circle",
                title: L("Nedeni açıkça bağla", "Link cause to effect"),
                body: L("“çünkü / dolayısıyla” gibi bir bağlaçla sebebi sonuca bağlarsan gerekçen okunur olur.",
                        "Tying cause to effect with “because / therefore” makes your rationale readable."),
                tone: .neutral))
        }

        if !t.isEmpty && !ThesisAnalyzer.hedgeWords.contains(where: { lower.contains($0) }) && t.count >= 80 {
            out.append(Insight(
                icon: "exclamationmark.triangle",
                title: L("Seni yanıltacak şey ne?", "What would prove you wrong?"),
                body: L("Bir cümleyle karşı senaryoyu da yaz. En iyi tahminciler nerede yanılabileceklerini baştan söyler.",
                        "Add the counter-scenario in one sentence. The best forecasters say up front where they could be wrong."),
                tone: .neutral))
        }

        if out.isEmpty {
            out.append(Insight(
                icon: "checkmark.seal",
                title: L("Gerekçe hazır", "Rationale is ready"),
                body: L("Mekanizma, sayısal eşik ve kaynaklar yerinde. Bu gerekçe sicilinle birlikte kaydedilecek.",
                        "Mechanism, numeric threshold and sources are all in place. This will be saved alongside your record."),
                tone: .positive))
        }
        return out
    }

    // Sicil analizi
    func trackRecord(card: ScoreCard, name: String) -> [Insight] {
        guard card.resolved > 0 else {
            return [Insight(icon: "hourglass",
                            title: L("Henüz sonuçlanmış tahminin yok", "No resolved predictions yet"),
                            body: L("İlk piyasaların çözüldüğünde burada isabet analizin oluşacak.",
                                    "Your accuracy analysis will appear here once your first markets resolve."),
                            tone: .neutral)]
        }
        var out: [Insight] = []
        let first = name.split(separator: " ").first.map(String.init) ?? name

        if let best = card.best, best.score >= card.score + 3 {
            out.append(Insight(
                icon: best.category.icon,
                title: L("\(first) özellikle \(best.category.title.lowercased()) tahminlerinde başarılı",
                         "\(first) is strongest on \(best.category.title.lowercased()) predictions"),
                body: L("\(best.resolved) sonuçlanan tahminin \(best.correct) tanesi doğru — bu kategorideki skoru \(best.score).",
                        "\(best.correct) of \(best.resolved) resolved predictions were right — category score \(best.score)."),
                tone: .positive))
        }
        if let worst = card.worst, worst.score <= card.score - 3 {
            out.append(Insight(
                icon: worst.category.icon,
                title: L("\(worst.category.title) tarafı zayıf halkan",
                         "\(worst.category.title) is your weak spot"),
                body: L("\(worst.resolved) tahminin \(worst.correct) doğru, skor \(worst.score). Bu kategoride daha küçük pozisyon almayı dene.",
                        "\(worst.correct) of \(worst.resolved) right, score \(worst.score). Try smaller positions in this category."),
                tone: .negative))
        }

        if card.shortTerm.n >= 3 && card.longTerm.n >= 3 {
            let s = Int(card.shortTerm.accuracy * 100)
            let l = Int(card.longTerm.accuracy * 100)
            if abs(s - l) >= 12 {
                let shorterBetter = s > l
                out.append(Insight(
                    icon: "timer",
                    title: shorterBetter
                        ? L("Kısa vadede daha isabetlisin", "You're sharper on short horizons")
                        : L("Uzun vadede daha isabetlisin", "You're sharper on long horizons"),
                    body: L("Kısa vadeli (≤30 gün) tahminlerinde \(Fmt.pctInt(s)), uzun vadelilerde \(Fmt.pctInt(l)) doğruluk.",
                            "\(Fmt.pctInt(s)) accuracy on short-horizon (≤30 days), \(Fmt.pctInt(l)) on long-horizon predictions."),
                    tone: .neutral))
            }
        }

        if abs(card.bias) > 0.10 {
            let optimistic = card.bias > 0
            let points = Int(abs(card.bias) * 100)
            out.append(Insight(
                icon: optimistic ? "arrow.up.right" : "arrow.down.right",
                title: optimistic ? L("Fazla iyimsersin", "You're over-optimistic")
                                  : L("Fazla temkinlisin", "You're over-cautious"),
                body: optimistic
                    ? L("Verdiğin olasılıklar gerçekleşenden ortalama \(points) puan yüksek. Emin olduğun yerde biraz geri çekil.",
                        "Your stated probabilities run \(points) points above what actually happened. Pull back where you feel certain.")
                    : L("Verdiğin olasılıklar gerçekleşenden ortalama \(points) puan düşük. Haklı olduğunda daha cesur ol.",
                        "Your stated probabilities run \(points) points below what actually happened. Be bolder when you're right."),
                tone: .warning))
        }

        if card.contrarian.n >= 3 {
            let r = Int(Double(card.contrarian.correct) / Double(card.contrarian.n) * 100)
            out.append(Insight(
                icon: "arrow.triangle.swap",
                title: L("Kalabalığa karşı gitme sicilin", "Your contrarian record"),
                body: L("45¢ altından girdiğin \(card.contrarian.n) tahminin \(card.contrarian.correct) tanesi tuttu (\(Fmt.pctInt(r))). \(r >= 50 ? "Ucuz tarafları görebiliyorsun." : "Ucuz olan çoğu zaman haklı sebeple ucuz.")",
                        "\(card.contrarian.correct) of \(card.contrarian.n) entries below 45¢ paid off (\(Fmt.pctInt(r))). \(r >= 50 ? "You can spot mispriced sides." : "Cheap is usually cheap for a reason.")"),
                tone: r >= 50 ? .positive : .negative))
        }

        if card.streak >= 3 {
            out.append(Insight(
                icon: "flame",
                title: L("\(card.streak) tahminlik doğru seri", "\(card.streak)-prediction winning streak"),
                body: L("Üst üste \(card.streak) piyasada haklı çıktın. Seriler geriye dönük anlatıdır — bir sonraki tahminde de aynı özeni göster.",
                        "You were right on \(card.streak) markets in a row. Streaks are stories told backwards — bring the same care to the next one."),
                tone: .positive))
        }

        out.append(Insight(
            icon: "target",
            title: L("Brier skorun \(Fmt.decimal(card.brier, decimals: 3))",
                     "Your Brier score is \(Fmt.decimal(card.brier, decimals: 3))"),
            body: card.brier < 0.25
                ? L("Yazı-turadan (\(Fmt.decimal(0.25, decimals: 3))) iyisin. Skorun bu farktan geliyor.",
                    "You're better than a coin flip (\(Fmt.decimal(0.25, decimals: 3))). Your score comes from that gap.")
                : L("Yazı-tura \(Fmt.decimal(0.25, decimals: 3)) verir; şu an onun gerisindesin. Emin olmadığın piyasalarda 50¢'e yakın kal.",
                    "A coin flip scores \(Fmt.decimal(0.25, decimals: 3)); you're behind that. Stay near 50¢ where you're unsure."),
            tone: card.brier < 0.25 ? .positive : .negative))

        return out
    }

    // Piyasa brifingi
    func marketBriefing(market: Market, theses: [Thesis]) -> [Insight] {
        var out: [Insight] = []
        let p = market.centsYes
        let chg = market.change24h

        out.append(Insight(
            icon: "chart.xyaxis.line",
            title: L("Kalabalık \(p)¢ diyor", "The crowd says \(p)¢"),
            body: L("Bu, “\(market.question.s)” sorusuna \(Fmt.pctInt(p)) olasılık biçildiği anlamına gelir. Son 24 saatte \(Fmt.signedDecimal(chg)) puan hareket.",
                    "That means “\(market.question.s)” is priced at \(Fmt.pctInt(p)) probability. \(Fmt.signedDecimal(chg)) points of movement in the last 24 hours."),
            tone: .neutral))

        if abs(chg) >= 4 {
            out.append(Insight(
                icon: chg > 0 ? "arrow.up.right.circle" : "arrow.down.right.circle",
                title: chg > 0 ? L("Beklenti hızla yükseliyor", "Expectations are climbing fast")
                               : L("Beklenti hızla düşüyor", "Expectations are falling fast"),
                body: L("24 saatte \(Fmt.decimal(abs(chg))) puanlık hareket bu piyasa için sert. Fiyatı taşıyan haberi bulmadan pozisyon alma.",
                        "\(Fmt.decimal(abs(chg))) points in 24 hours is sharp for this market. Find the news moving it before taking a position."),
                tone: .warning))
        }

        if market.daysLeft <= 7 && market.status == .open {
            out.append(Insight(
                icon: "clock.badge.exclamationmark",
                title: L("Kapanışa \(market.daysLeft) gün", "\(market.daysLeft) days to close"),
                body: L("Vade yaklaştıkça fiyat sonuca doğru sertleşir; yanılma payın azalır.",
                        "As expiry nears the price hardens toward the outcome and your margin for error shrinks."),
                tone: .warning))
        }

        let yesCount = theses.filter { $0.side == .yes }.count
        let noCount = theses.count - yesCount
        if theses.count >= 2 {
            let split: String
            if yesCount == noCount {
                split = L("Tam bölünmüş bir piyasa.", "A perfectly split market.")
            } else if yesCount > noCount {
                split = L("Yazanların çoğu EVET'te.", "Most writers are on YES.")
            } else {
                split = L("Yazanların çoğu HAYIR'da.", "Most writers are on NO.")
            }
            out.append(Insight(
                icon: "text.bubble",
                title: L("Gerekçelerin dağılımı", "How the rationales split"),
                body: L("\(theses.count) gerekçeden \(yesCount) tanesi EVET, \(noCount) tanesi HAYIR tarafında. \(split)",
                        "Of \(theses.count) rationales, \(yesCount) are on YES and \(noCount) on NO. \(split)"),
                tone: .neutral))
        }

        if let top = theses.max(by: { $0.quality < $1.quality }), top.quality >= 60 {
            out.append(Insight(
                icon: "star",
                title: L("En sağlam gerekçe: \(top.authorName)", "Strongest rationale: \(top.authorName)"),
                body: L("\(top.sources.count) kaynakla desteklenmiş, kalite \(top.quality)/100, \(top.side.title) tarafında.",
                        "Backed by \(top.sources.count) sources, quality \(top.quality)/100, on the \(top.side.title) side."),
                tone: .positive))
        }

        return out
    }
}
