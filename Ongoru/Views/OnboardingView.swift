import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var store: AppStore
    @State private var name: String = ""
    @State private var sample: Bool = true
    @FocusState private var focused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                header
                nameField
                startChoice
                rules
                startButton
                disclaimer
            }
            .padding(22)
            .padding(.top, 30)
        }
        .background(Palette.bg)
        .scrollDismissesKeyboard(.interactively)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 9) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Palette.bg)
                    .frame(width: 34, height: 34)
                    .background(Palette.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                Text("ÖNGÖRÜ")
                    .font(.system(size: 20, weight: .black)).kerning(2.5)
                    .foregroundStyle(Palette.text)
            }
            Text("Türkiye'nin kolektif tahmin motoru")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Palette.text)
            Text("Geleceğe dair sorulara olasılık biç, gerekçeni yaz, haklı çıktıkça itibar kazan. Para yok — puan ve sicil var.")
                .font(.system(size: 14))
                .foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ADIN").font(.system(size: 10, weight: .bold)).kerning(0.8)
                .foregroundStyle(Palette.faint)
            TextField("", text: $name, prompt: Text("Ligde görünecek isim").foregroundStyle(Palette.faint))
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Palette.text)
                .focused($focused)
                .submitLabel(.done)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
                .padding(.horizontal, 14).padding(.vertical, 13)
                .background(Palette.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(focused ? Palette.accent.opacity(0.6) : Palette.stroke, lineWidth: 1))
        }
    }

    private var startChoice: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NASIL BAŞLAYALIM").font(.system(size: 10, weight: .bold)).kerning(0.8)
                .foregroundStyle(Palette.faint)
            choiceRow(
                selected: sample,
                title: "Sezon ortasından başla",
                body: "18 sonuçlanmış tahmin, 6 açık pozisyon ve 128.000 puanlık bir demo hesabı. Öngörü Skoru'nu ilk açılışta görürsün.",
                action: { sample = true })
            choiceRow(
                selected: !sample,
                title: "Sıfırdan başla",
                body: "10.000 puan, boş portföy, boş sicil. Skorun ilk piyasan sonuçlanınca oluşmaya başlar.",
                action: { sample = false })
        }
    }

    private func choiceRow(selected: Bool, title: String, body: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(selected ? Palette.accent : Palette.faint)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.system(size: 14, weight: .semibold)).foregroundStyle(Palette.text)
                    Text(body).font(.system(size: 12)).foregroundStyle(Palette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .padding(13)
            .background(selected ? Palette.accent.opacity(0.07) : Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder(selected ? Palette.accent.opacity(0.45) : Palette.stroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var rules: some View {
        VStack(alignment: .leading, spacing: 12) {
            ruleRow("number.circle", "Fiyat = olasılık",
                    "63¢, kalabalığın o sonuca %63 ihtimal verdiği anlamına gelir. EVET + HAYIR her zaman 100¢.")
            ruleRow("checkmark.seal", "Doğru bilen 100 puan alır",
                    "Sonuç açıklandığında haklı taraftaki her sözleşme 100 puana döner, yanlış taraf sıfırlanır.")
            ruleRow("brain.head.profile", "Asıl ölçü isabet",
                    "Öngörü Skoru puanını değil, verdiğin olasılıkların ne kadar kalibre olduğunu ölçer.")
        }
        .card(padding: 16)
    }

    private func ruleRow(_ icon: String, _ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: icon).font(.system(size: 14))
                .foregroundStyle(Palette.accent).frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.text)
                Text(text).font(.system(size: 12)).foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var startButton: some View {
        Button {
            focused = false
            store.completeOnboarding(name: name, withSampleRecord: sample)
        } label: {
            Text("Başla")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Palette.bg)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Palette.accent)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var disclaimer: some View {
        Text("Öngörü'de gerçek para yoktur: para yatırma, çekme veya nakde çevirme yoktur. Gösterilen toplulaştırılmış beklentiler yatırım tavsiyesi değildir.")
            .font(.system(size: 11))
            .foregroundStyle(Palette.faint)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, 30)
    }
}
