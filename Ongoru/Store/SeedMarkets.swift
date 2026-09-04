import Foundation

/// Kaynak veri. Gerçek üründe bunun yerine sunucudan gelen piyasa listesi olur.
struct MarketSeed {
    var id: String
    var q: LText
    var detail: LText
    var source: LText
    var cat: Category
    var price: Double
    var b: Double
    var volume: Int
    var participants: Int
    var openedDaysAgo: Int
    var closesInDays: Int
    var topic: IndexTopic? = nil
}

private func t(_ tr: String, _ en: String) -> LText { LText(tr, en) }

enum SeedMarkets {

    static let all: [MarketSeed] = ekonomi + siyaset + spor + teknoloji + sirketler + kultur + hava

    // MARK: Ekonomi

    static let ekonomi: [MarketSeed] = [
        MarketSeed(id: "eko-faiz-30",
                   q: t("TCMB politika faizi 2026 yıl sonunda %30'un altında mı olacak?",
                        "Will the CBRT policy rate be below 30% at the end of 2026?"),
                   detail: t("31 Aralık 2026 itibarıyla TCMB bir hafta vadeli repo ihale faiz oranı %30,00'ın altındaysa EVET.",
                             "YES if the CBRT one-week repo auction rate is below 30.00% as of 31 December 2026."),
                   source: t("TCMB PPK kararı duyurusu", "CBRT MPC decision announcement"),
                   cat: .ekonomi, price: 0.63, b: 900,
                   volume: 184_231, participants: 12_482, openedDaysAgo: 96, closesInDays: 118,
                   topic: .faizDusecek),

        MarketSeed(id: "eko-enf-20",
                   q: t("Yıllık enflasyon Aralık 2026'da %20'nin altına iner mi?",
                        "Will annual inflation fall below 20% in December 2026?"),
                   detail: t("TÜİK'in Aralık 2026 dönemi için açıkladığı yıllık TÜFE değişimi %20,00'ın altındaysa EVET.",
                             "YES if the annual CPI change published by TurkStat for December 2026 is below 20.00%."),
                   source: t("TÜİK Tüketici Fiyat Endeksi bülteni", "TurkStat Consumer Price Index bulletin"),
                   cat: .ekonomi, price: 0.31, b: 850,
                   volume: 221_904, participants: 15_318, openedDaysAgo: 110, closesInDays: 120,
                   topic: .enflasyonDusecek),

        MarketSeed(id: "eko-usd-60",
                   q: t("Dolar/TL 2026 sonunda 60'ın üzerinde mi olacak?",
                        "Will USD/TRY be above 60 at the end of 2026?"),
                   detail: t("31 Aralık 2026 TCMB gösterge alış kuru 60,0000 TL'nin üzerindeyse EVET.",
                             "YES if the CBRT indicative buying rate on 31 December 2026 is above 60.0000."),
                   source: t("TCMB gösterge niteliğindeki kurlar", "CBRT indicative exchange rates"),
                   cat: .ekonomi, price: 0.58, b: 1000,
                   volume: 312_770, participants: 19_045, openedDaysAgo: 120, closesInDays: 118,
                   topic: .dovizYukselecek),

        MarketSeed(id: "eko-altin-8000",
                   q: t("Gram altın 2026'da 8.000 TL'yi geçer mi?",
                        "Will gram gold exceed ₺8,000 during 2026?"),
                   detail: t("Kapalıçarşı gram altın satış fiyatı 2026 içinde herhangi bir kapanışta 8.000 TL üzerindeyse EVET.",
                             "YES if the Grand Bazaar gram gold ask price closes above ₺8,000 on any day in 2026."),
                   source: t("İstanbul Altın Rafinerisi / Kapalıçarşı kapanış",
                             "Istanbul Gold Refinery / Grand Bazaar close"),
                   cat: .ekonomi, price: 0.72, b: 800,
                   volume: 156_402, participants: 11_206, openedDaysAgo: 88, closesInDays: 118,
                   topic: .altinYukselecek),

        MarketSeed(id: "eko-konut-20",
                   q: t("İstanbul'da konut fiyatları 2026'da %20'den fazla artar mı?",
                        "Will Istanbul housing prices rise more than 20% in 2026?"),
                   detail: t("TCMB Konut Fiyat Endeksi İstanbul serisinin Aralık 2026 yıllık artışı %20,0'ın üzerindeyse EVET.",
                             "YES if the December 2026 annual increase in the CBRT House Price Index for Istanbul exceeds 20.0%."),
                   source: t("TCMB Konut Fiyat Endeksi", "CBRT House Price Index"),
                   cat: .ekonomi, price: 0.66, b: 700,
                   volume: 98_551, participants: 8_774, openedDaysAgo: 74, closesInDays: 140,
                   topic: .konutArtacak),

        MarketSeed(id: "eko-bist-20k",
                   q: t("BIST 100 endeksi 2026'da 20.000 puanı görür mü?",
                        "Will the BIST 100 index reach 20,000 in 2026?"),
                   detail: t("BIST 100 kapanış değeri 2026 içinde en az bir gün 20.000'in üzerindeyse EVET.",
                             "YES if the BIST 100 closes above 20,000 on at least one day in 2026."),
                   source: t("Borsa İstanbul günlük bülten", "Borsa Istanbul daily bulletin"),
                   cat: .ekonomi, price: 0.41, b: 750,
                   volume: 143_889, participants: 10_330, openedDaysAgo: 65, closesInDays: 118,
                   topic: .borsaYukselecek),

        MarketSeed(id: "eko-issizlik-10",
                   q: t("İşsizlik oranı 2026'da %10'un üzerine çıkar mı?",
                        "Will the unemployment rate exceed 10% in 2026?"),
                   detail: t("TÜİK mevsim etkisinden arındırılmış işsizlik oranı 2026'da herhangi bir ayda %10,0'ı aşarsa EVET.",
                             "YES if TurkStat's seasonally adjusted unemployment rate exceeds 10.0% in any month of 2026."),
                   source: t("TÜİK İşgücü İstatistikleri", "TurkStat Labour Force Statistics"),
                   cat: .ekonomi, price: 0.37, b: 600,
                   volume: 61_204, participants: 5_918, openedDaysAgo: 52, closesInDays: 118,
                   topic: .issizlikArtacak),

        MarketSeed(id: "eko-asgari-reel",
                   q: t("2027 asgari ücret zammı yıllık enflasyonun üzerinde olur mu?",
                        "Will the 2027 minimum wage hike exceed annual inflation?"),
                   detail: t("Açıklanan 2027 net asgari ücret artış oranı, Aralık 2026 yıllık TÜFE'nin üzerindeyse EVET.",
                             "YES if the announced 2027 net minimum wage increase exceeds the December 2026 annual CPI."),
                   source: t("Asgari Ücret Tespit Komisyonu kararı + TÜİK",
                             "Minimum Wage Commission decision + TurkStat"),
                   cat: .ekonomi, price: 0.44, b: 700,
                   volume: 189_337, participants: 21_774, openedDaysAgo: 40, closesInDays: 112,
                   topic: .asgariReel),

        MarketSeed(id: "eko-buyume-4",
                   q: t("Türkiye ekonomisi 2026'da %4'ten fazla büyür mü?",
                        "Will Türkiye's economy grow more than 4% in 2026?"),
                   detail: t("TÜİK'in açıklayacağı 2026 yıllık GSYH büyümesi %4,0'ın üzerindeyse EVET.",
                             "YES if TurkStat's reported 2026 annual GDP growth exceeds 4.0%."),
                   source: t("TÜİK Dönemsel GSYH", "TurkStat Quarterly GDP"),
                   cat: .ekonomi, price: 0.35, b: 650,
                   volume: 54_118, participants: 4_902, openedDaysAgo: 60, closesInDays: 150,
                   topic: .ekonomiBuyuyecek),

        MarketSeed(id: "eko-kk-faiz",
                   q: t("Kredi kartı azami akdi faiz oranı 2026'da düşürülür mü?",
                        "Will the maximum credit card interest rate be cut in 2026?"),
                   detail: t("TCMB'nin belirlediği kredi kartı azami akdi faiz oranı 2026 içinde bir kez bile indirilirse EVET.",
                             "YES if the CBRT lowers the maximum credit card contractual rate at least once during 2026."),
                   source: t("TCMB tebliğ / Resmî Gazete", "CBRT communiqué / Official Gazette"),
                   cat: .ekonomi, price: 0.52, b: 500,
                   volume: 33_640, participants: 3_411, openedDaysAgo: 28, closesInDays: 118,
                   topic: .faizDusecek),
    ]

