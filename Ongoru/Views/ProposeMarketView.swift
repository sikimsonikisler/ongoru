import SwiftUI

struct ProposeMarketView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var question = ""
    @State private var detail = ""
    @State private var source = ""
    @State private var category: Category = .ekonomi
    @State private var closeDate = Date().addingTimeInterval(30 * 86_400)
    @State private var probability: Double = 50
    @FocusState private var focus: Field?

    enum Field { case question, detail, source }

    private var verdict: ModerationResult {
        ContentModerator.check(question + "\n" + detail, kind: .marketQuestion)
    }

    private var canSubmit: Bool {
        question.trimmingCharacters(in: .whitespaces).count >= 12 &&
        detail.trimmingCharacters(in: .whitespaces).count >= 15 &&
        !verdict.isBlocked
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    intro
                    field(L("SORU", "QUESTION"),
                          L("Evet/hayır ile cevaplanabilen bir soru yaz",
                            "Write a question answerable with yes or no"),
                          text: $question, focusValue: .question, minHeight: 74)
                    categoryPicker
                    field(L("ÇÖZÜM KRİTERİ", "RESOLUTION CRITERIA"),
                          L("Hangi durumda EVET sayılacağını tarif et — sayı ve tarih ver",
                            "Describe exactly when it counts as YES — give a number and a date"),
                          text: $detail, focusValue: .detail, minHeight: 84)
                    sourceField
                    dateRow
                    probabilityRow
                    if !verdict.isClean { ModerationBanner(result: verdict) }
                    rules
                    Color.clear.frame(height: 90)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(Palette.bg)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(L("Piyasa öner", "Propose a market"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L("Vazgeç", "Cancel")) { dismiss() }.foregroundStyle(Palette.muted)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(L("Bitti", "Done")) { focus = nil }
                }
            }
            .safeAreaInset(edge: .bottom) { submitBar }
        }
        .presentationBackground(Palette.bg)
    }

    private var intro: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "info.circle").font(.system(size: 12))
                .foregroundStyle(Palette.accent)
            Text(L("İyi bir piyasa sorusu tek bir olayı, tek bir eşikle ve tek bir tarihle sorar. “Ekonomi düzelir mi?” kötü; “Yıllık enflasyon Aralık'ta %20'nin altına iner mi?” iyi bir sorudur.",
                   "A good market question asks about one event, with one threshold and one date. “Will the economy improve?” is bad; “Will annual inflation fall below 20% in December?” is good."))
                .font(.system(size: 12)).foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .card(padding: 13)
    }

    private func field(_ label: String, _ placeholder: String,
                       text: Binding<String>, focusValue: Field, minHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label).font(.system(size: 9, weight: .bold)).kerning(0.7)
                .foregroundStyle(Palette.faint)
            ZStack(alignment: .topLeading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 13)).foregroundStyle(Palette.faint)
                        .padding(.horizontal, 12).padding(.vertical, 12)
                }
                TextEditor(text: text)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.text)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: minHeight)
                    .padding(.horizontal, 7).padding(.vertical, 4)
                    .focused($focus, equals: focusValue)
            }
            .background(Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(verdict.isBlocked ? Palette.no.opacity(0.5) : Palette.stroke, lineWidth: 1))
        }
    }

    private var sourceField: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(L("ÇÖZÜM KAYNAĞI", "RESOLUTION SOURCE"))
                .font(.system(size: 9, weight: .bold)).kerning(0.7)
                .foregroundStyle(Palette.faint)
            TextField("", text: $source,
                      prompt: Text(L("Örn. TÜİK enflasyon bülteni", "e.g. TurkStat inflation bulletin"))
                        .foregroundStyle(Palette.faint))
                .font(.system(size: 13))
                .foregroundStyle(Palette.text)
                .focused($focus, equals: .source)
                .padding(.horizontal, 12).padding(.vertical, 12)
                .background(Palette.surface)
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(Palette.stroke, lineWidth: 1))
        }
    }

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(L("KATEGORİ", "CATEGORY")).font(.system(size: 9, weight: .bold)).kerning(0.7)
                .foregroundStyle(Palette.faint)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    ForEach(Category.allCases) { c in
                        Button {
                            Haptics.select()
                            category = c
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: c.icon).font(.system(size: 10, weight: .semibold))
                                Text(c.title).font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundStyle(category == c ? Palette.bg : c.tint)
                            .padding(.horizontal, 11).padding(.vertical, 7)
                            .background(category == c ? c.tint : c.tint.opacity(0.12))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .scrollClipDisabled()
        }
    }

    private var dateRow: some View {
        HStack {
            Text(L("Kapanış tarihi", "Close date"))
                .font(.system(size: 13, weight: .medium)).foregroundStyle(Palette.text)
            Spacer()
            DatePicker("", selection: $closeDate,
                       in: Date().addingTimeInterval(86_400)...Date().addingTimeInterval(730 * 86_400),
                       displayedComponents: .date)
                .labelsHidden()
                .environment(\.locale, I18N.locale)
        }
        .card(padding: 13)
    }

    private var probabilityRow: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text(L("Açılış fiyatı", "Opening price"))
                    .font(.system(size: 13, weight: .medium)).foregroundStyle(Palette.text)
                Spacer()
                Text("\(Int(probability))¢")
                    .font(.mono(16, .bold)).foregroundStyle(Palette.accent)
            }
            Slider(value: $probability, in: 5...95, step: 1).tint(Palette.accent)
            Text(L("Sence bu sonucun olasılığı ne? Piyasa buradan başlar, sonra kalabalık taşır.",
                   "What's your own probability? The market opens here, then the crowd moves it."))
                .font(.system(size: 11)).foregroundStyle(Palette.faint)
                .fixedSize(horizontal: false, vertical: true)
        }
        .card(padding: 13)
    }

    private var rules: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(L("YAYIN KURALLARI", "PUBLISHING RULES"))
                .font(.system(size: 9, weight: .bold)).kerning(0.7)
                .foregroundStyle(Palette.faint)
            rule(L("Belirli bir kişiye suç isnadı içeren soru açılamaz.",
                   "Questions accusing a named person of a crime are not allowed."))
            rule(L("Küfür, hakaret, nefret söylemi ve tehdit yasaktır.",
                   "Profanity, insults, hate speech and threats are prohibited."))
            rule(L("Kişisel veri (telefon, adres, kimlik no) paylaşılamaz.",
                   "Personal data (phone, address, ID number) cannot be shared."))
            rule(L("Bir kişinin sağlığı, ölümü veya özel hayatı piyasa konusu yapılamaz.",
                   "A person's health, death or private life cannot be a market."))
        }
        .card(padding: 14)
    }

    private func rule(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "xmark.circle").font(.system(size: 10))
                .foregroundStyle(Palette.no.opacity(0.8)).padding(.top, 1)
            Text(text).font(.system(size: 12)).foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private var submitBar: some View {
        VStack(spacing: 0) {
            Divider().overlay(Palette.stroke)
            Button {
                focus = nil
                let result = store.propose(question: question, detail: detail, source: source,
                                           category: category, closeDate: closeDate,
                                           probability: probability / 100)
                if !result.isBlocked { dismiss() }
            } label: {
                Text(verdict.isBlocked
                     ? L("Kurallara takıldı", "Blocked by the rules")
                     : L("Yayımla", "Publish"))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(canSubmit ? Palette.bg : Palette.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(canSubmit ? Palette.accent : Palette.surfaceHigh)
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!canSubmit)
            .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 8)
        }
        .background(.ultraThinMaterial)
    }
}

