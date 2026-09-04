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
| **Sicil** | Öngörü Skoru, kategori kırılımı, vade kırılımı, kalibrasyon grafiği, asistan analizi, gerekçelerin, önerdiğin piyasalar |

Ayrıca: **Türkçe/İngilizce** uygulama içi dil değiştirme, **hesap** (Apple, Google,
Öngörü hesabı), **kullanıcı piyasa önerileri**, **içerik denetimi**, **bildirme**
akışı ve **reklamsız destek** ekranı.

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

## Dil

Uygulama Türkçe ve İngilizce çalışır; dil **uygulama içinden** değiştirilir
(Ayarlar › Dil, ya da her ekranın sol üstündeki küre). `Sistem dili` seçiliyse
cihazın diline uyar.

Çeviri satır içi `L("Türkçe", "English")` çağrılarıyla yapılır
([`Core/Localization.swift`](Ongoru/Core/Localization.swift)). `.xcstrings`
yerine bunun seçilme sebebi, String Catalog'un yalnızca sistem diline uyması —
uygulama içi dil seçici mümkün olmuyor. Veride saklanan metinler (35 piyasa
sorusu, çözüm kriterleri, 18 gerekçe) `LText` ile iki dilli tutulur; kullanıcı
üretimi içerik tek dillidir.

Sayı ve tarih biçimleri de dile bağlıdır: Türkçede `129.059` ve `%63`,
İngilizcede `129,059` ve `63%`.

---

## İçerik denetimi

Kullanıcılar piyasa önerebildiği ve gerekçe yazabildiği için denetim
zorunlu. [`Core/Moderation.swift`](Ongoru/Core/Moderation.swift) tamamen cihaz
üstünde, iki katman hâlinde çalışır:

**Sert engel — gönderi hiç oluşmaz:**
- Küfür, hakaret, aşağılama (Türkçe ve İngilizce kökler)
- Nefret söylemi ve şiddet tehdidi
- Kişisel veri: telefon, e-posta, TC kimlik no, IBAN
- **Adı geçen bir kişiye suç isnadı** — "X hırsız mı", "Y rüşvet aldı mı" gibi
  sorularla piyasa açılamaz

**İşaretleme — yayımlanır ama incelemeye düşer:**
- Aynı suç isnadı bir *gerekçe* içinde geçerse (piyasada engel, gerekçede uyarı)
- Belirli bir kişinin sağlığı, ölümü veya özel hayatı

Kaçırma yöntemlerine karşı metin normalleştirilir: küçük harf, rakam/simge
ikamesi (`s1kt1r`), Türkçe aksan düzleme, harf tekrarı çökertme (`siiiiktir`) ve
ayraç temizleme (`s.i.k.t.i.r`). Çökertme masum kelimeleri de bozduğu için
yasaklı kökler ve güvenli kelime listesi (`sikke`, `amaç`, `toplantı`,
`götürmek`…) aynı normalleştirmeden geçirilip öyle karşılaştırılır. Üç harf ve
altındaki kökler yalnızca tam kelime eşleşir.

Kullanıcı arayüzünde bu, **yazarken** görünür: kural ihlali kırmızı bir bantla
açıklanır, ne yakalandığı söylenir ve yayımlama düğmesi kilitlenir. Ayrıca her
gerekçe ve piyasa için **bildirme** akışı vardır; bildirilen içerik anında
kullanıcıdan gizlenir.

### Testler

```bash
./run-tests.sh
```

22 senaryo: kural ihlalleri, kaçırma yöntemleri ve 47 masum Türkçe girdi
üzerinde yanlış pozitif taraması. Uygulamanın kendi kaynaklarını derler.

---

## Hesap

Üç yol: **Apple ile Giriş**, **Google ile devam et**, **Öngörü hesabı**.

- **Apple** — `AuthenticationServices` ile gerçek `SignInWithAppleButton`.
  Çalışması için Xcode'da hedefe "Sign in with Apple" yetkilendirmesi eklenip
  bir geliştirici ekibi seçilmeli; eksikse hata kullanıcıya net cümleyle
  söylenir, sessizce yutulmaz.
- **Google** — SDK'sız, OAuth 2.0 Authorization Code + PKCE akışı
  (`ASWebAuthenticationSession`). Kod tamdır; tek eksik Google Cloud
  Console'da bir iOS OAuth istemcisi oluşturup kimliği
  [`GoogleConfig.clientID`](Ongoru/Store/Auth.swift)'ye yazmak.
- **Öngörü hesabı** — parola **istenmez**. Sunucu olmadan parolayı cihazda
  saklamak güvenlik hissi verir ama korumaz; hesap kimliği cihazda üretilir.

İlerleme şu an cihazda saklanıyor. Cihazlar arası taşıma sunucu gerektirir;
kimlik katmanı (`Account`, `AuthService`) bunun bağlanacağı yer olarak hazır.

---

## Gelir modeli

Reklam yerine **destek + Pro** tercih edildi. Gerekçesi uygulama içinde de
açıkça yazılı (Sicil › Ayarlar › Destek):

- **Politika riski** — tahmin piyasası arayüzü, para olmasa bile reklam
  ağlarının kumar politikalarına takılabilir.
- **Düşük getiri** — bu ölçekte reklam geliri kullanıcı başına kuruşlarla
  ölçülür; ürünü bozma maliyeti gelirden büyüktür.
- **Veri baskısı** — reklam, izleme ve profil çıkarma baskısı getirir; asistanı
  cihaz üstünde tutma kararıyla çelişir.

