import Foundation

struct SettlementSeed {
    var q: LText
    var cat: Category
    var outcome: Bool
    var side: Side
    var entryYes: Double
    var shares: Double
    var horizon: Int
    var daysAgo: Int
}

struct ThesisSeed {
    var marketId: String
    var author: String
    var score: Int
    var side: Side
    var price: Double
    var text: LText
    var sources: [LText]
    var upvotes: Int
    var hoursAgo: Int
}

private func t(_ tr: String, _ en: String) -> LText { LText(tr, en) }

enum SeedPeople {

    // MARK: Lig katılımcıları

    static let traders: [Trader] = [
        Trader(id: "t1", name: "Ahmet Yıldırım", handle: "ahmety", avatarSeed: 1,
               cash: 148_200, score: 81, resolvedCount: 214, correctCount: 158, streak: 6,
               title: t("Makro", "Macro")),
        Trader(id: "t2", name: "Mehmet Doğan", handle: "mdogan", avatarSeed: 2,
               cash: 139_820, score: 77, resolvedCount: 186, correctCount: 131, streak: 2,
               title: t("Spor", "Sports")),
        Trader(id: "t3", name: "Zeynep Kaya", handle: "zkaya", avatarSeed: 3,
               cash: 131_440, score: 84, resolvedCount: 142, correctCount: 109, streak: 9,
               title: t("Kalibrasyon canavarı", "Calibration monster")),
        Trader(id: "t4", name: "Elif Şahin", handle: "elifs", avatarSeed: 4,
               cash: 118_760, score: 72, resolvedCount: 168, correctCount: 112, streak: 0,
               title: t("Teknoloji", "Tech")),
        Trader(id: "t5", name: "Burak Aslan", handle: "baslan", avatarSeed: 5,
               cash: 104_330, score: 69, resolvedCount: 121, correctCount: 78, streak: 3, title: nil),
        Trader(id: "t6", name: "Selin Arıkan", handle: "selinar", avatarSeed: 6,
               cash: 97_540, score: 74, resolvedCount: 98, correctCount: 68, streak: 4,
               title: t("Enerji", "Energy")),
        Trader(id: "t7", name: "Emre Koç", handle: "emrekoc", avatarSeed: 7,
               cash: 91_220, score: 63, resolvedCount: 205, correctCount: 122, streak: 1, title: nil),
        Trader(id: "t8", name: "Deniz Yalçın", handle: "dyalcin", avatarSeed: 8,
               cash: 84_910, score: 70, resolvedCount: 88, correctCount: 59, streak: 2,
               title: t("Kültür", "Culture")),
        Trader(id: "t9", name: "Ayşe Tunç", handle: "aysetunc", avatarSeed: 9,
               cash: 76_400, score: 66, resolvedCount: 133, correctCount: 84, streak: 0, title: nil),
        Trader(id: "t10", name: "Kerem Özkan", handle: "keremoz", avatarSeed: 10,
               cash: 68_150, score: 58, resolvedCount: 76, correctCount: 43, streak: 0, title: nil),
        Trader(id: "t11", name: "Merve Bilgin", handle: "mervebil", avatarSeed: 11,
               cash: 61_770, score: 61, resolvedCount: 59, correctCount: 36, streak: 1, title: nil),
        Trader(id: "t12", name: "Onur Çetin", handle: "onurc", avatarSeed: 12,
               cash: 54_200, score: 55, resolvedCount: 112, correctCount: 62, streak: 0, title: nil),
        Trader(id: "t13", name: "İrem Baş", handle: "irembas", avatarSeed: 13,
               cash: 47_880, score: 64, resolvedCount: 44, correctCount: 29, streak: 3,
               title: t("Yeni", "New")),
        Trader(id: "t14", name: "Hakan Ertürk", handle: "hakane", avatarSeed: 14,
               cash: 39_610, score: 49, resolvedCount: 91, correctCount: 44, streak: 0, title: nil),
        Trader(id: "t15", name: "Ceren Aydın", handle: "cerena", avatarSeed: 15,
               cash: 31_050, score: 52, resolvedCount: 38, correctCount: 20, streak: 1, title: nil),
    ]

