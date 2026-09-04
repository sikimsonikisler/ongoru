import Foundation

/// Kaynak veri. Gerçek üründe bunun yerine sunucudan gelen piyasa listesi olur.
struct MarketSeed {
    var id: String
    var q: String
    var detail: String
    var source: String
    var cat: Category
    var price: Double        // başlangıç EVET fiyatı
    var b: Double            // likidite
    var volume: Int
    var participants: Int
    var openedDaysAgo: Int
    var closesInDays: Int
    var theme: String? = nil
    var inverted: Bool = false
}

enum SeedMarkets {

    static let all: [MarketSeed] = ekonomi + siyaset + spor + teknoloji + sirketler + kultur + hava

    // MARK: Ekonomi

    static let ekonomi: [MarketSeed] = [
        MarketSeed(id: "eko-faiz-30", q: "TCMB politika faizi 2026 yıl sonunda %30'un altında mı olacak?",
                   detail: "31 Aralık 2026 itibarıyla TCMB bir hafta vadeli repo ihale faiz oranı %30,00'ın altındaysa EVET.",
                   source: "TCMB PPK kararı duyurusu", cat: .ekonomi, price: 0.63, b: 900,
                   volume: 184_231, participants: 12_482, openedDaysAgo: 96, closesInDays: 118,
                   theme: "Faiz düşecek"),

        MarketSeed(id: "eko-enf-20", q: "Yıllık enflasyon Aralık 2026'da %20'nin altına iner mi?",
                   detail: "TÜİK'in Aralık 2026 dönemi için açıkladığı yıllık TÜFE değişimi %20,00'ın altındaysa EVET.",
                   source: "TÜİK Tüketici Fiyat Endeksi bülteni", cat: .ekonomi, price: 0.31, b: 850,
                   volume: 221_904, participants: 15_318, openedDaysAgo: 110, closesInDays: 120,
                   theme: "Enflasyon düşecek"),

        MarketSeed(id: "eko-usd-60", q: "Dolar/TL 2026 sonunda 60'ın üzerinde mi olacak?",
                   detail: "31 Aralık 2026 TCMB gösterge alış kuru 60,0000 TL'nin üzerindeyse EVET.",
                   source: "TCMB gösterge niteliğindeki kurlar", cat: .ekonomi, price: 0.58, b: 1000,
                   volume: 312_770, participants: 19_045, openedDaysAgo: 120, closesInDays: 118,
                   theme: "Döviz yükselecek", inverted: true),

        MarketSeed(id: "eko-altin-8000", q: "Gram altın 2026'da 8.000 TL'yi geçer mi?",
                   detail: "Kapalıçarşı gram altın satış fiyatı 2026 içinde herhangi bir kapanışta 8.000 TL üzerindeyse EVET.",
                   source: "İstanbul Altın Rafinerisi / Kapalıçarşı kapanış", cat: .ekonomi, price: 0.72, b: 800,
                   volume: 156_402, participants: 11_206, openedDaysAgo: 88, closesInDays: 118,
                   theme: "Altın yükselecek", inverted: true),

        MarketSeed(id: "eko-konut-20", q: "İstanbul'da konut fiyatları 2026'da %20'den fazla artar mı?",
                   detail: "TCMB Konut Fiyat Endeksi İstanbul serisinin Aralık 2026 yıllık artışı %20,0'ın üzerindeyse EVET.",
                   source: "TCMB Konut Fiyat Endeksi", cat: .ekonomi, price: 0.66, b: 700,
                   volume: 98_551, participants: 8_774, openedDaysAgo: 74, closesInDays: 140,
                   theme: "Konut fiyatları artacak", inverted: true),

        MarketSeed(id: "eko-bist-20k", q: "BIST 100 endeksi 2026'da 20.000 puanı görür mü?",
                   detail: "BIST 100 kapanış değeri 2026 içinde en az bir gün 20.000'in üzerindeyse EVET.",
                   source: "Borsa İstanbul günlük bülten", cat: .ekonomi, price: 0.41, b: 750,
                   volume: 143_889, participants: 10_330, openedDaysAgo: 65, closesInDays: 118,
                   theme: "Borsa yükselecek"),

        MarketSeed(id: "eko-issizlik-10", q: "İşsizlik oranı 2026'da %10'un üzerine çıkar mı?",
                   detail: "TÜİK mevsim etkisinden arındırılmış işsizlik oranı 2026'da herhangi bir ayda %10,0'ı aşarsa EVET.",
                   source: "TÜİK İşgücü İstatistikleri", cat: .ekonomi, price: 0.37, b: 600,
                   volume: 61_204, participants: 5_918, openedDaysAgo: 52, closesInDays: 118,
                   theme: "İşsizlik artacak", inverted: true),

        MarketSeed(id: "eko-asgari-reel", q: "2027 asgari ücret zammı yıllık enflasyonun üzerinde olur mu?",
                   detail: "Açıklanan 2027 net asgari ücret artış oranı, Aralık 2026 yıllık TÜFE'nin üzerindeyse EVET.",
                   source: "Asgari Ücret Tespit Komisyonu kararı + TÜİK", cat: .ekonomi, price: 0.44, b: 700,
                   volume: 189_337, participants: 21_774, openedDaysAgo: 40, closesInDays: 112,
                   theme: "Asgari ücret reel artacak"),

        MarketSeed(id: "eko-buyume-4", q: "Türkiye ekonomisi 2026'da %4'ten fazla büyür mü?",
                   detail: "TÜİK'in açıklayacağı 2026 yıllık GSYH büyümesi %4,0'ın üzerindeyse EVET.",
                   source: "TÜİK Dönemsel GSYH", cat: .ekonomi, price: 0.35, b: 650,
                   volume: 54_118, participants: 4_902, openedDaysAgo: 60, closesInDays: 150,
                   theme: "Ekonomi büyüyecek"),

        MarketSeed(id: "eko-kk-faiz", q: "Kredi kartı azami akdi faiz oranı 2026'da düşürülür mü?",
                   detail: "TCMB'nin belirlediği kredi kartı azami akdi faiz oranı 2026 içinde bir kez bile indirilirse EVET.",
                   source: "TCMB tebliğ / Resmî Gazete", cat: .ekonomi, price: 0.52, b: 500,
                   volume: 33_640, participants: 3_411, openedDaysAgo: 28, closesInDays: 118,
                   theme: "Faiz düşecek"),
    ]