Ekranda StoreKit 2 akışı hazır (ürün yükleme, satın alma, doğrulama). App Store
Connect'te ürün tanımlanmadığı için mağaza boş dönüyor ve ekran bunu gizlemek
yerine söylüyor. Ürün kimlikleri `SupportStore.ids` içinde.

Bağış toplama Türkiye'de mevzuata tabidir (2860 sayılı Yardım Toplama Kanunu) ve
Apple, gerçek "bağış"ı yalnızca kayıtlı yardım kuruluşları için uygulama dışı
ödemeye izin verir; ticari bir yayıncı için destek satın alması uygulama içi
satın alma olmak zorundadır. Yayına almadan önce ikisini de avukatla netleştir.

---

## Mimari

```
Ongoru/
├─ Core/
│  ├─ Localization.swift        L("tr","en"), LText, dil çözümleme
│  ├─ Moderation.swift          içerik denetimi + normalleştirme
│  └─ Haptics.swift             dokunsal geri bildirim
├─ Models/Domain.swift          Market, Trade, Position, Settlement, Thesis,
│                               Trader, MarketProposal, Report, IndexTopic
├─ Engine/
│  ├─ LMSR.swift                otomatik piyasa yapıcı
│  ├─ MarketSimulator.swift     kalabalık akışı + sentetik geçmiş
│  ├─ ScoreEngine.swift         Brier tabanlı Öngörü Skoru
│  ├─ Assistant.swift           cihaz üstü asistan + gerekçe analizi
│  └─ ExpectationIndex.swift    toplulaştırma
├─ Store/
│  ├─ AppState.swift            Codable durum + kurulum
│  ├─ AppStore.swift            tek kaynak: işlem, sonuçlanma, lig, kalıcılık
│  ├─ Auth.swift                Apple / Google (PKCE) / yerel hesap
│  ├─ Persistence.swift         Application Support altında JSON
│  ├─ SeedMarkets.swift         35 piyasa
│  └─ SeedPeople.swift          15 katılımcı, 18 örnek sicil kaydı, 18 gerekçe
├─ Views/                       SwiftUI ekranları + bileşenler
└─ Theme/Theme.swift            palet, tipografi, dile bağlı sayı biçimleri

Tests/ModerationTests.swift     ./run-tests.sh ile çalışır
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
4. **Piyasalar → "Sonuçlanan"** sekmesi → arşiv.
5. **Piyasalar › +** → piyasa öner. Soruya bir telefon numarası ya da bir kişiye
   suç isnadı yaz: kural bandı çıkar ve yayımlama kilitlenir.
6. Sol üstteki küreden **English**'e geç — arayüz, piyasa soruları, gerekçeler
   ve sayı biçimleri birlikte değişir.

---

## Sıradaki işler

Kalan her şey [Issues](https://github.com/sikimsonikisler/ongoru/issues)
altında, her biri kendi başına okunacak şekilde yazıldı. Kabaca sıra:

| # | İş | Neden önemli |
|---|---|---|
| [#1](https://github.com/sikimsonikisler/ongoru/issues/1) | Sunucu: durumu API'ye taşı | Kolektif tahmin motoru tek kişilik simülasyonken kolektif değil |
| [#6](https://github.com/sikimsonikisler/ongoru/issues/6) | Piyasa çözümlemesi gerçek olmalı | Sonuç şu an rastgele; sicil buna güvenmekle anlam kazanıyor |
| [#2](https://github.com/sikimsonikisler/ongoru/issues/2) | Moderasyon kuyruğu | İşaretlenen içerik ve bildirimler bir yere düşmüyor |
| [#7](https://github.com/sikimsonikisler/ongoru/issues/7) | Hukuki görüş | Yayına almadan önce |
| [#3](https://github.com/sikimsonikisler/ongoru/issues/3) [#4](https://github.com/sikimsonikisler/ongoru/issues/4) [#5](https://github.com/sikimsonikisler/ongoru/issues/5) | Apple / Google / StoreKit yapılandırması | Kod hazır, hesap ayarı eksik |
| [#8](https://github.com/sikimsonikisler/ongoru/issues/8) | Pro'da vaat edilen özellikler | Para alınan şeyin karşılığı olmalı |

---

## Bilinçli olarak yapılmayanlar

- **Sunucu yok.** Tüm veri cihazda; "kalabalık" simüle ediliyor. Gerçek üründe
  piyasa listesi, emirler ve çözümleme sunucuda olmalı.
- **Kimlik doğrulama sunucusuz.** Apple ve Google akışları gerçek ama
  yapılandırma (yetkilendirme / istemci kimliği) gerektirir; oturum sunucuda
  doğrulanmaz. Lig katılımcıları seed veridir.
- **Moderasyon kuyruğu yok.** İşaretlenen içerik ve bildirimler cihazda tutulur;
  gerçek üründe bir insan incelemesine düşmeli. Kural tabanlı denetim, bağlam
  gerektiren örtük hakareti yakalayamaz — `ContentModerator` bir sınıflandırıcıyla
  değiştirilebilecek şekilde tek noktada duruyor.
- **Çözümleme otomatik değil.** Piyasa kapanınca gizli olasılığa göre rastgele
  sonuçlanır; gerçekte bunun bir çözüm mekanizması (resmî kaynak + itiraz süreci)
  olması gerekir. Her piyasanın çözüm kriteri ve kaynağı zaten veride tanımlı.
- **Piyasa içeriği örnektir.** Sorular ve seed fiyatlar gösterim amaçlıdır;
  gerçek veriye dayanmaz.
