import Foundation

// Öngörü içerik denetimi testleri.
// Çalıştırmak için: ./run-tests.sh
//
// Uygulamanın kendi kaynaklarıyla derlenir; ayrı bir kopya tutulmaz.

struct Case {
    var text: String
    var kind: ContentKind
    var expected: ModerationSeverity
    var label: String
}

let cases: [Case] = [
    // Temiz içerik geçmeli
    .init(text: "Yıllık enflasyon Aralık 2026'da %20'nin altına iner mi?",
          kind: .marketQuestion, expected: .allowed, label: "normal soru"),
    .init(text: "Hizmet enflasyonu katı olduğu için %20 zor; kira tek başına 6 puan taban yapıyor.",
          kind: .thesis, expected: .allowed, label: "normal gerekçe"),
    .init(text: "Galatasaray 2025-26 şampiyon olur mu?",
          kind: .marketQuestion, expected: .allowed, label: "kurum adı suç isnadı değil"),
    .init(text: "Amaçlı bir toplantı yapıldı, toplam katılım yüksekti.",
          kind: .thesis, expected: .allowed, label: "güvenli kelimeler"),

    // Küfür ve kaçırma yöntemleri
    .init(text: "bu ne amk saçmalık", kind: .thesis, expected: .blocked, label: "kısaltma küfür"),
    .init(text: "siktir git buradan", kind: .thesis, expected: .blocked, label: "küfür"),
    .init(text: "s.i.k.t.i.r", kind: .thesis, expected: .blocked, label: "noktayla kaçırma"),
    .init(text: "siiiiktir", kind: .thesis, expected: .blocked, label: "harf tekrarıyla kaçırma"),
    .init(text: "s1kt1r", kind: .thesis, expected: .blocked, label: "rakamla kaçırma"),
    .init(text: "orospu çocuğu", kind: .thesis, expected: .blocked, label: "hakaret"),
    .init(text: "you are a fucking idiot", kind: .thesis, expected: .blocked, label: "İngilizce küfür"),
    .init(text: "tam bir şerefsizsin", kind: .thesis, expected: .blocked, label: "aşağılama"),

    // Tehdit ve nefret söylemi
    .init(text: "adresini biliyorum evini basacagim", kind: .thesis, expected: .blocked, label: "tehdit"),
    .init(text: "hepsi gebersin", kind: .thesis, expected: .blocked, label: "nefret söylemi"),

    // Kişisel veri
    .init(text: "bana ulaş 0532 111 22 33", kind: .thesis, expected: .blocked, label: "telefon"),
    .init(text: "mail at ahmet@example.com", kind: .thesis, expected: .blocked, label: "e-posta"),
    .init(text: "TC 12345678901 numarası", kind: .thesis, expected: .blocked, label: "kimlik no"),

    // İtibar suikastı
    .init(text: "Mehmet Yılmaz hırsız mı çıkacak?", kind: .marketQuestion,
          expected: .blocked, label: "kişiye suç isnadı → piyasa açılamaz"),
    .init(text: "Mehmet Yılmaz hırsız mı çıkacak?", kind: .thesis,
          expected: .flagged, label: "aynı metin gerekçede incelemeye düşer"),
    .init(text: "Ayşe Demir rüşvet aldı mı 2026'da?", kind: .marketQuestion,
          expected: .blocked, label: "rüşvet isnadı"),
    .init(text: "Ali Vural kanser mi olacak?", kind: .marketQuestion,
          expected: .flagged, label: "kişinin sağlığı hassas"),
]

/// Yasaklı kök içeren ya da çift harfli, engellenmemesi gereken kelimeler.
let innocent = [
    "dikkat", "millet", "hakkında", "muhakkak", "kuvvetli", "şiddet",
    "affetmek", "bakkal", "sıkkın", "teşekkür", "zannetmek", "dükkan",
    "amaç", "amacı", "ampul", "amir", "ama", "aman", "amortisman",
    "toplantı", "toplam", "topluluk", "toplumsal", "toparlamak", "toprak",
    "götürmek", "götürü", "gotik", "asistan", "asit", "masa",
    "sikke", "sikkeler", "siklet", "salatalık", "malzeme", "maliyet",
    "kasık", "aşık", "aşıklar", "boksör",
    "İstanbul'da konut fiyatları %20 artar mı?",
    "Galatasaray şampiyon olur mu?",
    "TCMB faizi düşürür mü?",
    "Bu tahmin çok iyi, teşekkürler dostum.",
    "Kalabalık haklı çıktı, dikkatli bir analizdi.",
    "Toplam işlem hacmi arttı, katılım güçlü.",
]

@main
struct ModerationTestRunner {
    static func main() {
        var pass = 0, fail = 0

        print("— Denetim kuralları —")
        for c in cases {
            let r = ContentModerator.check(c.text, kind: c.kind)
            let ok = r.severity == c.expected
            ok ? (pass += 1) : (fail += 1)
            let detail = ok ? "" : "  (beklenen \(c.expected.rawValue), gelen \(r.severity.rawValue))"
            print("\(ok ? "✓" : "✗") \(c.label)\(detail)")
        }

        print("\n— Yanlış pozitif taraması —")
        var falsePositives: [String] = []
        for word in innocent where ContentModerator.check(word, kind: .thesis).severity != .allowed {
            falsePositives.append(word)
        }
        if falsePositives.isEmpty {
            pass += 1
            print("✓ \(innocent.count) masum girdinin hiçbiri engellenmedi")
        } else {
            fail += 1
            print("✗ yanlış pozitif: \(falsePositives.joined(separator: ", "))")
        }

        print("\n\(pass) geçti, \(fail) kaldı")
        exit(fail == 0 ? 0 : 1)
    }
}