    // MARK: Siyaset ve kamu

    static let siyaset: [MarketSeed] = [
        MarketSeed(id: "siy-euro-2027", q: "Türkiye 2027'de Euro'ya geçer mi?",
                   detail: "31 Aralık 2027'ye kadar Euro Türkiye'de resmî para birimi olarak yürürlüğe girerse EVET.",
                   source: "Resmî Gazete", cat: .siyaset, price: 0.04, b: 400,
                   volume: 44_902, participants: 9_118, openedDaysAgo: 130, closesInDays: 300,
                   theme: nil),

        MarketSeed(id: "siy-anayasa", q: "Yeni anayasa teklifi 2026'da TBMM Genel Kurulu'na iner mi?",
                   detail: "Anayasa değişikliği teklifi 2026 içinde Genel Kurul gündemine alınırsa EVET.",
                   source: "TBMM tutanak ve gündem kayıtları", cat: .siyaset, price: 0.38, b: 600,
                   volume: 77_215, participants: 8_003, openedDaysAgo: 70, closesInDays: 118),

        MarketSeed(id: "siy-vize", q: "AB ile vize serbestisi 2027 sonuna kadar yürürlüğe girer mi?",
                   detail: "Türk vatandaşları için Schengen bölgesine vizesiz seyahat 31 Aralık 2027'ye kadar başlarsa EVET.",
                   source: "AB Resmî Gazetesi / Komisyon kararı", cat: .siyaset, price: 0.12, b: 500,
                   volume: 128_440, participants: 16_772, openedDaysAgo: 140, closesInDays: 300,
                   theme: nil),

        MarketSeed(id: "siy-butce", q: "2027 merkezi yönetim bütçe açığı GSYH'nin %4'ünü aşar mı?",
                   detail: "Bütçe kanununda öngörülen açık/GSYH oranı %4,0'ın üzerindeyse EVET.",
                   source: "Hazine ve Maliye Bakanlığı bütçe sunumu", cat: .siyaset, price: 0.49, b: 450,
                   volume: 26_113, participants: 2_884, openedDaysAgo: 22, closesInDays: 96),
    ]

