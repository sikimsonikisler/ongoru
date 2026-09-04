# Öngörü — Türkiye'nin Kolektif Tahmin Motoru

Para değil **itibar** üzerine kurulu bir tahmin piyasası. Kullanıcılar Türkiye'ye
dair geleceğe yönelik sorulara olasılık biçer, gerekçesini yazar ve haklı
çıktıkça bir **sicil** oluşturur. Amaç bir Kalshi klonu değil; kalabalığın
beklentilerini ölçen ve bunu toplulaştıran bir motor.

> **Gerçek para yoktur.** Para yatırma, çekme veya nakde çevirme yoktur; puanlar
> yalnızca sıralama ve sicil içindir. Uygulamadaki toplulaştırılmış beklentiler
> yatırım tavsiyesi değildir. Bu yapının Türkiye'de yayına alınmadan önce oyun/
> yarışma hukuku açısından ürün-spesifik hukuki görüş alınması gerekir —
> özellikle ödül, ücretli giriş, nakde çevrilebilirlik ve sponsorluk eklenirse
> değerlendirme değişir.

---

## Ne yapıyor

| Sekme | İçerik |
|---|---|
| **Piyasalar** | 35 Türkiye piyasası; canlı EVET/HAYIR fiyatları, sparkline, kategori filtresi, arama, sonuçlanan piyasa arşivi |
| **Endeks** | Türkiye Kolektif Beklenti Endeksi: bileşik iyimserlik göstergesi, en çok yükselen/gerileyen beklentiler, kategori nabzı |
| **Portföy** | Açık pozisyonlar (canlı K/Z), sonuçlananlar (Brier skoruyla), işlem geçmişi |
| **Lig** | Puan ligi ve İsabet ligi; podyum, sıralama, kendi sıran |
| **Sicil** | Öngörü Skoru, kategori kırılımı, vade kırılımı, kalibrasyon grafiği, asistan analizi, gerekçelerin |

### Fikrin üç ayağı

1. **Fiyat = olasılık.** 63¢, kalabalığın o sonuca %63 ihtimal verdiği anlamına
   gelir. EVET + HAYIR her zaman 100¢ eder; doğru bilen her sözleşme 100 puana
   döner.
2. **Asıl ölçü isabet, puan değil.** Öngörü Skoru, Brier skoru üzerinden
   kalibrasyonu ölçer — "%70 dediklerinin gerçekten %70'i oldu mu?"
3. **Gerekçe zorunlu değil ama ödüllendirilir.** Her tahminin yanına mekanizma
   ve kaynak yazılabilir; asistan eksikleri gösterir, diğer kullanıcılar oylar.

---

## Nasıl çalışıyor

### Piyasa yapıcı — LMSR

Fiyatlar Hanson'ın Logaritmik Piyasa Skorlama Kuralı ile belirlenir
([`Engine/LMSR.swift`](Ongoru/Engine/LMSR.swift)):

```
C(q) = b · ln(e^(qY/b) + e^(qN/b))          maliyet fonksiyonu
p_yes = e^(qY/b) / (e^(qY/b) + e^(qN/b))    anlık fiyat
```

Bir işlemin maliyeti `C(q_sonra) − C(q_önce)`. Bu sayede her alım fiyatı
gerçekten hareket ettirir, fiyat 0–1 arasında kalır ve EVET + HAYIR = 1 olur.
`b` likidite parametresi: büyük olduğunda fiyat daha az oynar. Bütçeden sözleşme
adedi ikili aramayla bulunur.

### Kalabalık simülasyonu

[`Engine/MarketSimulator.swift`](Ongoru/Engine/MarketSimulator.swift) her 2,5
saniyede piyasaların ~%45'ini, gizli bir `latentProbability` etrafında ortalamaya
dönen (Ornstein–Uhlenbeck benzeri) bir süreçle hareket ettirir. Gerçek üründe
bunun yerini diğer kullanıcıların emirleri alır.

### Öngörü Skoru

[`Engine/ScoreEngine.swift`](Ongoru/Engine/ScoreEngine.swift):

```
Brier = ortalama (verdiğin olasılık − sonuç)²
Skor  = 50 + 50 · (1 − Brier / 0,25)
```

Yazı-tura (her şeye %50 demek) 0,250 Brier verir, yani 50 puan. 100 kusursuz,
0 sistematik yanlış demektir. Az sayıda tahminde skor 50'ye doğru çekilir
(küçük sayı yanılgısına karşı). Ayrıca kategori kırılımı, vade kırılımı
(≤30 gün / >30 gün), kalibrasyon dilimleri, iyimserlik yanlılığı ve
"kalabalığa karşı gitme" sicili hesaplanır.

### Öngörü Asistanı

[`Engine/Assistant.swift`](Ongoru/Engine/Assistant.swift) tamamen **cihaz
üstünde, kural tabanlı** çalışır — hiçbir veri dışarı gönderilmez. Üç iş yapar:

- **Gerekçe yazarken yönlendirir:** mekanizma eksikse sorar, sayısal eşik ister,
  kategoriye göre kaynak önerir ("TÜİK enflasyon bülteni", "TFF fikstürü",
  "KAP bildirimi"…), piyasayla ayrıştığında karşı argüman ister.