    // MARK: Siyaset ve kamu

    static let siyaset: [MarketSeed] = [
        MarketSeed(id: "siy-euro-2027",
                   q: t("Türkiye 2027'de Euro'ya geçer mi?",
                        "Will Türkiye adopt the Euro in 2027?"),
                   detail: t("31 Aralık 2027'ye kadar Euro Türkiye'de resmî para birimi olarak yürürlüğe girerse EVET.",
                             "YES if the Euro becomes Türkiye's official currency before 31 December 2027."),
                   source: t("Resmî Gazete", "Official Gazette"),
                   cat: .siyaset, price: 0.04, b: 400,
                   volume: 44_902, participants: 9_118, openedDaysAgo: 130, closesInDays: 300),

        MarketSeed(id: "siy-anayasa",
                   q: t("Yeni anayasa teklifi 2026'da TBMM Genel Kurulu'na iner mi?",
                        "Will a new constitution proposal reach the Turkish Parliament floor in 2026?"),
                   detail: t("Anayasa değişikliği teklifi 2026 içinde Genel Kurul gündemine alınırsa EVET.",
                             "YES if a constitutional amendment proposal is put on the General Assembly agenda during 2026."),
                   source: t("TBMM tutanak ve gündem kayıtları", "Parliamentary records and agenda"),
                   cat: .siyaset, price: 0.38, b: 600,
                   volume: 77_215, participants: 8_003, openedDaysAgo: 70, closesInDays: 118),

        MarketSeed(id: "siy-vize",
                   q: t("AB ile vize serbestisi 2027 sonuna kadar yürürlüğe girer mi?",
                        "Will EU visa-free travel take effect by the end of 2027?"),
                   detail: t("Türk vatandaşları için Schengen bölgesine vizesiz seyahat 31 Aralık 2027'ye kadar başlarsa EVET.",
                             "YES if visa-free Schengen travel for Turkish citizens begins before 31 December 2027."),
                   source: t("AB Resmî Gazetesi / Komisyon kararı",
                             "EU Official Journal / Commission decision"),
                   cat: .siyaset, price: 0.12, b: 500,
                   volume: 128_440, participants: 16_772, openedDaysAgo: 140, closesInDays: 300),

        MarketSeed(id: "siy-butce",
                   q: t("2027 merkezi yönetim bütçe açığı GSYH'nin %4'ünü aşar mı?",
                        "Will the 2027 central government budget deficit exceed 4% of GDP?"),
                   detail: t("Bütçe kanununda öngörülen açık/GSYH oranı %4,0'ın üzerindeyse EVET.",
                             "YES if the deficit-to-GDP ratio in the budget law exceeds 4.0%."),
                   source: t("Hazine ve Maliye Bakanlığı bütçe sunumu",
                             "Ministry of Treasury and Finance budget presentation"),
                   cat: .siyaset, price: 0.49, b: 450,
                   volume: 26_113, participants: 2_884, openedDaysAgo: 22, closesInDays: 96),
    ]

