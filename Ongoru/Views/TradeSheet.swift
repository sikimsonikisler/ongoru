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
            .navigationTitle("İşlem")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Vazgeç") { dismiss() }.foregroundStyle(Palette.muted)
                }
            }
            .safeAreaInset(edge: .bottom) { confirmBar }
            .onAppear { side = initialSide }
        }
        .presentationDetents([.large])
        .presentationBackground(Palette.bg)
    }

    // MARK: Soru

    private func question(_ m: Market) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            CategoryBadge(category: m.category)
            Text(m.question)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Palette.text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Taraf

    private func sidePicker(_ m: Market) -> some View {
        HStack(spacing: 8) {
            ForEach(Side.allCases, id: \.self) { s in
                Button { withAnimation(.easeOut(duration: 0.18)) { side = s } } label: {
                    VStack(spacing: 3) {
                        Text(s.title).font(.system(size: 12, weight: .bold))
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
            }
        }
    }

    // MARK: Tutar

    private func amountBlock() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("HARCANACAK PUAN").font(.system(size: 9, weight: .bold)).kerning(0.7)
                    .foregroundStyle(Palette.faint)
                Spacer()
                Text("Nakit: \(Fmt.puan(cash))").font(.mono(10, .medium))
                    .foregroundStyle(Palette.muted)
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
                quickChip("Maks") { budget = max(50, cash) }
            }
        }
        .card(padding: 15)
    }

    private func quickChip(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
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

    // MARK: Önizleme

    private func preview(_ m: Market) -> some View {
        let impact = (avgPrice - m.price(for: side)) * 100
        return VStack(spacing: 11) {
            row("Sözleşme adedi", Fmt.puan(shares), Palette.text)
            row("Ortalama fiyat", Fmt.cents(avgPrice), Palette.text)
            row("Fiyat etkisi", Fmt.signedDecimal(impact, decimals: 2) + " puan", Palette.muted)
            Divider().overlay(Palette.stroke)
            row("Haklı çıkarsan", Fmt.puan(payout) + " puan", Palette.yes)
            row("Net kazanç", Fmt.signed(profit) + " puan", profit >= 0 ? Palette.yes : Palette.no)
            row("Yanılırsan", "−" + Fmt.puan(budget) + " puan", Palette.no)
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

    // MARK: Gerekçe

    private func thesisBlock(_ m: Market) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $addThesis.animation(.easeInOut(duration: 0.2))) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Gerekçeni de yaz").font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Palette.text)
                    Text("Gerekçeli tahminler sicilinde ayrıca izlenir")
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

    // MARK: Onay

    private var confirmBar: some View {
        VStack(spacing: 0) {
            Divider().overlay(Palette.stroke)
            Button {
                guard let trade = store.execute(marketId: marketId, side: side, budget: budget) else { return }
                if addThesis, !thesisText.trimmingCharacters(in: .whitespaces).isEmpty {
                    store.postThesis(marketId: marketId, side: side, text: thesisText, sources: sources)
                }
                _ = trade
                dismiss()
            } label: {
                HStack(spacing: 7) {
                    Text("\(side.title) al").font(.system(size: 16, weight: .bold))
                    Text("· \(Fmt.puan(budget)) puan").font(.mono(14, .semibold)).opacity(0.75)
                }
                .foregroundStyle(Palette.bg)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(budget <= cash && budget > 0 ? side.color : Palette.faint)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(budget > cash || budget <= 0)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
        .background(.ultraThinMaterial)
    }
}

// MARK: - Gerekçe düzenleyici (asistanla birlikte)

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

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Neden \(side.title) diyorsun? Mekanizmayı ve sayısal eşiği yaz.")
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
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Bitti") { focus = nil }
                }
            }

            qualityMeter

            sourcesBlock

            VStack(alignment: .leading, spacing: 11) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles").font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Palette.accent)
                    Text("Asistan").font(.system(size: 11, weight: .bold))
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
                Text("KAYNAKLAR").font(.system(size: 9, weight: .bold)).kerning(0.7)
                    .foregroundStyle(Palette.faint)
                Spacer()
                Text("\(sources.count)/3").font(.mono(10, .semibold))
                    .foregroundStyle(sources.count >= 3 ? Palette.yes : Palette.faint)
            }

            ForEach(sources) { s in
                HStack(spacing: 8) {
                    Image(systemName: "doc.text").font(.system(size: 10))
                        .foregroundStyle(Palette.accent)
                    Text(s.title).font(.system(size: 12)).foregroundStyle(Palette.text)
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
                          prompt: Text("Kaynak ekle").foregroundStyle(Palette.faint))
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
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(ThesisAnalyzer.suggestedSources(for: market.category), id: \.self) { s in
                        Button {
                            guard !sources.contains(where: { $0.title == s }) else { return }
                            sources.append(EvidenceSource(title: s, detail: nil))
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
        sources.append(EvidenceSource(title: t, detail: nil))
        newSource = ""
    }
}