// MARK: - Moderasyon uyarısı

struct ModerationBanner: View {
    var result: ModerationResult

    private var tint: Color { result.isBlocked ? Palette.no : Palette.gold }

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: result.isBlocked ? "hand.raised.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundStyle(tint)
                .frame(width: 26, height: 26)
                .background(tint.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(result.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(tint)
                Text(result.explanation)
                    .font(.system(size: 12)).foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
                if !result.evidence.isEmpty {
                    Text(L("Tespit edilen: ", "Detected: ") + "“\(result.evidence)”")
                        .font(.mono(11))
                        .foregroundStyle(Palette.faint)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(13)
        .background(tint.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous)
            .strokeBorder(tint.opacity(0.35), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - İçerik bildirme

struct ReportSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var targetKind: String
    var targetId: String

    @State private var reason: ReportReason = .hakaret
    @State private var note = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(L("Bu içeriği neden bildiriyorsun?", "Why are you reporting this?"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Palette.text)

                    VStack(spacing: 8) {
                        ForEach(ReportReason.allCases) { r in
                            Button {
                                Haptics.select()
                                reason = r
                            } label: {
                                HStack(spacing: 11) {
                                    Image(systemName: reason == r ? "largecircle.fill.circle" : "circle")
                                        .font(.system(size: 17))
                                        .foregroundStyle(reason == r ? Palette.accent : Palette.faint)
                                    Text(r.label).font(.system(size: 13))
                                        .foregroundStyle(Palette.text)
                                    Spacer()
                                }
                                .padding(12)
                                .background(reason == r ? Palette.accent.opacity(0.07) : Palette.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    TextField("", text: $note, prompt: Text(L("İstersen kısa bir not ekle",
                                                              "Add a short note if you like"))
                        .foregroundStyle(Palette.faint), axis: .vertical)
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.text)
                        .lineLimit(3...5)
                        .padding(12)
                        .background(Palette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

                    Text(L("Bildirdiğin içerik senden hemen gizlenir. Gerçek üründe bildirimler bir moderasyon kuyruğuna düşer.",
                           "Reported content is hidden from you immediately. In production, reports would go to a moderation queue."))
                        .font(.system(size: 11)).foregroundStyle(Palette.faint)
                        .fixedSize(horizontal: false, vertical: true)

                    Button {
                        store.report(targetKind: targetKind, targetId: targetId,
                                     reason: reason, note: note.isEmpty ? nil : note)
                        dismiss()
                    } label: {
                        Text(L("Bildir", "Report"))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Palette.bg)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Palette.no)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
            }
            .background(Palette.bg)
            .navigationTitle(L("İçeriği bildir", "Report content"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("Kapat", "Close")) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Palette.bg)
    }
}
