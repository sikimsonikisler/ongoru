import SwiftUI

struct TradeSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let marketId: String
    var initialSide: Side

    @State private var side: Side = .yes
    @State private var budget: Double = 500
    @State private var addThesis = false
    @State private var thesisText = ""
    @State private var sources: [EvidenceSource] = []
    @State private var newSource = ""

    private var market: Market? { store.market(id: marketId) }
    private var cash: Double { store.state.me.cash }

    private var shares: Double {
        guard let market else { return 0 }
        return LMSR.shares(forBudget: budget, market: market, side: side)
    }
    private var avgPrice: Double {
        guard let market, shares > 0 else { return market?.price(for: side) ?? 0 }
        return LMSR.averageFillPrice(market: market, side: side, shares: shares)
    }
    private var payout: Double { shares * 100 }
    private var profit: Double { payout - budget }

    private var thesisVerdict: ModerationResult {
        ContentModerator.check(thesisText, kind: .thesis)
    }
    private var blockedByModeration: Bool { addThesis && thesisVerdict.isBlocked }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let market {
                    VStack(alignment: .leading, spacing: 18) {
                        question(market)
                        sidePicker(market)
                        amountBlock()
                        preview(market)
                        thesisBlock(market)
                        Color.clear.frame(height: 90)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                }
            }
            .background(Palette.bg)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(L("İşlem", "Trade"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L("Vazgeç", "Cancel")) { dismiss() }.foregroundStyle(Palette.muted)
                }
            }
            .safeAreaInset(edge: .bottom) { confirmBar }
            .onAppear { side = initialSide }
        }
        .presentationDetents([.large])
        .presentationBackground(Palette.bg)
    }

    private func question(_ m: Market) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            CategoryBadge(category: m.category)
            Text(m.question.s)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Palette.text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func sidePicker(_ m: Market) -> some View {
        HStack(spacing: 8) {
            ForEach(Side.allCases, id: \.self) { s in
                Button {
                    Haptics.select()
                    withAnimation(.easeOut(duration: 0.18)) { side = s }
                } label: {
                    VStack(spacing: 3) {
                        HStack(spacing: 4) {
                            Image(systemName: s.glyph).font(.system(size: 9, weight: .bold))
                            Text(s.title).font(.system(size: 12, weight: .bold))
                        }
                        Text(Fmt.cents(m.price(for: s))).font(.mono(20, .bold))
                    }
                    .foregroundStyle(side == s ? Palette.bg : s.color)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(side == s ? s.color : s.dimColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(s.color.opacity(side == s ? 0 : 0.3), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(side == s ? [.isSelected] : [])
            }
        }
    }

    private func amountBlock() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(L("HARCANACAK PUAN", "POINTS TO SPEND"))
                    .font(.system(size: 9, weight: .bold)).kerning(0.7)
                    .foregroundStyle(Palette.faint)
                Spacer()
                Text(L("Nakit: \(Fmt.puan(cash))", "Cash: \(Fmt.puan(cash))"))
                    .font(.mono(10, .medium)).foregroundStyle(Palette.muted)
            }
            Text(Fmt.puan(budget))
                .font(.mono(34, .bold))
                .foregroundStyle(Palette.text)
                .contentTransition(.numericText())

            Slider(value: $budget, in: 50...max(100, cash), step: 50)
                .tint(side.color)

            HStack(spacing: 7) {
                ForEach([250.0, 500.0, 1_000.0, 2_500.0], id: \.self) { v in
                    quickChip(Fmt.puan(v)) { budget = min(v, cash) }
                }
                quickChip(L("Maks", "Max")) { budget = max(50, cash) }
            }
        }
        .card(padding: 15)
    }

    private func quickChip(_ label: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.select()
            action()
        } label: {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Palette.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(Palette.surfaceHigh)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func preview(_ m: Market) -> some View {
        let impact = (avgPrice - m.price(for: side)) * 100
        return VStack(spacing: 11) {
            row(L("Sözleşme adedi", "Contracts"), Fmt.puan(shares), Palette.text)
            row(L("Ortalama fiyat", "Average price"), Fmt.cents(avgPrice), Palette.text)
            row(L("Fiyat etkisi", "Price impact"),
                Fmt.signedDecimal(impact, decimals: 2) + L(" puan", " pts"), Palette.muted)
            Divider().overlay(Palette.stroke)
            row(L("Haklı çıkarsan", "If you're right"),
                Fmt.puan(payout) + L(" puan", " points"), Palette.yes)
            row(L("Net kazanç", "Net gain"),
                Fmt.signed(profit) + L(" puan", " points"), profit >= 0 ? Palette.yes : Palette.no)
            row(L("Yanılırsan", "If you're wrong"),
                "−" + Fmt.puan(budget) + L(" puan", " points"), Palette.no)
        }
        .card(padding: 15)
    }

    private func row(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Text(label).font(.system(size: 12)).foregroundStyle(Palette.muted)
            Spacer()
            Text(value).font(.mono(13, .semibold)).foregroundStyle(color)
        }
    }

    private func thesisBlock(_ m: Market) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $addThesis.animation(.easeInOut(duration: 0.2))) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("Gerekçeni de yaz", "Add your rationale"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Palette.text)
                    Text(L("Gerekçeli tahminler sicilinde ayrıca izlenir",
                           "Reasoned predictions are tracked separately in your record"))
                        .font(.system(size: 11)).foregroundStyle(Palette.faint)
                }
            }
            .tint(Palette.accent)

            if addThesis {
                ThesisEditor(market: m, side: side, text: $thesisText,
                             sources: $sources, newSource: $newSource)
            }
        }
        .card(padding: 15)
    }

    private var confirmBar: some View {
        VStack(spacing: 0) {
            Divider().overlay(Palette.stroke)
            Button {
                guard store.execute(marketId: marketId, side: side, budget: budget) != nil else { return }
                if addThesis, !thesisText.trimmingCharacters(in: .whitespaces).isEmpty {
                    _ = store.postThesis(marketId: marketId, side: side,
                                         text: thesisText, sources: sources)
                }
                dismiss()
            } label: {
                HStack(spacing: 7) {
                    Text(blockedByModeration
                         ? L("Gerekçe kurallara takıldı", "Rationale blocked by the rules")
                         : L("\(side.title) al", "Buy \(side.title)"))
                        .font(.system(size: 16, weight: .bold))
                    if !blockedByModeration {
                        Text("· \(Fmt.puan(budget))").font(.mono(14, .semibold)).opacity(0.75)
                    }
                }
                .foregroundStyle(canTrade ? Palette.bg : Palette.muted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(canTrade ? side.color : Palette.surfaceHigh)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!canTrade)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
        .background(.ultraThinMaterial)
    }

    private var canTrade: Bool {
        budget > 0 && budget <= cash && !blockedByModeration
    }
}

// MARK: - Gerekçe düzenleyici (asistan + moderasyon)

struct ThesisEditor: View {
    @EnvironmentObject var store: AppStore
    var market: Market
    var side: Side
    @Binding var text: String
    @Binding var sources: [EvidenceSource]
    @Binding var newSource: String
    @FocusState private var focus: EditorField?

    enum EditorField { case thesis, source }

    private var quality: Int { ThesisAnalyzer.quality(text: text, sources: sources) }
    private var verdict: ModerationResult { ContentModerator.check(text, kind: .thesis) }

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(L("Neden \(side.title) diyorsun? Mekanizmayı ve sayısal eşiği yaz.",
                           "Why \(side.title)? Give the mechanism and a numeric threshold."))
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.faint)
                        .padding(.horizontal, 12).padding(.vertical, 12)
                }
                TextEditor(text: $text)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.text)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 96)
                    .padding(.horizontal, 7).padding(.vertical, 4)
                    .focused($focus, equals: .thesis)
            }
            .background(Palette.surfaceHigh)
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(verdict.isBlocked ? Palette.no.opacity(0.55) : .clear, lineWidth: 1.2))
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(L("Bitti", "Done")) { focus = nil }
                }
            }

            if !verdict.isClean { ModerationBanner(result: verdict) }

            qualityMeter
            sourcesBlock

            VStack(alignment: .leading, spacing: 11) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles").font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Palette.accent)
                    Text(L("Asistan", "Assistant")).font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Palette.text)
                }
                ForEach(store.thesisPrompts(market: market, side: side, text: text, sources: sources)) {
                    InsightRow(insight: $0)
                }
            }
            .padding(12)
            .background(Palette.bg.opacity(0.55))
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        }
    }

    private var qualityMeter: some View {
        HStack(spacing: 9) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.stroke)
                    Capsule().fill(qualityColor)
                        .frame(width: geo.size.width * CGFloat(quality) / 100)
                        .animation(.easeOut(duration: 0.25), value: quality)
                }
            }
            .frame(height: 5)
            Text("\(quality)/100 · \(ThesisAnalyzer.qualityLabel(quality))")
                .font(.mono(10, .semibold))
                .foregroundStyle(qualityColor)
                .frame(width: 118, alignment: .trailing)
        }
    }

    private var qualityColor: Color {
        switch quality {
        case 75...: return Palette.yes
        case 45..<75: return Palette.gold
        default: return Palette.faint
        }
    }

    private var sourcesBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(L("KAYNAKLAR", "SOURCES")).font(.system(size: 9, weight: .bold)).kerning(0.7)
                    .foregroundStyle(Palette.faint)
                Spacer()
                Text("\(sources.count)/3").font(.mono(10, .semibold))
                    .foregroundStyle(sources.count >= 3 ? Palette.yes : Palette.faint)
            }

            ForEach(sources) { s in
                HStack(spacing: 8) {
                    Image(systemName: "doc.text").font(.system(size: 10))
                        .foregroundStyle(Palette.accent)
                    Text(s.title.s).font(.system(size: 12)).foregroundStyle(Palette.text)
                    Spacer()
                    Button {
                        sources.removeAll { $0.id == s.id }
                    } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 12))
                            .foregroundStyle(Palette.faint)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 10).padding(.vertical, 8)
                .background(Palette.surfaceHigh)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            }

            HStack(spacing: 8) {
                TextField("", text: $newSource,
                          prompt: Text(L("Kaynak ekle", "Add a source")).foregroundStyle(Palette.faint))
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.text)
                    .focused($focus, equals: .source)
                    .onSubmit(addSource)
                    .padding(.horizontal, 10).padding(.vertical, 9)
                    .background(Palette.surfaceHigh)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                Button(action: addSource) {
                    Image(systemName: "plus").font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Palette.bg)
                        .frame(width: 34, height: 34)
                        .background(newSource.isEmpty ? Palette.faint : Palette.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(newSource.isEmpty)
                .accessibilityLabel(L("Kaynak ekle", "Add source"))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(ThesisAnalyzer.suggestedSources(for: market.category), id: \.self) { s in
                        Button {
                            guard !sources.contains(where: { $0.title.s == s }) else { return }
                            Haptics.tap()
                            sources.append(EvidenceSource(title: LText(s), detail: nil))
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus").font(.system(size: 8, weight: .bold))
                                Text(s).font(.system(size: 10, weight: .medium))
                            }
                            .foregroundStyle(Palette.muted)
                            .padding(.horizontal, 9).padding(.vertical, 6)
                            .background(Palette.surfaceHigh.opacity(0.7))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .scrollClipDisabled()
        }
    }

    private func addSource() {
        let t = newSource.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        let check = ContentModerator.check(t, kind: .thesis)
        guard !check.isBlocked else {
            Haptics.error()
            newSource = ""
            return
        }
        sources.append(EvidenceSource(title: LText(t), detail: nil))
        newSource = ""
    }
}
