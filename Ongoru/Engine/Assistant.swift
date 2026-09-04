import Foundation

/// Öngörü Asistanı'nın sözleşmesi.
///
/// Şu anki uygulama tamamen cihaz üstünde, kural tabanlı çalışır — hiçbir
/// veri dışarı çıkmaz. Gerçek bir dil modeline (ör. Claude API) geçmek
/// istendiğinde tek yapılacak bu protokolü uygulayan yeni bir tip yazıp
/// `AppStore.assistant`'ı değiştirmek.
protocol InsightProviding {
    /// Gerekçe yazarken kullanıcıyı yönlendiren istemler
    func thesisPrompts(market: Market, side: Side, text: String, sources: [EvidenceSource]) -> [Insight]
    /// Sicil analizi
    func trackRecord(card: ScoreCard, name: String) -> [Insight]
    /// Bir piyasa hakkında bağlam notları
    func marketBriefing(market: Market, theses: [Thesis]) -> [Insight]
}

// MARK: - Gerekçe kalitesi

enum ThesisAnalyzer {

    static let causalWords = ["çünkü", "zira", "nedeniyle", "dolayısıyla", "bu yüzden",
                              "sebebiyle", "olduğu için", "sonucunda", "buna karşın", "ancak"]

    /// 0–100 arası gerekçe kalitesi. Uzunluk, sayısal eşik, kaynak ve
    /// nedensellik bağlacı arar. Ne kadar "argüman" gibi göründüğünü ölçer,
    /// doğruluğunu değil.
    static func quality(text: String, sources: [EvidenceSource]) -> Int {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return 0 }
        var q = 14.0
        let lower = t.lowercased()

        // Uzunluk (240 karaktere kadar ödüllendirilir)
        q += min(28, Double(t.count) / 240 * 28)
        // Sayısal eşik / veri
        if t.rangeOfCharacter(from: .decimalDigits) != nil { q += 13 }
        // Nedensellik
        if causalWords.contains(where: { lower.contains($0) }) { q += 10 }
        // Karşı argüman kabulü
        if ["ancak", "fakat", "riski", "aksi", "yanılırsam", "buna karşın"].contains(where: { lower.contains($0) }) { q += 8 }
        // Kaynaklar
        q += min(27, Double(sources.count) * 9)