    // MARK: Kullanıcının örnek sicili
    //
    // Teknolojide güçlü, ekonomide zayıf bir profil — Öngörü Skoru'nun
    // kategori kırılımını ilk açılışta görünür kılmak için.

    static let settlements: [SettlementSeed] = [
        SettlementSeed(q: t("iPhone 16 Pro Türkiye fiyatı 90.000 TL'yi aştı mı?",
                            "Did the iPhone 16 Pro exceed ₺90,000 in Türkiye?"),
                       cat: .teknoloji, outcome: true, side: .yes, entryYes: 0.72,
                       shares: 40, horizon: 24, daysAgo: 210),
        SettlementSeed(q: t("Starlink Türkiye'de 2025'te ticari hizmete başladı mı?",
                            "Did Starlink launch commercially in Türkiye in 2025?"),
                       cat: .teknoloji, outcome: false, side: .no, entryYes: 0.30,
                       shares: 55, horizon: 120, daysAgo: 96),
        SettlementSeed(q: t("5G ihalesi 2025 içinde yapıldı mı?",
                            "Was the 5G spectrum auction held during 2025?"),
                       cat: .teknoloji, outcome: true, side: .yes, entryYes: 0.61,
                       shares: 35, horizon: 90, daysAgo: 140),
        SettlementSeed(q: t("TOGG 2025'te yurt dışına 10 binden fazla araç sattı mı?",
                            "Did TOGG export more than 10,000 vehicles in 2025?"),
                       cat: .teknoloji, outcome: false, side: .yes, entryYes: 0.55,
                       shares: 25, horizon: 150, daysAgo: 80),
        SettlementSeed(q: t("Bir Türk yapay zekâ girişimi 2025'te 50 milyon $ yatırım aldı mı?",
                            "Did a Turkish AI startup raise $50M in 2025?"),
                       cat: .teknoloji, outcome: true, side: .yes, entryYes: 0.66,
                       shares: 30, horizon: 100, daysAgo: 62),

        SettlementSeed(q: t("TCMB politika faizi Eylül 2025'te %40'ın altına indi mi?",
                            "Did the CBRT policy rate fall below 40% in September 2025?"),
                       cat: .ekonomi, outcome: true, side: .no, entryYes: 0.44,
                       shares: 45, horizon: 60, daysAgo: 175),
        SettlementSeed(q: t("Yıllık enflasyon Ağustos 2025'te %35'in altına indi mi?",
                            "Did annual inflation fall below 35% in August 2025?"),
                       cat: .ekonomi, outcome: false, side: .yes, entryYes: 0.58,
                       shares: 38, horizon: 45, daysAgo: 190),
        SettlementSeed(q: t("Dolar/TL 2025'te 45'i gördü mü?",
                            "Did USD/TRY reach 45 in 2025?"),
                       cat: .ekonomi, outcome: false, side: .yes, entryYes: 0.63,
                       shares: 50, horizon: 200, daysAgo: 70),
        SettlementSeed(q: t("Gram altın 2025'te 5.000 TL'yi aştı mı?",
                            "Did gram gold exceed ₺5,000 in 2025?"),
                       cat: .ekonomi, outcome: true, side: .yes, entryYes: 0.70,
                       shares: 42, horizon: 180, daysAgo: 120),
        SettlementSeed(q: t("2025'te asgari ücrete ara zam yapıldı mı?",
                            "Was there a mid-year minimum wage hike in 2025?"),
                       cat: .ekonomi, outcome: false, side: .no, entryYes: 0.38,
                       shares: 60, horizon: 150, daysAgo: 55),

        SettlementSeed(q: t("Galatasaray 2024-25 Süper Lig şampiyonu oldu mu?",
                            "Did Galatasaray win the 2024-25 Süper Lig?"),
                       cat: .spor, outcome: true, side: .yes, entryYes: 0.62,
                       shares: 48, horizon: 240, daysAgo: 130),
        SettlementSeed(q: t("Türkiye EURO 2024'te çeyrek finale çıktı mı?",
                            "Did Türkiye reach the EURO 2024 quarter-finals?"),
                       cat: .spor, outcome: true, side: .yes, entryYes: 0.34,
                       shares: 30, horizon: 20, daysAgo: 400),
        SettlementSeed(q: t("Fenerbahçe 2024-25 Avrupa Ligi'nde yarı finale çıktı mı?",
                            "Did Fenerbahçe reach the 2024-25 Europa League semi-finals?"),
                       cat: .spor, outcome: false, side: .yes, entryYes: 0.48,
                       shares: 36, horizon: 60, daysAgo: 150),

        SettlementSeed(q: t("BIST 100 2025'te 12.000 puanı gördü mü?",
                            "Did the BIST 100 reach 12,000 in 2025?"),
                       cat: .sirketler, outcome: true, side: .yes, entryYes: 0.55,
                       shares: 44, horizon: 120, daysAgo: 90),
        SettlementSeed(q: t("THY 2025'te 100 milyon yolcuyu aştı mı?",
                            "Did Turkish Airlines exceed 100 million passengers in 2025?"),
                       cat: .sirketler, outcome: false, side: .no, entryYes: 0.42,
                       shares: 33, horizon: 180, daysAgo: 48),

        SettlementSeed(q: t("2025'te bir yerli film 5 milyon bilet sattı mı?",
                            "Did a Turkish film sell 5 million tickets in 2025?"),
                       cat: .kultur, outcome: false, side: .yes, entryYes: 0.52,
                       shares: 22, horizon: 150, daysAgo: 65),
        SettlementSeed(q: t("Türkiye 2026 Eurovision'a katılım açıkladı mı?",
                            "Did Türkiye announce participation in Eurovision 2026?"),
                       cat: .kultur, outcome: false, side: .no, entryYes: 0.28,
                       shares: 40, horizon: 70, daysAgo: 44),

        SettlementSeed(q: t("İstanbul'a Ocak 2025'te kar yağdı mı?",
                            "Did it snow in Istanbul in January 2025?"),
                       cat: .hava, outcome: true, side: .yes, entryYes: 0.80,
                       shares: 50, horizon: 25, daysAgo: 220),
    ]