    // MARK: Spor

    static let spor: [MarketSeed] = [
        MarketSeed(id: "spor-gs-lig", q: "Galatasaray 2025-26 Süper Lig şampiyonu olur mu?",
                   detail: "TFF'nin tescil ettiği 2025-26 Süper Lig şampiyonu Galatasaray ise EVET.",
                   source: "TFF resmî tescil", cat: .spor, price: 0.47, b: 900,
                   volume: 402_118, participants: 28_440, openedDaysAgo: 100, closesInDays: 62),

        MarketSeed(id: "spor-fb-lig", q: "Fenerbahçe 2025-26 Süper Lig şampiyonu olur mu?",
                   detail: "TFF'nin tescil ettiği 2025-26 Süper Lig şampiyonu Fenerbahçe ise EVET.",
                   source: "TFF resmî tescil", cat: .spor, price: 0.34, b: 900,
                   volume: 388_904, participants: 27_115, openedDaysAgo: 100, closesInDays: 62),

        MarketSeed(id: "spor-avrupa-ceyrek", q: "Bir Türk takımı 2025-26 Avrupa kupalarında çeyrek finale kalır mı?",
                   detail: "UEFA Şampiyonlar Ligi, Avrupa Ligi veya Konferans Ligi'nde bir Türk kulübü çeyrek finale çıkarsa EVET.",
                   source: "UEFA resmî fikstür", cat: .spor, price: 0.44, b: 700,
                   volume: 155_330, participants: 14_209, openedDaysAgo: 80, closesInDays: 34),

        MarketSeed(id: "spor-fifa-20", q: "A Millî Takım 2026 sonunda FIFA sıralamasında ilk 20'ye girer mi?",
                   detail: "FIFA'nın Aralık 2026 sıralamasında Türkiye 20. sıra veya üstündeyse EVET.",
                   source: "FIFA dünya sıralaması", cat: .spor, price: 0.29, b: 550,
                   volume: 71_664, participants: 9_330, openedDaysAgo: 45, closesInDays: 118),

        MarketSeed(id: "spor-transfer-30m", q: "2026 yaz döneminde bir Süper Lig kulübü 30 milyon € üzeri transfer harcaması yapar mı?",
                   detail: "Tek transfer döneminde bir kulübün toplam bonservis gideri 30 milyon € üzerindeyse EVET.",
                   source: "Transfermarkt + kulüp KAP açıklamaları", cat: .spor, price: 0.51, b: 500,
                   volume: 63_902, participants: 7_118, openedDaysAgo: 30, closesInDays: 210),
    ]

    // MARK: Teknoloji

