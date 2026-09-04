import SwiftUI

struct SettingsSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Binding var showResolver: Bool
    @Binding var showSupport: Bool

    @State private var confirmReset = false
    @State private var editingName = false
    @State private var draftName = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    languageSection
                    accountSection
                    supportSection
                    demoSection
                    aboutSection
                    Color.clear.frame(height: 20)
                }
                .padding(16)
            }
            .background(Palette.bg)
            .navigationTitle(L("Ayarlar", "Settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("Kapat", "Close")) { dismiss() }
                }
            }
            .alert(L("Her şey sıfırlansın mı?", "Reset everything?"), isPresented: $confirmReset) {
                Button(L("Vazgeç", "Cancel"), role: .cancel) {}
                Button(L("Sıfırla", "Reset"), role: .destructive) {
                    store.signOut()
                    dismiss()
                }
            } message: {
                Text(L("Hesabın, puanların, pozisyonların ve sicilin silinecek.",
                       "Your account, points, positions and record will be deleted."))
            }
        }
        .presentationBackground(Palette.bg)
    }

    // MARK: Dil

    private var languageSection: some View {
        group(L("Dil", "Language")) {
            VStack(spacing: 8) {
                ForEach(AppLanguage.allCases) { lang in
                    Button {
                        store.setLanguage(lang)
                    } label: {
                        HStack(spacing: 11) {
                            Text(lang.flag).font(.system(size: 16))
                            Text(lang.label).font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Palette.text)
                            if lang == .system {
                                Text("(\(lang.resolved.rawValue.uppercased()))")
                                    .font(.system(size: 11)).foregroundStyle(Palette.faint)
                            }
                            Spacer()
                            if store.language == lang {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16)).foregroundStyle(Palette.accent)
                            }
                        }
                        .padding(13)
                        .background(store.language == lang ? Palette.accent.opacity(0.07) : Palette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(store.language == lang
                                          ? Palette.accent.opacity(0.4) : Palette.stroke, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(store.language == lang ? [.isSelected] : [])
                }
            }
        }
    }

    // MARK: Hesap

    private var accountSection: some View {
        group(L("Hesap", "Account")) {
            VStack(spacing: 9) {
                HStack(spacing: 12) {
                    Avatar(initials: store.me.initials, seed: 0, size: 38)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(store.me.name).font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Palette.text)
                        if let account = store.account {
                            HStack(spacing: 4) {
                                Image(systemName: account.provider.icon).font(.system(size: 9))
                                Text(account.email ?? account.provider.label)
                                    .font(.system(size: 11))
                            }
                            .foregroundStyle(Palette.faint)
                        }
                    }
                    Spacer()
                    Button {
                        draftName = store.me.name
                        editingName = true
                    } label: {
                        Text(L("Düzenle", "Edit")).font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Palette.accent)
                    }
                    .buttonStyle(.plain)
                }
                .card(padding: 13)

                if editingName {
                    HStack(spacing: 8) {
                        TextField("", text: $draftName)
                            .font(.system(size: 14))
                            .foregroundStyle(Palette.text)
                            .autocorrectionDisabled()
                            .padding(.horizontal, 12).padding(.vertical, 10)
                            .background(Palette.surfaceHigh)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        Button {
                            store.rename(draftName)
                            editingName = false
                        } label: {
                            Text(L("Kaydet", "Save"))
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Palette.bg)
                                .padding(.horizontal, 14).padding(.vertical, 11)
                                .background(Palette.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }

                infoNote(L("İlerlemen bu cihazda saklanıyor. Cihazlar arasında taşımak için bir sunucu gerekir; kimlik katmanı (Apple, Google, Öngörü hesabı) bunun için hazır.",
                           "Your progress is stored on this device. Moving it between devices requires a server; the identity layer (Apple, Google, Öngörü account) is ready for that."))

                actionRow("rectangle.portrait.and.arrow.right",
                          L("Çıkış yap ve sıfırla", "Sign out and reset"),
                          L("Hesabın ve tüm ilerlemen silinir.",
                            "Your account and all progress will be deleted."),
                          tint: Palette.no) { confirmReset = true }
            }
        }
    }

    // MARK: Destek

    private var supportSection: some View {
        group(L("Destek", "Support")) {
            actionRow("heart.fill",
                      store.state.supporterTier == nil
                        ? L("Öngörü'yü destekle", "Support Öngörü")
                        : L("Destekçisin — teşekkürler", "You're a supporter — thank you"),
                      L("Neden reklam koymadığımızı ve seçenekleri gör.",
                        "See why we don't run ads, and the options."),
                      tint: Palette.no) {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showSupport = true }
            }
        }
    }

    // MARK: Demo

    private var demoSection: some View {
        group(L("Demo araçları", "Demo tools")) {
            actionRow("bolt.badge.clock",
                      L("Bir piyasayı şimdi sonuçlandır", "Resolve a market now"),
                      L("Sonuç açıklandığında ödemenin ve sicilin nasıl güncellendiğini gör.",
                        "See how the payout and your record update when a result lands.")) {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showResolver = true }
            }
        }
    }

    // MARK: Hakkında

    private var aboutSection: some View {
        group(L("Öngörü hakkında", "About Öngörü")) {
            VStack(alignment: .leading, spacing: 9) {
                bullet(L("Bu uygulamada gerçek para yoktur. Para yatırma, çekme veya nakde çevirme yoktur; puanlar yalnızca sıralama ve sicil içindir.",
                         "There is no real money in this app. No deposits, withdrawals or cash-outs; points exist only for ranking and record-keeping."))
                bullet(L("Toplulaştırılmış beklentiler yatırım tavsiyesi değildir.",
                         "Aggregated expectations are not investment advice."))
                bullet(L("Öngörü Asistanı tamamen cihaz üstünde, kural tabanlı çalışır; hiçbir veri dışarı gönderilmez.",
                         "The Öngörü Assistant is entirely on-device and rule-based; no data leaves your phone."))
                bullet(L("İçerik denetimi de cihaz üstündedir: küfür, nefret söylemi, tehdit, kişisel veri ve kişiye suç isnadı içeren gönderiler engellenir.",
                         "Content moderation is on-device too: profanity, hate speech, threats, personal data and accusations against named individuals are blocked."))
                bullet(L("Piyasa fiyatları LMSR otomatik piyasa yapıcısıyla belirlenir; demo kalabalığı fiyatları canlı tutar.",
                         "Prices are set by an LMSR automated market maker; a simulated crowd keeps them live."))
            }
        }
    }

    // MARK: Yardımcılar

    private func group<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title.uppercased()).font(.system(size: 9, weight: .bold)).kerning(0.7)
                .foregroundStyle(Palette.faint)
            content()
        }
    }

    private func actionRow(_ icon: String, _ title: String, _ sub: String,
                           tint: Color = Palette.accent, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 11) {
                Image(systemName: icon).font(.system(size: 14)).foregroundStyle(tint).frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.text)
                    Text(sub).font(.system(size: 11)).foregroundStyle(Palette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Palette.faint)
            }
            .card(padding: 13)
        }
        .buttonStyle(.plain)
    }

    private func infoNote(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11)).foregroundStyle(Palette.faint)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 2)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle().fill(Palette.faint).frame(width: 4, height: 4).padding(.top, 6)
            Text(text).font(.system(size: 11)).foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Demo çözümleyici