    // MARK: Spor

    static let spor: [MarketSeed] = [
        MarketSeed(id: "spor-gs-lig",
                   q: t("Galatasaray 2025-26 Süper Lig şampiyonu olur mu?",
                        "Will Galatasaray win the 2025-26 Süper Lig?"),
                   detail: t("TFF'nin tescil ettiği 2025-26 Süper Lig şampiyonu Galatasaray ise EVET.",
                             "YES if the TFF-registered 2025-26 Süper Lig champion is Galatasaray."),
                   source: t("TFF resmî tescil", "TFF official registration"),
                   cat: .spor, price: 0.47, b: 900,
                   volume: 402_118, participants: 28_440, openedDaysAgo: 100, closesInDays: 62),

        MarketSeed(id: "spor-fb-lig",
                   q: t("Fenerbahçe 2025-26 Süper Lig şampiyonu olur mu?",
                        "Will Fenerbahçe win the 2025-26 Süper Lig?"),
                   detail: t("TFF'nin tescil ettiği 2025-26 Süper Lig şampiyonu Fenerbahçe ise EVET.",
                             "YES if the TFF-registered 2025-26 Süper Lig champion is Fenerbahçe."),
                   source: t("TFF resmî tescil", "TFF official registration"),
                   cat: .spor, price: 0.34, b: 900,
                   volume: 388_904, participants: 27_115, openedDaysAgo: 100, closesInDays: 62),

        MarketSeed(id: "spor-avrupa-ceyrek",
                   q: t("Bir Türk takımı 2025-26 Avrupa kupalarında çeyrek finale kalır mı?",
                        "Will a Turkish club reach a European quarter-final in 2025-26?"),
                   detail: t("UEFA Şampiyonlar Ligi, Avrupa Ligi veya Konferans Ligi'nde bir Türk kulübü çeyrek finale çıkarsa EVET.",
                             "YES if a Turkish club reaches the quarter-finals of the Champions League, Europa League or Conference League."),
                   source: t("UEFA resmî fikstür", "UEFA official fixtures"),
                   cat: .spor, price: 0.44, b: 700,
                   volume: 155_330, participants: 14_209, openedDaysAgo: 80, closesInDays: 34),

        MarketSeed(id: "spor-fifa-20",
                   q: t("A Millî Takım 2026 sonunda FIFA sıralamasında ilk 20'ye girer mi?",
                        "Will the national team be in the FIFA top 20 at the end of 2026?"),
                   detail: t("FIFA'nın Aralık 2026 sıralamasında Türkiye 20. sıra veya üstündeyse EVET.",
                             "YES if Türkiye ranks 20th or higher in FIFA's December 2026 ranking."),
                   source: t("FIFA dünya sıralaması", "FIFA world ranking"),
                   cat: .spor, price: 0.29, b: 550,
                   volume: 71_664, participants: 9_330, openedDaysAgo: 45, closesInDays: 118),

        MarketSeed(id: "spor-transfer-30m",
                   q: t("2026 yaz döneminde bir Süper Lig kulübü 30 milyon € üzeri transfer harcaması yapar mı?",
                        "Will a Süper Lig club spend over €30M on transfers in summer 2026?"),
                   detail: t("Tek transfer döneminde bir kulübün toplam bonservis gideri 30 milyon € üzerindeyse EVET.",
                             "YES if a single club's total transfer fees exceed €30M in one window."),
                   source: t("Transfermarkt + kulüp KAP açıklamaları",
                             "Transfermarkt + club public disclosures"),
                   cat: .spor, price: 0.51, b: 500,
                   volume: 63_902, participants: 7_118, openedDaysAgo: 30, closesInDays: 210),
    ]