- **Gerekçe kalitesi (0–100)** üretir: uzunluk, sayısal eşik, nedensellik bağlacı,
  karşı senaryo kabulü ve kaynak sayısı.
- **Sicil analizi** yazar: "X özellikle teknoloji tahminlerinde başarılı",
  "fazla iyimsersin", "kısa vadede daha isabetlisin".

Tümü `InsightProviding` protokolünün arkasında. Gerçek bir dil modeline
(ör. Claude API) geçmek için tek yapılacak bu protokolü uygulayan yeni bir tip
yazıp `AppStore.assistant`'ı değiştirmek.

### Beklenti Endeksi

[`Engine/ExpectationIndex.swift`](Ongoru/Engine/ExpectationIndex.swift)
piyasaları başlıklara ("Faiz düşecek", "Konut fiyatları artacak", "Döviz
yükselecek"…) gruplar ve 7 günlük değişimlerini çıkarır. Bileşik endeks için her
piyasanın olasılığı iyimserlik yönüne çevrilir: "enflasyon düşecek" yükselirse
iyimserlik, "döviz yükselecek" yükselirse karamsarlık sayılır (`indexInverted`).
50 nötr çizgidir.

---

## Mimari

```
Ongoru/
├─ Models/Domain.swift          Market, Trade, Position, Settlement, Thesis, Trader
├─ Engine/
│  ├─ LMSR.swift                otomatik piyasa yapıcı
│  ├─ MarketSimulator.swift     kalabalık akışı + sentetik geçmiş
│  ├─ ScoreEngine.swift         Brier tabanlı Öngörü Skoru
│  ├─ Assistant.swift           cihaz üstü asistan + gerekçe analizi
│  └─ ExpectationIndex.swift    toplulaştırma
├─ Store/
│  ├─ AppState.swift            Codable durum + kurulum
│  ├─ AppStore.swift            tek kaynak: işlem, sonuçlanma, lig, kalıcılık
│  ├─ Persistence.swift         Application Support altında JSON
│  ├─ SeedMarkets.swift         35 piyasa
│  └─ SeedPeople.swift          15 katılımcı, 18 örnek sicil kaydı, 18 gerekçe
├─ Views/                       SwiftUI ekranları + bileşenler
└─ Theme/Theme.swift            palet, tipografi, Türkçe sayı biçimleri
```

Durum tek bir `AppStore` (`ObservableObject`) üzerinde. Pozisyonlar işlem
kayıtlarından türetilir; sonuçlanma anında `Settlement` dondurulur, böylece
sicil geriye dönük olarak yeniden hesaplanmaz. Kalıcılık: Application Support
altında tek bir JSON dosyası, 1,5 saniyelik gecikmeli yazma.

---

## Çalıştırma

Gereksinim: Xcode 26+, iOS 18+ simülatörü.

```bash
./build.sh
xcrun simctl install booted /tmp/ongoru-dd/Build/Products/Debug-iphonesimulator/Ongoru.app
xcrun simctl launch booted com.ongoru.tahmin
```

`build.sh` türev veriyi `/tmp` altına yazar (`ONGORU_DD` ile değiştirilebilir).
Bu bilinçli: proje iCloud'a senkronlanan bir klasörde durduğunda derleme çıktısı
`com.apple.fileprovider` uzantılı özniteliği alıyor ve `codesign` reddediyor.

Xcode'dan açmak için `Ongoru.xcodeproj`. Proje, Xcode 16+ senkronize klasör
grubunu kullanır: `Ongoru/` altına eklenen her dosya otomatik derlemeye girer.

### Denemeye değer akış

1. Onboarding'de **"Sezon ortasından başla"** → 18 sonuçlanmış tahmin ve 6 açık
   pozisyonla dolu bir hesap.
2. Bir piyasaya gir → **EVET/HAYIR** → tutarı seç → **"Gerekçeni de yaz"** aç.
   Yazdıkça asistanın istemleri ve kalite ölçeri değişir.
3. **Sicil → ⚙︎ → "Bir piyasayı şimdi sonuçlandır"** → ödemenin yapıldığını,
   skorun ve kategori kırılımının güncellendiğini gör.
4. **Piyasalar → filtre → "Sonuçlananları göster"** → arşiv.

---

## Bilinçli olarak yapılmayanlar

- **Sunucu yok.** Tüm veri cihazda; "kalabalık" simüle ediliyor. Gerçek üründe
  piyasa listesi, emirler ve çözümleme sunucuda olmalı.
- **Kimlik doğrulama yok.** Lig katılımcıları seed veridir.
- **Çözümleme otomatik değil.** Piyasa kapanınca gizli olasılığa göre rastgele
  sonuçlanır; gerçekte bunun bir çözüm mekanizması (resmî kaynak + itiraz süreci)
  olması gerekir. Her piyasanın çözüm kriteri ve kaynağı zaten veride tanımlı.
- **Piyasa içeriği örnektir.** Sorular ve seed fiyatlar gösterim amaçlıdır;
  gerçek veriye dayanmaz.