    // MARK: Gerekçeler

    static let theses: [ThesisSeed] = [
        ThesisSeed(marketId: "eko-faiz-30", author: "Zeynep Kaya", score: 84, side: .yes, price: 0.59,
                   text: t("Dezenflasyon patikası bozulmadığı sürece TCMB'nin yıl sonuna kadar toplamda 1200 baz puanlık indirim alanı var. Son iki PPK metninde \"temkinli\" vurgusunun yumuşaması bunun sinyaliydi. Ancak gıda enflasyonunda yeni bir şok gelirse patika kayar.",
                           "As long as the disinflation path holds, the CBRT has room for roughly 1,200 basis points of cuts by year-end. The softening of the \"cautious\" language in the last two MPC statements signalled this. However, a fresh food-price shock would push the path back."),
                   sources: [t("TCMB PPK Ekim metni", "CBRT MPC October statement"),
                             t("TCMB Piyasa Katılımcıları Anketi", "CBRT Market Participants Survey"),
                             t("TÜİK aylık TÜFE serisi", "TurkStat monthly CPI series")],
                   upvotes: 218, hoursAgo: 9),

        ThesisSeed(marketId: "eko-faiz-30", author: "Emre Koç", score: 63, side: .no, price: 0.41,
                   text: t("Kur tarafındaki baskı devam ederse indirim hızının kesileceğini düşünüyorum. Geçmişte de %30 bandına inildiğinde politika duraklamıştı.",
                           "If FX pressure persists I think the pace of cuts stalls. Historically policy has paused whenever the rate approached the 30% band."),
                   sources: [t("TCMB rezerv verisi", "CBRT reserve data")],
                   upvotes: 74, hoursAgo: 21),

        ThesisSeed(marketId: "eko-enf-20", author: "Ahmet Yıldırım", score: 81, side: .no, price: 0.70,
                   text: t("Hizmet enflasyonu katılığı sürüyor; kira ve eğitim kalemleri tek başına yıllık 6-7 puanlık taban oluşturuyor. %20 için hizmetlerin %25 altına inmesi gerekir, bu 12 ayda gerçekçi değil çünkü ücret güncellemeleri yıl başında yapılıyor.",
                           "Services inflation remains sticky; rent and education alone create a 6-7 point annual floor. Getting to 20% requires services below 25%, which isn't realistic in 12 months because wage updates land at the start of the year."),
                   sources: [t("TÜİK hizmet enflasyonu alt kalemleri", "TurkStat services inflation components"),
                             t("TCMB Enflasyon Raporu IV", "CBRT Inflation Report IV"),
                             t("Kira endeksi verisi", "Rent index data")],
                   upvotes: 341, hoursAgo: 4),

        ThesisSeed(marketId: "eko-konut-20", author: "Selin Arıkan", score: 74, side: .yes, price: 0.63,
                   text: t("İstanbul'da konut arzı yeni deprem yönetmeliği sonrası ciddi daraldı. Ruhsat sayıları geçen yıla göre %30 düşükken talep yerinde; dolayısıyla nominal artışın enflasyonun üzerine çıkması olası.",
                           "Housing supply in Istanbul tightened significantly after the new earthquake code. Permits are down 30% year-on-year while demand holds, so nominal increases outpacing inflation is likely."),
                   sources: [t("TÜİK yapı ruhsatı istatistikleri", "TurkStat building permit statistics"),
                             t("TCMB Konut Fiyat Endeksi", "CBRT House Price Index"),
                             t("Endeksa İstanbul m² verisi", "Endeksa Istanbul price-per-m² data")],
                   upvotes: 156, hoursAgo: 14),

        ThesisSeed(marketId: "eko-usd-60", author: "Burak Aslan", score: 69, side: .yes, price: 0.55,
                   text: t("Reel kur endeksi hâlâ tarihi ortalamanın üzerinde. Cari açık kapanmadan bu seviyenin korunması zor.",
                           "The real effective exchange rate is still above its historical average. Holding this level is hard without the current account gap closing."),
                   sources: [t("TCMB reel efektif döviz kuru", "CBRT real effective exchange rate"),
                             t("Ödemeler dengesi bülteni", "Balance of payments bulletin")],
                   upvotes: 98, hoursAgo: 30),

        ThesisSeed(marketId: "tek-iphone-100k", author: "Elif Şahin", score: 72, side: .yes, price: 0.74,
                   text: t("Geçen üç lansmanda Türkiye fiyatı ortalama %38 zamlandı. Bu yılki ÖTV matrah dilimleri ve kur seviyesiyle en ucuz Pro modelin 100.000 TL altında kalması ancak Apple'ın Türkiye'ye özel indirim yapmasıyla mümkün — ki bunun örneği yok.",
                           "Across the last three launches the Türkiye price rose 38% on average. With this year's excise tax brackets and the exchange rate, the cheapest Pro staying under ₺100,000 would require an Türkiye-specific discount from Apple — for which there is no precedent."),
                   sources: [t("Apple TR geçmiş fiyat listesi", "Apple TR historical price list"),
                             t("ÖTV matrah dilimi tebliği", "Excise tax bracket communiqué"),
                             t("TCMB kur projeksiyonu", "CBRT exchange rate projection")],
                   upvotes: 402, hoursAgo: 6),

        ThesisSeed(marketId: "tek-iphone-100k", author: "İrem Baş", score: 64, side: .no, price: 0.26,
                   text: t("Apple bu yıl baz modelin fiyatını sabit tutma eğiliminde. Pro tarafında da agresif zam gelmeyebilir.",
                           "Apple seems inclined to hold the base model price this year. The Pro line may not see an aggressive hike either."),
                   sources: [], upvotes: 31, hoursAgo: 40),

        ThesisSeed(marketId: "tek-5g", author: "Ahmet Yıldırım", score: 81, side: .yes, price: 0.66,
                   text: t("İhale takvimi açıklandı ve operatörlerin altyapı yatırımı şimdiden başladı. Frekans tahsisi tamamlandıktan sonra ticari açılışın 6 ay içinde yapılması sektör normu.",
                           "The auction calendar is out and operators have already begun infrastructure spending. Commercial launch within six months of spectrum allocation is the industry norm."),
                   sources: [t("BTK ihale şartnamesi", "ICTA auction specification"),
                             t("Operatör yatırım planı sunumu", "Operator capex plan presentation")],
                   upvotes: 187, hoursAgo: 11),

        ThesisSeed(marketId: "tek-togg", author: "Kerem Özkan", score: 58, side: .no, price: 0.72,
                   text: t("Aylık 5.000 bandı mevcut üretim kapasitesinin neredeyse tamamı demek. Gemlik'te ikinci hat devreye girmeden bu rakam zor.",
                           "5,000 a month is nearly the entirety of current production capacity. That figure is hard to reach before the second line at Gemlik comes online."),
                   sources: [t("ODMD aylık satış raporu", "ODMD monthly sales report"),
                             t("TOGG kapasite açıklaması", "TOGG capacity statement")],
                   upvotes: 112, hoursAgo: 26),

        ThesisSeed(marketId: "spor-gs-lig", author: "Mehmet Doğan", score: 77, side: .yes, price: 0.45,
                   text: t("Puan farkı 4'e indi ama fikstür avantajı bizde: kalan 6 maçın 4'ü iç saha ve ilk 5 takımdan sadece biriyle oynanacak. Buna karşın sakatlık listesi uzarsa tablo değişir.",
                           "The gap is down to 4 points but the fixture edge is ours: four of the remaining six are at home and only one is against a top-five side. That said, a lengthening injury list changes the picture."),
                   sources: [t("TFF fikstürü", "TFF fixture list"),
                             t("Kulüp sakatlık raporu", "Club injury report"),
                             t("Son 10 maç puan ortalaması", "Points per game over last 10")],
                   upvotes: 289, hoursAgo: 3),

        ThesisSeed(marketId: "spor-fb-lig", author: "Deniz Yalçın", score: 70, side: .no, price: 0.66,
                   text: t("Deplasmanda alınan puan ortalaması şampiyonluk için gereken bandın altında. Zirve yarışında bu fark 6 maçta kapanmaz.",
                           "Away points per game sit below the band required for a title run. That gap doesn't close over six matches in a race this tight."),
                   sources: [t("TFF puan durumu", "TFF league table"),
                             t("Deplasman puan ortalaması", "Away points per game")],
                   upvotes: 143, hoursAgo: 8),

        ThesisSeed(marketId: "siy-euro-2027", author: "Ayşe Tunç", score: 66, side: .no, price: 0.96,
                   text: t("Euro'ya geçiş için önce AB üyeliği, sonra en az iki yıl ERM II üyeliği gerekiyor. Takvim matematiksel olarak 2027'ye sığmıyor.",
                           "Euro adoption requires EU membership first, then at least two years in ERM II. The timeline mathematically does not fit into 2027."),
                   sources: [t("AB Maastricht kriterleri", "EU Maastricht criteria"),
                             t("ERM II süreç belgesi", "ERM II process document")],
                   upvotes: 521, hoursAgo: 18),

        ThesisSeed(marketId: "kul-dizi-top10", author: "Deniz Yalçın", score: 70, side: .yes, price: 0.68,
                   text: t("Son üç yıldır Türk yapımları İngilizce dışı listesinde ortalama 9 hafta ilk 10'da kaldı. 2026'da platformun Türkiye yapım bütçesi de artıyor.",
                           "Over the last three years Turkish productions have averaged nine weeks in the non-English top 10. The platform's Türkiye production budget is also rising for 2026."),
                   sources: [t("Netflix Top 10 arşivi", "Netflix Top 10 archive"),
                             t("Platform yatırım duyurusu", "Platform investment announcement"),
                             t("Yapımcı birliği raporu", "Producers' association report")],
                   upvotes: 96, hoursAgo: 16),

        ThesisSeed(marketId: "hava-kar", author: "Selin Arıkan", score: 74, side: .yes, price: 0.61,
                   text: t("ECMWF ensemble çıktısı önümüzdeki 10 gün için soğuk hava dalgasını %70 olasılıkla veriyor. Son 30 yılın 22'sinde İstanbul bu eşiği aştı.",
                           "The ECMWF ensemble puts a cold spell at 70% probability over the next 10 days. Istanbul has crossed this threshold in 22 of the last 30 years."),
                   sources: [t("ECMWF ensemble", "ECMWF ensemble"),
                             t("MGM 30 yıllık iklim normalleri", "30-year climate normals")],
                   upvotes: 204, hoursAgo: 2),

        ThesisSeed(marketId: "eko-bist-20k", author: "Zeynep Kaya", score: 84, side: .no, price: 0.59,
                   text: t("20.000 için endeksin dolar bazında 2021 zirvesini geçmesi gerekiyor. Reel getiri beklentisi mevduatın altındayken bu giriş zor; ancak faiz indirimleri hızlanırsa senaryo değişir.",
                           "Reaching 20,000 requires the index to clear its 2021 peak in dollar terms. That inflow is hard while expected real returns sit below deposit rates — though the scenario changes if rate cuts accelerate."),
                   sources: [t("BIST 100 dolar bazlı seri", "BIST 100 dollar-based series"),
                             t("Mevduat faizi ortalaması", "Average deposit rate"),
                             t("Yabancı takas oranı", "Foreign ownership ratio")],
                   upvotes: 178, hoursAgo: 12),

        ThesisSeed(marketId: "sir-halka-arz", author: "Onur Çetin", score: 55, side: .yes, price: 0.58,
                   text: t("SPK onay bekleyen dosya sayısı şu an 41. Geçmiş yıllarda bu havuzun yaklaşık %70'i aynı yıl içinde işlem görmeye başladı.",
                           "There are currently 41 filings awaiting regulatory approval. Historically about 70% of that pool starts trading within the same year."),
                   sources: [t("SPK haftalık bülten", "CMB weekly bulletin"),
                             t("Borsa İstanbul halka arz arşivi", "Borsa Istanbul IPO archive")],
                   upvotes: 67, hoursAgo: 22),

        ThesisSeed(marketId: "tek-starlink", author: "Elif Şahin", score: 72, side: .no, price: 0.65,
                   text: t("Yer istasyonu ve veri yerelleştirme şartı çözülmeden lisans çıkmıyor. Görüşmeler iki yıldır aynı noktada.",
                           "No licence issues until the ground station and data localisation requirements are resolved. Talks have been at the same point for two years."),
                   sources: [t("BTK mevzuat çerçevesi", "ICTA regulatory framework"),
                             t("Şirket başvuru duyurusu", "Company application announcement")],
                   upvotes: 121, hoursAgo: 33),

        ThesisSeed(marketId: "eko-asgari-reel", author: "Ahmet Yıldırım", score: 81, side: .no, price: 0.55,
                   text: t("Son beş yılın dördünde zam, gerçekleşen enflasyonun altında kaldı. Bütçe disiplini hedefi varken reel artış politika tercihi olarak zayıf ihtimal.",
                           "In four of the last five years the hike came in below realised inflation. With a fiscal discipline target in place, a real increase is a weak policy bet."),
                   sources: [t("Asgari ücret tarihsel serisi", "Minimum wage historical series"),
                             t("TÜİK yıllık TÜFE", "TurkStat annual CPI"),
                             t("OVP hedefleri", "Medium-Term Programme targets")],
                   upvotes: 267, hoursAgo: 7),
    ]
}