    static let teknoloji: [MarketSeed] = [
        MarketSeed(id: "tek-iphone-100k", q: "Bir sonraki iPhone Türkiye'de 100.000 TL'nin üzerinde mi olacak?",
                   detail: "Apple Türkiye'nin resmî sitesinde yeni serinin en ucuz Pro modeli 100.000 TL üzerindeyse EVET.",
                   source: "apple.com/tr fiyat listesi", cat: .teknoloji, price: 0.78, b: 800,
                   volume: 267_441, participants: 24_902, openedDaysAgo: 55, closesInDays: 41),

        MarketSeed(id: "tek-starlink", q: "Starlink Türkiye'de 2026'da ticari hizmete başlar mı?",
                   detail: "BTK lisansıyla bireysel kullanıma açık ticari satış 2026 içinde başlarsa EVET.",
                   source: "BTK lisans duyurusu", cat: .teknoloji, price: 0.33, b: 600,
                   volume: 92_004, participants: 11_440, openedDaysAgo: 62, closesInDays: 118),

        MarketSeed(id: "tek-5g", q: "5G Türkiye'de 2026'da ticari olarak kullanıma açılır mı?",
                   detail: "En az bir operatör 2026 içinde bireysel abonelere 5G hizmeti sunmaya başlarsa EVET.",
                   source: "BTK / operatör resmî duyurusu", cat: .teknoloji, price: 0.69, b: 700,
                   volume: 174_882, participants: 18_006, openedDaysAgo: 90, closesInDays: 118),

        MarketSeed(id: "tek-togg", q: "TOGG 2026'da aylık 5.000 adet satış bandını aşar mı?",
                   detail: "ODMD verilerine göre TOGG'un herhangi bir ayki yurt içi perakende satışı 5.000 adedi aşarsa EVET.",
                   source: "ODMD aylık satış raporu", cat: .teknoloji, price: 0.28, b: 550,
                   volume: 88_119, participants: 9_774, openedDaysAgo: 48, closesInDays: 118),

        MarketSeed(id: "tek-llm", q: "Türkçe odaklı yerli bir büyük dil modeli 2026'da açık kaynak yayımlanır mı?",
                   detail: "Türkiye merkezli bir kurum, ağırlıkları indirilebilir en az 7B parametreli bir modeli 2026'da yayımlarsa EVET.",
                   source: "Hugging Face / kurum duyurusu", cat: .teknoloji, price: 0.57, b: 500,
                   volume: 41_770, participants: 5_118, openedDaysAgo: 35, closesInDays: 118),

        MarketSeed(id: "tek-veri-merkezi", q: "Türkiye'de 2026'da 100 MW üzeri yeni bir veri merkezi yatırımı açıklanır mı?",
                   detail: "Kurulu kapasitesi 100 MW üzeri bir veri merkezi yatırımı resmî olarak duyurulursa EVET.",
                   source: "Şirket duyurusu / Sanayi Bakanlığı teşvik belgesi", cat: .teknoloji, price: 0.46, b: 450,
                   volume: 22_330, participants: 2_664, openedDaysAgo: 18, closesInDays: 118),
    ]

    // MARK: Şirketler

    static let sirketler: [MarketSeed] = [
        MarketSeed(id: "sir-thy-110", q: "THY 2026'da 110 milyon yolcu taşır mı?",
                   detail: "Türk Hava Yolları'nın 2026 toplam yolcu sayısı 110.000.000'u aşarsa EVET.",
                   source: "THY aylık trafik sonuçları (KAP)", cat: .sirketler, price: 0.46, b: 600,
                   volume: 58_441, participants: 6_003, openedDaysAgo: 42, closesInDays: 130,
                   theme: "Ekonomi büyüyecek"),

        MarketSeed(id: "sir-unicorn", q: "Türk kurucuların şirketi 2026'da 1 milyar $ değerlemeyle yatırım alır mı?",
                   detail: "Türkiye merkezli veya Türk kurucular tarafından kurulmuş bir şirket 2026'da ≥1 milyar $ değerlemeyle tur kapatırsa EVET.",
                   source: "Şirket / yatırımcı resmî açıklaması", cat: .sirketler, price: 0.39, b: 500,
                   volume: 37_118, participants: 4_220, openedDaysAgo: 33, closesInDays: 118),

        MarketSeed(id: "sir-halka-arz", q: "Borsa İstanbul'da 2026'da 30'dan fazla halka arz gerçekleşir mi?",
                   detail: "2026 içinde işlem görmeye başlayan yeni şirket sayısı 30'u aşarsa EVET.",
                   source: "Borsa İstanbul halka arz listesi", cat: .sirketler, price: 0.62, b: 550,
                   volume: 44_902, participants: 5_331, openedDaysAgo: 50, closesInDays: 118,
                   theme: "Borsa yükselecek"),

        MarketSeed(id: "sir-savunma-ihracat", q: "Savunma sanayi ihracatı 2026'da 10 milyar $'ı aşar mı?",
                   detail: "SSB'nin açıkladığı yıllık savunma ve havacılık ihracatı 10 milyar doları geçerse EVET.",
                   source: "SSB / TİM yıllık ihracat verisi", cat: .sirketler, price: 0.55, b: 500,
                   volume: 66_774, participants: 7_902, openedDaysAgo: 58, closesInDays: 118,
                   theme: "Ekonomi büyüyecek"),
    ]