struct ResolverSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    private var candidates: [Market] {
        store.markets.filter { $0.status == .open }.sorted { $0.closeDate < $1.closeDate }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L("Bir piyasayı seçip sonucu belirle. Pozisyonun varsa ödeme yapılır ve sicilin güncellenir.",
                           "Pick a market and set its outcome. If you hold a position it pays out and your record updates."))
                        .font(.system(size: 12)).foregroundStyle(Palette.muted)
                        .fixedSize(horizontal: false, vertical: true)

                    ForEach(candidates.prefix(12)) { m in
                        VStack(alignment: .leading, spacing: 9) {
                            HStack {
                                CategoryBadge(category: m.category)
                                Spacer()
                                if store.position(for: m.id) != nil {
                                    Text(L("pozisyonun var", "you hold this"))
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundStyle(Palette.gold)
                                }
                            }
                            Text(m.question.s).font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Palette.text)
                                .fixedSize(horizontal: false, vertical: true)
                            HStack(spacing: 8) {
                                ForEach(Side.allCases, id: \.self) { s in
                                    Button {
                                        store.forceResolve(marketId: m.id, outcome: s == .yes)
                                        dismiss()
                                    } label: {
                                        Text(L("Sonuç: ", "Result: ") + s.title)
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(s.color)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 9)
                                            .background(s.dimColor)
                                            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .card(padding: 13)
                    }
                }
                .padding(16)
            }
            .background(Palette.bg)
            .navigationTitle(L("Piyasa sonuçlandır", "Resolve a market"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("Kapat", "Close")) { dismiss() }
                }
            }
        }
        .presentationBackground(Palette.bg)
    }
}