    // MARK: Teknoloji

    static let teknoloji: [MarketSeed] = [
        MarketSeed(id: "tek-iphone-100k",
                   q: t("Bir sonraki iPhone Türkiye'de 100.000 TL'nin üzerinde mi olacak?",
                        "Will the next iPhone cost over ₺100,000 in Türkiye?"),
                   detail: t("Apple Türkiye'nin resmî sitesinde yeni serinin en ucuz Pro modeli 100.000 TL üzerindeyse EVET.",
                             "YES if the cheapest Pro model of the new series is listed above ₺100,000 on Apple Türkiye's site."),
                   source: t("apple.com/tr fiyat listesi", "apple.com/tr price list"),
                   cat: .teknoloji, price: 0.78, b: 800,
                   volume: 267_441, participants: 24_902, openedDaysAgo: 55, closesInDays: 41),

        MarketSeed(id: "tek-starlink",
                   q: t("Starlink Türkiye'de 2026'da ticari hizmete başlar mı?",
                        "Will Starlink launch commercially in Türkiye in 2026?"),
                   detail: t("BTK lisansıyla bireysel kullanıma açık ticari satış 2026 içinde başlarsa EVET.",
                             "YES if licensed commercial retail service to consumers begins during 2026."),
                   source: t("BTK lisans duyurusu", "ICTA licence announcement"),
                   cat: .teknoloji, price: 0.33, b: 600,
                   volume: 92_004, participants: 11_440, openedDaysAgo: 62, closesInDays: 118),

        MarketSeed(id: "tek-5g",
                   q: t("5G Türkiye'de 2026'da ticari olarak kullanıma açılır mı?",
                        "Will 5G go commercially live in Türkiye in 2026?"),
                   detail: t("En az bir operatör 2026 içinde bireysel abonelere 5G hizmeti sunmaya başlarsa EVET.",
                             "YES if at least one operator starts offering 5G to retail subscribers during 2026."),
                   source: t("BTK / operatör resmî duyurusu", "ICTA / operator official announcement"),
                   cat: .teknoloji, price: 0.69, b: 700,
                   volume: 174_882, participants: 18_006, openedDaysAgo: 90, closesInDays: 118),

        MarketSeed(id: "tek-togg",
                   q: t("TOGG 2026'da aylık 5.000 adet satış bandını aşar mı?",
                        "Will TOGG exceed 5,000 monthly units in 2026?"),
                   detail: t("ODMD verilerine göre TOGG'un herhangi bir ayki yurt içi perakende satışı 5.000 adedi aşarsa EVET.",
                             "YES if TOGG's domestic retail sales exceed 5,000 units in any month per ODMD data."),
                   source: t("ODMD aylık satış raporu", "ODMD monthly sales report"),
                   cat: .teknoloji, price: 0.28, b: 550,
                   volume: 88_119, participants: 9_774, openedDaysAgo: 48, closesInDays: 118),

        MarketSeed(id: "tek-llm",
                   q: t("Türkçe odaklı yerli bir büyük dil modeli 2026'da açık kaynak yayımlanır mı?",
                        "Will a Turkish-focused open-weight LLM be released in 2026?"),
                   detail: t("Türkiye merkezli bir kurum, ağırlıkları indirilebilir en az 7B parametreli bir modeli 2026'da yayımlarsa EVET.",
                             "YES if a Türkiye-based institution publishes downloadable weights of a model with at least 7B parameters in 2026."),
                   source: t("Hugging Face / kurum duyurusu", "Hugging Face / institutional announcement"),
                   cat: .teknoloji, price: 0.57, b: 500,
                   volume: 41_770, participants: 5_118, openedDaysAgo: 35, closesInDays: 118),

        MarketSeed(id: "tek-veri-merkezi",
                   q: t("Türkiye'de 2026'da 100 MW üzeri yeni bir veri merkezi yatırımı açıklanır mı?",
                        "Will a new 100+ MW data centre investment be announced in Türkiye in 2026?"),
                   detail: t("Kurulu kapasitesi 100 MW üzeri bir veri merkezi yatırımı resmî olarak duyurulursa EVET.",
                             "YES if a data centre investment with over 100 MW capacity is officially announced."),
                   source: t("Şirket duyurusu / Sanayi Bakanlığı teşvik belgesi",
                             "Company announcement / Ministry of Industry incentive certificate"),
                   cat: .teknoloji, price: 0.46, b: 450,
                   volume: 22_330, participants: 2_664, openedDaysAgo: 18, closesInDays: 118),
    ]