    // MARK: Kültür

    static let kultur: [MarketSeed] = [
        MarketSeed(id: "kul-film-5m", q: "2026'da bir yerli film 5 milyon bilet satar mı?",
                   detail: "Box Office Türkiye verisine göre 2026 vizyonundaki bir yerli film 5.000.000 bileti aşarsa EVET.",
                   source: "Box Office Türkiye", cat: .kultur, price: 0.36, b: 450,
                   volume: 29_004, participants: 4_118, openedDaysAgo: 38, closesInDays: 118),

        MarketSeed(id: "kul-dizi-top10", q: "Bir Türk dizisi 2026'da Netflix küresel ilk 10'a girer mi?",
                   detail: "Netflix Top 10 küresel (İngilizce dışı) listesinde Türkiye yapımı bir dizi ilk 10'a girerse EVET.",
                   source: "Netflix Top 10 haftalık liste", cat: .kultur, price: 0.71, b: 500,
                   volume: 51_220, participants: 6_774, openedDaysAgo: 44, closesInDays: 118),

        MarketSeed(id: "kul-eurovision", q: "Türkiye 2027 Eurovision'a katılım açıklar mı?",
                   detail: "TRT veya EBU 2027 yarışması için Türkiye'nin katılımını resmen duyurursa EVET.",
                   source: "EBU katılımcı listesi", cat: .kultur, price: 0.21, b: 400,
                   volume: 73_441, participants: 11_002, openedDaysAgo: 26, closesInDays: 88),
    ]

    // MARK: Hava

    static let hava: [MarketSeed] = [
        MarketSeed(id: "hava-kar", q: "İstanbul'a bu kış 5 cm'den fazla kar yağar mı?",
                   detail: "MGM İstanbul (Sarıyer) istasyonunda ölçülen kar kalınlığı bir günde 5 cm'yi aşarsa EVET.",
                   source: "MGM günlük gözlem verisi", cat: .hava, price: 0.64, b: 400,
                   volume: 118_774, participants: 16_330, openedDaysAgo: 20, closesInDays: 9),

        MarketSeed(id: "hava-40c", q: "İstanbul'da bu yaz 40°C görülür mü?",
                   detail: "MGM İstanbul istasyonlarından herhangi birinde günlük maksimum sıcaklık 40,0°C'yi aşarsa EVET.",
                   source: "MGM günlük gözlem verisi", cat: .hava, price: 0.58, b: 400,
                   volume: 62_118, participants: 8_441, openedDaysAgo: 15, closesInDays: 96),

        MarketSeed(id: "hava-baraj", q: "İstanbul baraj doluluk oranı bu ay %40'ın altına iner mi?",
                   detail: "İSKİ'nin yayımladığı toplam baraj doluluk oranı bu ay içinde %40,0'ın altına inerse EVET.",
                   source: "İSKİ baraj doluluk verisi", cat: .hava, price: 0.42, b: 350,
                   volume: 34_902, participants: 5_118, openedDaysAgo: 12, closesInDays: 4),
    ]
}
