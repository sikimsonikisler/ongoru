import Foundation

struct SettlementSeed {
    var q: String
    var cat: Category
    var outcome: Bool          // EVET mi çıktı
    var side: Side             // benim tarafım
    var entryYes: Double       // giriş anında EVET'e biçtiğim olasılık
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
    var text: String
    var sources: [String]
    var upvotes: Int
    var hoursAgo: Int
}

enum SeedPeople {

    // MARK: Lig katılımcıları

    static let traders: [Trader] = [
        Trader(id: "t1",  name: "Ahmet Yıldırım", handle: "ahmety", avatarSeed: 1,
               cash: 148_200, score: 81, resolvedCount: 214, correctCount: 158, streak: 6, title: "Makro"),
        Trader(id: "t2",  name: "Mehmet Doğan", handle: "mdogan", avatarSeed: 2,
               cash: 139_820, score: 77, resolvedCount: 186, correctCount: 131, streak: 2, title: "Spor"),
        Trader(id: "t3",  name: "Zeynep Kaya", handle: "zkaya", avatarSeed: 3,
               cash: 131_440, score: 84, resolvedCount: 142, correctCount: 109, streak: 9, title: "Kalibrasyon canavarı"),
        Trader(id: "t4",  name: "Elif Şahin", handle: "elifs", avatarSeed: 4,
               cash: 118_760, score: 72, resolvedCount: 168, correctCount: 112, streak: 0, title: "Teknoloji"),
        Trader(id: "t5",  name: "Burak Aslan", handle: "baslan", avatarSeed: 5,
               cash: 104_330, score: 69, resolvedCount: 121, correctCount: 78, streak: 3, title: nil),
        Trader(id: "t6",  name: "Selin Arıkan", handle: "selinar", avatarSeed: 6,
               cash: 97_540, score: 74, resolvedCount: 98, correctCount: 68, streak: 4, title: "Enerji"),
        Trader(id: "t7",  name: "Emre Koç", handle: "emrekoc", avatarSeed: 7,
               cash: 91_220, score: 63, resolvedCount: 205, correctCount: 122, streak: 1, title: nil),
        Trader(id: "t8",  name: "Deniz Yalçın", handle: "dyalcin", avatarSeed: 8,
               cash: 84_910, score: 70, resolvedCount: 88, correctCount: 59, streak: 2, title: "Kültür"),
        Trader(id: "t9",  name: "Ayşe Tunç", handle: "aysetunc", avatarSeed: 9,
               cash: 76_400, score: 66, resolvedCount: 133, correctCount: 84, streak: 0, title: nil),
        Trader(id: "t10", name: "Kerem Özkan", handle: "keremoz", avatarSeed: 10,
               cash: 68_150, score: 58, resolvedCount: 76, correctCount: 43, streak: 0, title: nil),
        Trader(id: "t11", name: "Merve Bilgin", handle: "mervebil", avatarSeed: 11,
               cash: 61_770, score: 61, resolvedCount: 59, correctCount: 36, streak: 1, title: nil),
        Trader(id: "t12", name: "Onur Çetin", handle: "onurc", avatarSeed: 12,
               cash: 54_200, score: 55, resolvedCount: 112, correctCount: 62, streak: 0, title: nil),
        Trader(id: "t13", name: "İrem Baş", handle: "irembas", avatarSeed: 13,
               cash: 47_880, score: 64, resolvedCount: 44, correctCount: 29, streak: 3, title: "Yeni"),
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
        // Teknoloji — güçlü
        SettlementSeed(q: "iPhone 16 Pro Türkiye fiyatı 90.000 TL'yi aştı mı?", cat: .teknoloji,
                       outcome: true, side: .yes, entryYes: 0.72, shares: 40, horizon: 24, daysAgo: 210),
        SettlementSeed(q: "Starlink Türkiye'de 2025'te ticari hizmete başladı mı?", cat: .teknoloji,
                       outcome: false, side: .no, entryYes: 0.30, shares: 55, horizon: 120, daysAgo: 96),
        SettlementSeed(q: "5G ihalesi 2025 içinde yapıldı mı?", cat: .teknoloji,
                       outcome: true, side: .yes, entryYes: 0.61, shares: 35, horizon: 90, daysAgo: 140),
        SettlementSeed(q: "TOGG 2025'te yurt dışına 10 binden fazla araç sattı mı?", cat: .teknoloji,
                       outcome: false, side: .yes, entryYes: 0.55, shares: 25, horizon: 150, daysAgo: 80),
        SettlementSeed(q: "Bir Türk yapay zekâ girişimi 2025'te 50 milyon $ yatırım aldı mı?", cat: .teknoloji,
                       outcome: true, side: .yes, entryYes: 0.66, shares: 30, horizon: 100, daysAgo: 62),

        // Ekonomi — zayıf
        SettlementSeed(q: "TCMB politika faizi Eylül 2025'te %40'ın altına indi mi?", cat: .ekonomi,
                       outcome: true, side: .no, entryYes: 0.44, shares: 45, horizon: 60, daysAgo: 175),
        SettlementSeed(q: "Yıllık enflasyon Ağustos 2025'te %35'in altına indi mi?", cat: .ekonomi,
                       outcome: false, side: .yes, entryYes: 0.58, shares: 38, horizon: 45, daysAgo: 190),
        SettlementSeed(q: "Dolar/TL 2025'te 45'i gördü mü?", cat: .ekonomi,
                       outcome: false, side: .yes, entryYes: 0.63, shares: 50, horizon: 200, daysAgo: 70),
        SettlementSeed(q: "Gram altın 2025'te 5.000 TL'yi aştı mı?", cat: .ekonomi,
                       outcome: true, side: .yes, entryYes: 0.70, shares: 42, horizon: 180, daysAgo: 120),
        SettlementSeed(q: "2025'te asgari ücrete ara zam yapıldı mı?", cat: .ekonomi,
                       outcome: false, side: .no, entryYes: 0.38, shares: 60, horizon: 150, daysAgo: 55),

        // Spor
        SettlementSeed(q: "Galatasaray 2024-25 Süper Lig şampiyonu oldu mu?", cat: .spor,
                       outcome: true, side: .yes, entryYes: 0.62, shares: 48, horizon: 240, daysAgo: 130),
        SettlementSeed(q: "Türkiye EURO 2024'te çeyrek finale çıktı mı?", cat: .spor,
                       outcome: true, side: .yes, entryYes: 0.34, shares: 30, horizon: 20, daysAgo: 400),
        SettlementSeed(q: "Fenerbahçe 2024-25 Avrupa Ligi'nde yarı finale çıktı mı?", cat: .spor,
                       outcome: false, side: .yes, entryYes: 0.48, shares: 36, horizon: 60, daysAgo: 150),

        // Şirketler
        SettlementSeed(q: "BIST 100 2025'te 12.000 puanı gördü mü?", cat: .sirketler,
                       outcome: true, side: .yes, entryYes: 0.55, shares: 44, horizon: 120, daysAgo: 90),
        SettlementSeed(q: "THY 2025'te 100 milyon yolcuyu aştı mı?", cat: .sirketler,
                       outcome: false, side: .no, entryYes: 0.42, shares: 33, horizon: 180, daysAgo: 48),

        // Kültür
        SettlementSeed(q: "2025'te bir yerli film 5 milyon bilet sattı mı?", cat: .kultur,
                       outcome: false, side: .yes, entryYes: 0.52, shares: 22, horizon: 150, daysAgo: 65),
        SettlementSeed(q: "Türkiye 2026 Eurovision'a katılım açıkladı mı?", cat: .kultur,
                       outcome: false, side: .no, entryYes: 0.28, shares: 40, horizon: 70, daysAgo: 44),

        // Hava
        SettlementSeed(q: "İstanbul'a Ocak 2025'te kar yağdı mı?", cat: .hava,
                       outcome: true, side: .yes, entryYes: 0.80, shares: 50, horizon: 25, daysAgo: 220),
    ]