    // MARK: Şirketler

    static let sirketler: [MarketSeed] = [
        MarketSeed(id: "sir-thy-110",
                   q: t("THY 2026'da 110 milyon yolcu taşır mı?",
                        "Will Turkish Airlines carry 110 million passengers in 2026?"),
                   detail: t("Türk Hava Yolları'nın 2026 toplam yolcu sayısı 110.000.000'u aşarsa EVET.",
                             "YES if Turkish Airlines' total 2026 passenger count exceeds 110,000,000."),
                   source: t("THY aylık trafik sonuçları (KAP)",
                             "Turkish Airlines monthly traffic results (public disclosure)"),
                   cat: .sirketler, price: 0.46, b: 600,
                   volume: 58_441, participants: 6_003, openedDaysAgo: 42, closesInDays: 130,
                   topic: .ekonomiBuyuyecek),

        MarketSeed(id: "sir-unicorn",
                   q: t("Türk kurucuların şirketi 2026'da 1 milyar $ değerlemeyle yatırım alır mı?",
                        "Will a Turkish-founded company raise at a $1B valuation in 2026?"),
                   detail: t("Türkiye merkezli veya Türk kurucular tarafından kurulmuş bir şirket 2026'da ≥1 milyar $ değerlemeyle tur kapatırsa EVET.",
                             "YES if a Türkiye-based or Turkish-founded company closes a round at a valuation of $1B or more in 2026."),
                   source: t("Şirket / yatırımcı resmî açıklaması",
                             "Company / investor official announcement"),
                   cat: .sirketler, price: 0.39, b: 500,
                   volume: 37_118, participants: 4_220, openedDaysAgo: 33, closesInDays: 118),

        MarketSeed(id: "sir-halka-arz",
                   q: t("Borsa İstanbul'da 2026'da 30'dan fazla halka arz gerçekleşir mi?",
                        "Will there be more than 30 IPOs on Borsa Istanbul in 2026?"),
                   detail: t("2026 içinde işlem görmeye başlayan yeni şirket sayısı 30'u aşarsa EVET.",
                             "YES if more than 30 new companies begin trading during 2026."),
                   source: t("Borsa İstanbul halka arz listesi", "Borsa Istanbul IPO listing"),
                   cat: .sirketler, price: 0.62, b: 550,
                   volume: 44_902, participants: 5_331, openedDaysAgo: 50, closesInDays: 118,
                   topic: .borsaYukselecek),

        MarketSeed(id: "sir-savunma-ihracat",
                   q: t("Savunma sanayi ihracatı 2026'da 10 milyar $'ı aşar mı?",
                        "Will defence industry exports exceed $10B in 2026?"),
                   detail: t("SSB'nin açıkladığı yıllık savunma ve havacılık ihracatı 10 milyar doları geçerse EVET.",
                             "YES if annual defence and aerospace exports reported by the SSB exceed $10 billion."),
                   source: t("SSB / TİM yıllık ihracat verisi",
                             "SSB / Turkish Exporters Assembly annual data"),
                   cat: .sirketler, price: 0.55, b: 500,
                   volume: 66_774, participants: 7_902, openedDaysAgo: 58, closesInDays: 118,
                   topic: .ekonomiBuyuyecek),
    ]