        return Int(min(100, q.rounded()))
    }

    static func qualityLabel(_ q: Int) -> String {
        switch q {
        case 80...: return "Sağlam"
        case 60..<80: return "İyi"
        case 40..<60: return "Orta"
        case 20..<40: return "Zayıf"
        default: return "Taslak"
        }
    }

    /// Kategoriye göre "şuna bakabilirsin" listesi
    static func suggestedSources(for category: Category) -> [String] {
        switch category {
        case .ekonomi:
            return ["TÜİK enflasyon bülteni", "TCMB Piyasa Katılımcıları Anketi",
                    "TCMB PPK özeti", "Hazine iç borçlanma takvimi"]
        case .siyaset:
            return ["Resmî Gazete", "TBMM komisyon takvimi", "Anket ortalaması", "Bütçe sunumu"]
        case .spor:
            return ["TFF fikstürü", "Sakatlık/ceza listesi", "Son 5 maç formu", "Kadro değeri"]
        case .teknoloji:
            return ["Şirketin yatırımcı sunumu", "Tedarik zinciri raporu",
                    "Gümrük ve ÖTV mevzuatı", "Ürün lansman takvimi"]
        case .sirketler:
            return ["KAP bildirimi", "Son çeyrek bilanço", "Analist konsensüsü", "Sektör kapasite raporu"]
        case .kultur:
            return ["Box Office Türkiye", "Yayın takvimi", "Platform açıklaması", "Festival programı"]
        case .hava:
            return ["MGM tahmini", "ECMWF model çıktısı", "Son 10 yıl ortalaması"]
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
            out.append(Insight(
                icon: "sparkles",
                title: "Neden böyle düşünüyorsun?",
                body: "Tek cümlelik bir mekanizma yaz: “\(market.question.replacingOccurrences(of: "?", with: ""))” sonucunu getirecek olan ne?",
                tone: .neutral))
        } else if t.count < 60 {
            out.append(Insight(
                icon: "text.alignleft",
                title: "Gerekçeni biraz aç",
                body: "Şu an \(t.count) karakter. Hangi mekanizmanın bu sonuca yol açacağını bir cümle daha ekle.",
                tone: .neutral))
        }

        if sources.count < 3 {
            let eksik = 3 - sources.count
            let öneri = ThesisAnalyzer.suggestedSources(for: market.category).prefix(3).joined(separator: ", ")
            out.append(Insight(
                icon: "doc.text.magnifyingglass",
                title: "Bu tahmini destekleyen \(eksik) veri eklemek ister misin?",
                body: "Bu kategoride sık kullanılanlar: \(öneri).",
                tone: .neutral))
        }

        if !t.isEmpty && t.rangeOfCharacter(from: .decimalDigits) == nil {
            out.append(Insight(
                icon: "number",
                title: "Sayısal bir eşik koy",
                body: "“Artar/azalır” yerine bir rakam söyle. Hangi değerin üstü seni haklı, altı haksız çıkarır?",
                tone: .neutral))
        }

        // Piyasayla ayrışma
        let myPrice = market.price(for: side)
        if !t.isEmpty && myPrice < 0.35 {
            out.append(Insight(
                icon: "arrow.triangle.branch",
                title: "Kalabalıkla ters düşüyorsun",
                body: "Piyasa \(side.title) tarafına yalnızca \(Int(myPrice * 100))¢ veriyor. Diğerlerinin gördüğü ama senin katılmadığın argüman ne?",
                tone: .warning))
        }

        if !t.isEmpty && !ThesisAnalyzer.causalWords.contains(where: { lower.contains($0) }) && t.count >= 60 {
            out.append(Insight(
                icon: "arrow.right.circle",
                title: "Nedeni açıkça bağla",
                body: "“çünkü / dolayısıyla” gibi bir bağlaçla sebebi sonuca bağlarsan gerekçen okunur olur.",
                tone: .neutral))
        }

        if !t.isEmpty && !["ancak", "fakat", "riski", "yanılırsam"].contains(where: { lower.contains($0) }) && t.count >= 80 {
            out.append(Insight(
                icon: "exclamationmark.triangle",
                title: "Seni yanıltacak şey ne?",
                body: "Bir cümleyle karşı senaryoyu da yaz. En iyi tahminciler nerede yanılabileceklerini baştan söyler.",
                tone: .neutral))
        }

        if out.isEmpty {
            out.append(Insight(
                icon: "checkmark.seal",
                title: "Gerekçe hazır",
                body: "Mekanizma, sayısal eşik ve kaynaklar yerinde. Bu gerekçe sicilinle birlikte kaydedilecek.",
                tone: .positive))
        }
        return out
    }

    // Sicil analizi
    func trackRecord(card: ScoreCard, name: String) -> [Insight] {
        guard card.resolved > 0 else {
            return [Insight(icon: "hourglass",
                            title: "Henüz sonuçlanmış tahminin yok",
                            body: "İlk piyasaların çözüldüğünde burada isabet analizin oluşacak.",
                            tone: .neutral)]
        }
        var out: [Insight] = []
        let ad = name.split(separator: " ").first.map(String.init) ?? name

        if let best = card.best, best.score >= card.score + 3 {
            out.append(Insight(
                icon: best.category.icon,
                title: "\(ad) özellikle \(best.category.title.lowercased()) tahminlerinde başarılı",
                body: "\(best.resolved) sonuçlanan tahminin \(best.correct) tanesi doğru — bu kategorideki skoru \(best.score).",
                tone: .positive))
        }
        if let worst = card.worst, worst.score <= card.score - 3 {
            out.append(Insight(
                icon: worst.category.icon,
                title: "\(worst.category.title) tarafı zayıf halkan",
                body: "\(worst.resolved) tahminin \(worst.correct) doğru, skor \(worst.score). Bu kategoride daha küçük pozisyon almayı dene.",
                tone: .negative))
        }

        if card.shortTerm.n >= 3 && card.longTerm.n >= 3 {
            let s = Int(card.shortTerm.accuracy * 100)
            let l = Int(card.longTerm.accuracy * 100)
            if abs(s - l) >= 12 {
                let kısaDaha = s > l
                out.append(Insight(
                    icon: "timer",
                    title: kısaDaha ? "Kısa vadede daha isabetlisin" : "Uzun vadede daha isabetlisin",
                    body: "Kısa vadeli (≤30 gün) tahminlerinde %\(s), uzun vadelilerde %\(l) doğruluk.",
                    tone: .neutral))
            }
        }

        if abs(card.bias) > 0.10 {
            let iyimser = card.bias > 0
            out.append(Insight(
                icon: iyimser ? "arrow.up.right" : "arrow.down.right",
                title: iyimser ? "Fazla iyimsersin" : "Fazla temkinlisin",
                body: iyimser
                    ? "Verdiğin olasılıklar gerçekleşenden ortalama \(Int(abs(card.bias) * 100)) puan yüksek. Emin olduğun yerde biraz geri çekil."
                    : "Verdiğin olasılıklar gerçekleşenden ortalama \(Int(abs(card.bias) * 100)) puan düşük. Haklı olduğunda daha cesur ol.",
                tone: .warning))
        }

        if card.contrarian.n >= 3 {
            let r = Int(Double(card.contrarian.correct) / Double(card.contrarian.n) * 100)
            out.append(Insight(
                icon: "arrow.triangle.swap",
                title: "Kalabalığa karşı gitme sicilin",
                body: "45¢ altından girdiğin \(card.contrarian.n) tahminin \(card.contrarian.correct) tanesi tuttu (%\(r)). \(r >= 50 ? "Ucuz tarafları görebiliyorsun." : "Ucuz olan çoğu zaman haklı sebeple ucuz.")",
                tone: r >= 50 ? .positive : .negative))
        }

        if card.streak >= 3 {
            out.append(Insight(
                icon: "flame",
                title: "\(card.streak) tahminlik doğru seri",
                body: "Üst üste \(card.streak) piyasada haklı çıktın. Seriler geriye dönük anlatıdır — bir sonraki tahminde de aynı özeni göster.",
                tone: .positive))
        }

        out.append(Insight(
            icon: "target",
            title: "Brier skorun \(Fmt.decimal(card.brier, decimals: 3))",
            body: card.brier < 0.25
                ? "Yazı-turadan (0,250) iyisin. Skorun bu farktan geliyor."
                : "Yazı-tura 0,250 verir; şu an onun gerisindesin. Emin olmadığın piyasalarda 50¢'e yakın kal.",
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
            title: "Kalabalık \(p)¢ diyor",
            body: "Bu, “\(market.question)” sorusuna %\(p) olasılık biçildiği anlamına gelir. Son 24 saatte \(Fmt.signedDecimal(chg)) puan hareket.",
            tone: .neutral))

        if abs(chg) >= 4 {
            out.append(Insight(
                icon: chg > 0 ? "arrow.up.right.circle" : "arrow.down.right.circle",
                title: chg > 0 ? "Beklenti hızla yükseliyor" : "Beklenti hızla düşüyor",
                body: "24 saatte \(Fmt.decimal(abs(chg))) puanlık hareket bu piyasa için sert. Fiyatı taşıyan haberi bulmadan pozisyon alma.",
                tone: .warning))
        }

        if market.daysLeft <= 7 && market.status == .open {
            out.append(Insight(
                icon: "clock.badge.exclamationmark",
                title: "Kapanışa \(market.daysLeft) gün",
                body: "Vade yaklaştıkça fiyat sonuca doğru sertleşir; yanılma payın azalır.",
                tone: .warning))
        }

        let yesCount = theses.filter { $0.side == .yes }.count
        let noCount = theses.count - yesCount
        if theses.count >= 2 {
            out.append(Insight(
                icon: "text.bubble",
                title: "Gerekçelerin dağılımı",
                body: "\(theses.count) gerekçeden \(yesCount) tanesi EVET, \(noCount) tanesi HAYIR tarafında. \(yesCount == noCount ? "Tam bölünmüş bir piyasa." : (yesCount > noCount ? "Yazanların çoğu EVET'te." : "Yazanların çoğu HAYIR'da."))",
                tone: .neutral))
        }

        if let top = theses.max(by: { $0.quality < $1.quality }), top.quality >= 60 {
            out.append(Insight(
                icon: "star",
                title: "En sağlam gerekçe: \(top.authorName)",
                body: "\(top.sources.count) kaynakla desteklenmiş, kalite \(top.quality)/100, \(top.side.title) tarafında.",
                tone: .positive))
        }

        return out
    }
}