    // MARK: Gerekçeler

    static let theses: [ThesisSeed] = [
        ThesisSeed(marketId: "eko-faiz-30", author: "Zeynep Kaya", score: 84, side: .yes, price: 0.59,
                   text: "Dezenflasyon patikası bozulmadığı sürece TCMB'nin yıl sonuna kadar toplamda 1200 baz puanlık indirim alanı var. Son iki PPK metninde \"temkinli\" vurgusunun yumuşaması bunun sinyaliydi. Ancak gıda enflasyonunda yeni bir şok gelirse patika kayar.",
                   sources: ["TCMB PPK Ekim metni", "TCMB Piyasa Katılımcıları Anketi", "TÜİK aylık TÜFE serisi"],
                   upvotes: 218, hoursAgo: 9),

        ThesisSeed(marketId: "eko-faiz-30", author: "Emre Koç", score: 63, side: .no, price: 0.41,
                   text: "Kur tarafındaki baskı devam ederse indirim hızının kesileceğini düşünüyorum. Geçmişte de %30 bandına inildiğinde politika duraklamıştı.",
                   sources: ["TCMB rezerv verisi"], upvotes: 74, hoursAgo: 21),

        ThesisSeed(marketId: "eko-enf-20", author: "Ahmet Yıldırım", score: 81, side: .no, price: 0.70,
                   text: "Hizmet enflasyonu katılığı sürüyor; kira ve eğitim kalemleri tek başına yıllık 6-7 puanlık taban oluşturuyor. %20 için hizmetlerin %25 altına inmesi gerekir, bu 12 ayda gerçekçi değil çünkü ücret güncellemeleri yıl başında yapılıyor.",
                   sources: ["TÜİK hizmet enflasyonu alt kalemleri", "TCMB Enflasyon Raporu IV", "Kira endeksi verisi"],
                   upvotes: 341, hoursAgo: 4),

        ThesisSeed(marketId: "eko-konut-20", author: "Selin Arıkan", score: 74, side: .yes, price: 0.63,
                   text: "İstanbul'da konut arzı yeni deprem yönetmeliği sonrası ciddi daraldı. Ruhsat sayıları geçen yıla göre %30 düşükken talep yerinde; dolayısıyla nominal artışın enflasyonun üzerine çıkması olası.",
                   sources: ["TÜİK yapı ruhsatı istatistikleri", "TCMB Konut Fiyat Endeksi", "Endeksa İstanbul m² verisi"],
                   upvotes: 156, hoursAgo: 14),

        ThesisSeed(marketId: "eko-usd-60", author: "Burak Aslan", score: 69, side: .yes, price: 0.55,
                   text: "Reel kur endeksi hâlâ tarihi ortalamanın üzerinde. Cari açık kapanmadan bu seviyenin korunması zor.",
                   sources: ["TCMB reel efektif döviz kuru", "Ödemeler dengesi bülteni"], upvotes: 98, hoursAgo: 30),

        ThesisSeed(marketId: "tek-iphone-100k", author: "Elif Şahin", score: 72, side: .yes, price: 0.74,
                   text: "Geçen üç lansmanda Türkiye fiyatı ortalama %38 zamlandı. Bu yılki ÖTV matrah dilimleri ve kur seviyesiyle en ucuz Pro modelin 100.000 TL altında kalması ancak Apple'ın Türkiye'ye özel indirim yapmasıyla mümkün — ki bunun örneği yok.",
                   sources: ["Apple TR geçmiş fiyat listesi", "ÖTV matrah dilimi tebliği", "TCMB kur projeksiyonu"],
                   upvotes: 402, hoursAgo: 6),

        ThesisSeed(marketId: "tek-iphone-100k", author: "İrem Baş", score: 64, side: .no, price: 0.26,
                   text: "Apple bu yıl baz modelin fiyatını sabit tutma eğiliminde. Pro tarafında da agresif zam gelmeyebilir.",
                   sources: [], upvotes: 31, hoursAgo: 40),

        ThesisSeed(marketId: "tek-5g", author: "Ahmet Yıldırım", score: 81, side: .yes, price: 0.66,
                   text: "İhale takvimi açıklandı ve operatörlerin altyapı yatırımı şimdiden başladı. Frekans tahsisi tamamlandıktan sonra ticari açılışın 6 ay içinde yapılması sektör normu.",
                   sources: ["BTK ihale şartnamesi", "Operatör yatırım planı sunumu"], upvotes: 187, hoursAgo: 11),

        ThesisSeed(marketId: "tek-togg", author: "Kerem Özkan", score: 58, side: .no, price: 0.72,
                   text: "Aylık 5.000 bandı mevcut üretim kapasitesinin neredeyse tamamı demek. Gemlik'te ikinci hat devreye girmeden bu rakam zor.",
                   sources: ["ODMD aylık satış raporu", "TOGG kapasite açıklaması"], upvotes: 112, hoursAgo: 26),

        ThesisSeed(marketId: "spor-gs-lig", author: "Mehmet Doğan", score: 77, side: .yes, price: 0.45,
                   text: "Puan farkı 4'e indi ama fikstür avantajı bizde: kalan 6 maçın 4'ü iç saha ve ilk 5 takımdan sadece biriyle oynanacak. Buna karşın sakatlık listesi uzarsa tablo değişir.",
                   sources: ["TFF fikstürü", "Kulüp sakatlık raporu", "Son 10 maç puan ortalaması"],
                   upvotes: 289, hoursAgo: 3),

        ThesisSeed(marketId: "spor-fb-lig", author: "Deniz Yalçın", score: 70, side: .no, price: 0.66,
                   text: "Deplasmanda alınan puan ortalaması şampiyonluk için gereken bandın altında. Zirve yarışında bu fark 6 maçta kapanmaz.",
                   sources: ["TFF puan durumu", "Deplasman puan ortalaması"], upvotes: 143, hoursAgo: 8),

        ThesisSeed(marketId: "siy-euro-2027", author: "Ayşe Tunç", score: 66, side: .no, price: 0.96,
                   text: "Euro'ya geçiş için önce AB üyeliği, sonra en az iki yıl ERM II üyeliği gerekiyor. Takvim matematiksel olarak 2027'ye sığmıyor.",
                   sources: ["AB Maastricht kriterleri", "ERM II süreç belgesi"], upvotes: 521, hoursAgo: 18),

        ThesisSeed(marketId: "kul-dizi-top10", author: "Deniz Yalçın", score: 70, side: .yes, price: 0.68,
                   text: "Son üç yıldır Türk yapımları İngilizce dışı listesinde ortalama 9 hafta ilk 10'da kaldı. 2026'da platformun Türkiye yapım bütçesi de artıyor.",
                   sources: ["Netflix Top 10 arşivi", "Platform yatırım duyurusu", "Yapımcı birliği raporu"],
                   upvotes: 96, hoursAgo: 16),

        ThesisSeed(marketId: "hava-kar", author: "Selin Arıkan", score: 74, side: .yes, price: 0.61,
                   text: "ECMWF ensemble çıktısı önümüzdeki 10 gün için soğuk hava dalgasını %70 olasılıkla veriyor. Son 30 yılın 22'sinde İstanbul bu eşiği aştı.",
                   sources: ["ECMWF ensemble", "MGM 30 yıllık iklim normalleri"], upvotes: 204, hoursAgo: 2),

        ThesisSeed(marketId: "eko-bist-20k", author: "Zeynep Kaya", score: 84, side: .no, price: 0.59,
                   text: "20.000 için endeksin dolar bazında 2021 zirvesini geçmesi gerekiyor. Reel getiri beklentisi mevduatın altındayken bu giriş zor; ancak faiz indirimleri hızlanırsa senaryo değişir.",
                   sources: ["BIST 100 dolar bazlı seri", "Mevduat faizi ortalaması", "Yabancı takas oranı"],
                   upvotes: 178, hoursAgo: 12),

        ThesisSeed(marketId: "sir-halka-arz", author: "Onur Çetin", score: 55, side: .yes, price: 0.58,
                   text: "SPK onay bekleyen dosya sayısı şu an 41. Geçmiş yıllarda bu havuzun yaklaşık %70'i aynı yıl içinde işlem görmeye başladı.",
                   sources: ["SPK haftalık bülten", "Borsa İstanbul halka arz arşivi"], upvotes: 67, hoursAgo: 22),

        ThesisSeed(marketId: "tek-starlink", author: "Elif Şahin", score: 72, side: .no, price: 0.65,
                   text: "Yer istasyonu ve veri yerelleştirme şartı çözülmeden lisans çıkmıyor. Görüşmeler iki yıldır aynı noktada.",
                   sources: ["BTK mevzuat çerçevesi", "Şirket başvuru duyurusu"], upvotes: 121, hoursAgo: 33),

        ThesisSeed(marketId: "eko-asgari-reel", author: "Ahmet Yıldırım", score: 81, side: .no, price: 0.55,
                   text: "Son beş yılın dördünde zam, gerçekleşen enflasyonun altında kaldı. Bütçe disiplini hedefi varken reel artış politika tercihi olarak zayıf ihtimal.",
                   sources: ["Asgari ücret tarihsel serisi", "TÜİK yıllık TÜFE", "OVP hedefleri"],
                   upvotes: 267, hoursAgo: 7),
    ]
}