    // MARK: Kültür

    static let kultur: [MarketSeed] = [
        MarketSeed(id: "kul-film-5m",
                   q: t("2026'da bir yerli film 5 milyon bilet satar mı?",
                        "Will a Turkish film sell 5 million tickets in 2026?"),
                   detail: t("Box Office Türkiye verisine göre 2026 vizyonundaki bir yerli film 5.000.000 bileti aşarsa EVET.",
                             "YES if a domestic film released in 2026 exceeds 5,000,000 admissions per Box Office Türkiye."),
                   source: t("Box Office Türkiye", "Box Office Türkiye"),
                   cat: .kultur, price: 0.36, b: 450,
                   volume: 29_004, participants: 4_118, openedDaysAgo: 38, closesInDays: 118),

        MarketSeed(id: "kul-dizi-top10",
                   q: t("Bir Türk dizisi 2026'da Netflix küresel ilk 10'a girer mi?",
                        "Will a Turkish series enter Netflix's global top 10 in 2026?"),
                   detail: t("Netflix Top 10 küresel (İngilizce dışı) listesinde Türkiye yapımı bir dizi ilk 10'a girerse EVET.",
                             "YES if a Türkiye-produced series enters the Netflix global non-English top 10."),
                   source: t("Netflix Top 10 haftalık liste", "Netflix Top 10 weekly list"),
                   cat: .kultur, price: 0.71, b: 500,
                   volume: 51_220, participants: 6_774, openedDaysAgo: 44, closesInDays: 118),

        MarketSeed(id: "kul-eurovision",
                   q: t("Türkiye 2027 Eurovision'a katılım açıklar mı?",
                        "Will Türkiye announce participation in Eurovision 2027?"),
                   detail: t("TRT veya EBU 2027 yarışması için Türkiye'nin katılımını resmen duyurursa EVET.",
                             "YES if TRT or the EBU officially announces Türkiye's participation in the 2027 contest."),
                   source: t("EBU katılımcı listesi", "EBU participant list"),
                   cat: .kultur, price: 0.21, b: 400,
                   volume: 73_441, participants: 11_002, openedDaysAgo: 26, closesInDays: 88),
    ]

