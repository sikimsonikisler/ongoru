import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var store: AppStore

    @State private var name: String = ""
    @State private var sample: Bool = true
    @State private var error: String?
    @State private var busy = false
    @State private var showLocalForm = false
    @FocusState private var focused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                startChoice
                providers
                if let error { errorBox(error) }
                rules
                disclaimer
            }
            .padding(22)
            .padding(.top, 12)
        }
        .background(Palette.bg)
        .scrollDismissesKeyboard(.interactively)
        .overlay(alignment: .topTrailing) {
            LanguageMenu()
                .padding(.horizontal, 22)
                .padding(.top, 8)
        }
    }

    // MARK: Başlık

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
            .padding(.top, 18)

            Text(L("Türkiye'nin kolektif tahmin motoru",
                   "Türkiye's collective forecasting engine"))
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Palette.text)
                .fixedSize(horizontal: false, vertical: true)

            Text(L("Geleceğe dair sorulara olasılık biç, gerekçeni yaz, haklı çıktıkça itibar kazan. Para yok — puan ve sicil var.",
                   "Price the future, write your reasoning, and earn standing by being right. No money — just points and a track record."))
                .font(.system(size: 14))
                .foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Başlangıç tercihi

    private var startChoice: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L("NASIL BAŞLAYALIM", "HOW TO START"))
                .font(.system(size: 10, weight: .bold)).kerning(0.8)
                .foregroundStyle(Palette.faint)
            choiceRow(
                selected: sample,
                title: L("Sezon ortasından başla", "Start mid-season"),
                body: L("18 sonuçlanmış tahmin, 6 açık pozisyon ve 128.000 puanlık bir demo hesabı. Öngörü Skoru'nu ilk açılışta görürsün.",
                        "18 resolved predictions, 6 open positions and a 128,000-point demo account. You see your Forecast Score right away."),
                action: { sample = true })
            choiceRow(
                selected: !sample,
                title: L("Sıfırdan başla", "Start from scratch"),
                body: L("10.000 puan, boş portföy, boş sicil. Skorun ilk piyasan sonuçlanınca oluşmaya başlar.",
                        "10,000 points, empty portfolio, empty record. Your score builds once your first market resolves."),
                action: { sample = false })
        }
    }

    private func choiceRow(selected: Bool, title: String, body: String,
                           action: @escaping () -> Void) -> some View {
        Button {
            Haptics.select()
            action()
        } label: {
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
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    // MARK: Giriş sağlayıcıları

    private var providers: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L("HESAP", "ACCOUNT"))
                .font(.system(size: 10, weight: .bold)).kerning(0.8)
                .foregroundStyle(Palette.faint)

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                handleApple(result)
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

            Button {
                Task { await handleGoogle() }
            } label: {
                HStack(spacing: 9) {
                    Image(systemName: "g.circle.fill").font(.system(size: 17, weight: .medium))
                    Text(L("Google ile devam et", "Continue with Google"))
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(Palette.text)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Palette.surfaceHigh)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .strokeBorder(Palette.stroke, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(busy)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showLocalForm.toggle() }
            } label: {
                HStack(spacing: 9) {
                    Image(systemName: "person.crop.circle").font(.system(size: 16))
                    Text(L("Öngörü hesabı oluştur", "Create an Öngörü account"))
                        .font(.system(size: 15, weight: .semibold))
                    Spacer()
                    Image(systemName: showLocalForm ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(Palette.muted)
                .padding(.horizontal, 15)
                .frame(height: 48)
                .background(Palette.surface)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .strokeBorder(Palette.stroke, lineWidth: 1))
            }
            .buttonStyle(.plain)

            if showLocalForm { localForm }
        }
    }

    private var localForm: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("", text: $name,
                      prompt: Text(L("Ligde görünecek isim", "Name shown on the leaderboard"))
                        .foregroundStyle(Palette.faint))
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Palette.text)
                .focused($focused)
                .submitLabel(.done)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
                .padding(.horizontal, 14).padding(.vertical, 13)
                .background(Palette.surfaceHigh)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(focused ? Palette.accent.opacity(0.6) : Palette.stroke, lineWidth: 1))

            Text(L("Parola istemiyoruz. Sunucu olmadan parolayı cihazda saklamak güvenlik hissi verir ama korumaz; ilerlemen bu cihazda tutulur.",
                   "We don't ask for a password. Storing one on-device without a server would feel secure without being secure; your progress is kept on this device."))
                .font(.system(size: 11))
                .foregroundStyle(Palette.faint)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                focused = false
                let account = store.auth.localAccount(name: name)
                store.completeSignIn(account: account, withSampleRecord: sample)
            } label: {
                Text(L("Başla", "Get started"))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Palette.bg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Palette.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(13)
        .background(Palette.surface.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    private func errorBox(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12)).foregroundStyle(Palette.gold)
            Text(message)
                .font(.system(size: 12)).foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Palette.gold.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
    }

    // MARK: Kurallar

    private var rules: some View {
        VStack(alignment: .leading, spacing: 12) {
            ruleRow("number.circle", L("Fiyat = olasılık", "Price = probability"),
                    L("63¢, kalabalığın o sonuca %63 ihtimal verdiği anlamına gelir. EVET + HAYIR her zaman 100¢.",
                      "63¢ means the crowd puts the outcome at 63%. YES + NO always adds to 100¢."))
            ruleRow("checkmark.seal", L("Doğru bilen 100 puan alır", "Being right pays 100 points"),
                    L("Sonuç açıklandığında haklı taraftaki her sözleşme 100 puana döner, yanlış taraf sıfırlanır.",
                      "When the result lands, every contract on the right side becomes 100 points; the other side goes to zero."))
            ruleRow("brain.head.profile", L("Asıl ölçü isabet", "Accuracy is what counts"),
                    L("Öngörü Skoru puanını değil, verdiğin olasılıkların ne kadar kalibre olduğunu ölçer.",
                      "The Forecast Score measures how well calibrated your probabilities are, not how many points you hold."))
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

    private var disclaimer: some View {
        Text(L("Öngörü'de gerçek para yoktur: para yatırma, çekme veya nakde çevirme yoktur. Gösterilen toplulaştırılmış beklentiler yatırım tavsiyesi değildir.",
               "There is no real money on Öngörü: no deposits, no withdrawals, no cash-out. Aggregated expectations shown here are not investment advice."))
            .font(.system(size: 11))
            .foregroundStyle(Palette.faint)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, 30)
    }

    // MARK: Akışlar

    private func handleApple(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            do {
                let account = try store.auth.account(from: authorization)
                store.completeSignIn(account: account, withSampleRecord: sample)
            } catch {
                self.error = (error as? AuthError)?.errorDescription ?? error.localizedDescription
            }
        case .failure(let err):
            let mapped = store.auth.describe(err)
            if mapped == .cancelled { return }
            self.error = mapped.errorDescription
            Haptics.error()
        }
    }

    private func handleGoogle() async {
        busy = true
        defer { busy = false }
        do {
            let account = try await store.auth.signInWithGoogle()
            store.completeSignIn(account: account, withSampleRecord: sample)
        } catch AuthError.cancelled {
            return
        } catch AuthError.googleNotConfigured {
            error = L("Google ile giriş için Google Cloud Console'da bir iOS OAuth istemcisi oluşturup istemci kimliğini Auth.swift içindeki GoogleConfig.clientID alanına yazman gerekiyor. Akışın kalanı (PKCE, token değişimi) hazır.",
                      "Sign in with Google needs an iOS OAuth client created in Google Cloud Console, with its client ID placed in GoogleConfig.clientID in Auth.swift. The rest of the flow (PKCE, token exchange) is already implemented.")
            Haptics.warning()
        } catch {
            self.error = (error as? AuthError)?.errorDescription ?? error.localizedDescription
            Haptics.error()
        }
    }
}