    // MARK: Hava

    static let hava: [MarketSeed] = [
        MarketSeed(id: "hava-kar",
                   q: t("İstanbul'a bu kış 5 cm'den fazla kar yağar mı?",
                        "Will Istanbul get more than 5 cm of snow this winter?"),
                   detail: t("MGM İstanbul (Sarıyer) istasyonunda ölçülen kar kalınlığı bir günde 5 cm'yi aşarsa EVET.",
                             "YES if snow depth measured at the Istanbul (Sarıyer) station exceeds 5 cm on any day."),
                   source: t("MGM günlük gözlem verisi",
                             "Turkish State Meteorological Service daily observations"),
                   cat: .hava, price: 0.64, b: 400,
                   volume: 118_774, participants: 16_330, openedDaysAgo: 20, closesInDays: 9),

        MarketSeed(id: "hava-40c",
                   q: t("İstanbul'da bu yaz 40°C görülür mü?",
                        "Will Istanbul hit 40°C this summer?"),
                   detail: t("MGM İstanbul istasyonlarından herhangi birinde günlük maksimum sıcaklık 40,0°C'yi aşarsa EVET.",
                             "YES if daily maximum temperature exceeds 40.0°C at any Istanbul station."),
                   source: t("MGM günlük gözlem verisi",
                             "Turkish State Meteorological Service daily observations"),
                   cat: .hava, price: 0.58, b: 400,
                   volume: 62_118, participants: 8_441, openedDaysAgo: 15, closesInDays: 96),

        MarketSeed(id: "hava-baraj",
                   q: t("İstanbul baraj doluluk oranı bu ay %40'ın altına iner mi?",
                        "Will Istanbul reservoir levels fall below 40% this month?"),
                   detail: t("İSKİ'nin yayımladığı toplam baraj doluluk oranı bu ay içinde %40,0'ın altına inerse EVET.",
                             "YES if the total reservoir occupancy published by İSKİ falls below 40.0% this month."),
                   source: t("İSKİ baraj doluluk verisi", "İSKİ reservoir occupancy data"),
                   cat: .hava, price: 0.42, b: 350,
                   volume: 34_902, participants: 5_118, openedDaysAgo: 12, closesInDays: 4),
    ]
}
