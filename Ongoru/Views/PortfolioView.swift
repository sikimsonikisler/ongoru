import SwiftUI

struct PortfolioView: View {
    @EnvironmentObject var store: AppStore
    @State private var tab: Int = 0
    @State private var path: [String] = []

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 14) {
                    summary
                    Picker("", selection: $tab) {
                        Text("Açık pozisyon").tag(0)
                        Text("Sonuçlananlar").tag(1)
                        Text("İşlem geçmişi").tag(2)
                    }
                    .pickerStyle(.segmented)

                    switch tab {
                    case 0: openPositions
                    case 1: settled
                    default: history
                    }
                    Color.clear.frame(height: 20)
                }
                .padding(.horizontal, 14)
                .padding(.top, 4)
            }
            .background(Palette.bg)
            .navigationTitle("Portföy")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: String.self) { MarketDetailView(marketId: $0) }
        }
    }

    // MARK: Özet

    private var summary: some View {
        VStack(spacing: 14) {
            VStack(spacing: 3) {
                Text("TOPLAM DEĞER").font(.system(size: 9, weight: .bold)).kerning(0.7)
                    .foregroundStyle(Palette.faint)
                Text(Fmt.puan(store.totalPoints))
                    .font(.mono(34, .bold)).foregroundStyle(Palette.text)
                    .contentTransition(.numericText())
                HStack(spacing: 5) {
                    Image(systemName: store.openPnL >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 9, weight: .bold))
                    Text(Fmt.signed(store.openPnL) + " puan açık K/Z")
                        .font(.mono(12, .semibold))
                }
                .foregroundStyle(store.openPnL >= 0 ? Palette.yes : Palette.no)
            }
            Divider().overlay(Palette.stroke)
            HStack(spacing: 0) {
                StatTile(label: "Nakit", value: Fmt.puan(store.state.me.cash))
                StatTile(label: "Pozisyonda", value: Fmt.puan(store.portfolioValue))
                StatTile(label: "Lig sırası", value: "\(store.myRank).", accent: Palette.gold)
                StatTile(label: "Öngörü skoru", value: "\(store.scoreCard.score)",
                         accent: store.scoreCard.score >= 60 ? Palette.yes : Palette.text)
            }
        }
        .card(padding: 16)
    }

    // MARK: Açık pozisyonlar

    @ViewBuilder
    private var openPositions: some View {
        if store.positions.isEmpty {
            EmptyState(icon: "tray", title: "Açık pozisyon yok",
                       message: "Piyasalar sekmesinden bir soruya olasılık biçerek başla.")
                .card()
        } else {
            ForEach(store.positions) { pos in
                if let m = store.market(id: pos.marketId) {
                    Button { path.append(m.id) } label: { positionRow(pos, m) }
                        .buttonStyle(.plain)
                }
            }
        }
    }

    private func positionRow(_ pos: Position, _ m: Market) -> some View {
        let side = pos.netSide ?? .yes
        let pnl = pos.pnl(at: m)
        let pct = pos.cost > 0 ? pnl / pos.cost * 100 : 0
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Text(side.title).font(.system(size: 9, weight: .bold))
                    .foregroundStyle(side.color)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(side.dimColor).clipShape(Capsule())
                CategoryBadge(category: m.category)
                Spacer()
                Text(Fmt.kalan(m.closeDate)).font(.system(size: 10))
                    .foregroundStyle(Palette.faint)
            }
            Text(m.question)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Palette.text)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 0) {
                StatTile(label: "Adet", value: Fmt.puan(pos.shares))
                StatTile(label: "Maliyet", value: Fmt.cents(pos.avgPrice(for: side)))
                StatTile(label: "Şimdi", value: Fmt.cents(m.price(for: side)),
                         accent: m.price(for: side) >= pos.avgPrice(for: side) ? Palette.yes : Palette.no)
                StatTile(label: "K/Z", value: Fmt.signed(pnl),
                         accent: pnl >= 0 ? Palette.yes : Palette.no,
                         sub: Fmt.signedDecimal(pct) + "%")
            }
        }
        .card()
    }

    // MARK: Sonuçlananlar

    @ViewBuilder
    private var settled: some View {
        if store.settlements.isEmpty {
            EmptyState(icon: "checkmark.circle", title: "Henüz sonuçlanan tahmin yok",
                       message: "Bir piyasa kapandığında sonucu burada görünür ve sicilini etkiler.")
                .card()
        } else {
            ForEach(store.settlements) { s in settlementRow(s) }
        }
    }

    private func settlementRow(_ s: Settlement) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: s.correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(s.correct ? Palette.yes : Palette.no)
            VStack(alignment: .leading, spacing: 5) {
                Text(s.question)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Palette.text)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 6) {
                    Text(s.mySide.title).font(.system(size: 9, weight: .bold))
                        .foregroundStyle(s.mySide.color)
                        .padding(.horizontal, 5).padding(.vertical, 1)
                        .background(s.mySide.dimColor).clipShape(Capsule())
                    Text("\(Fmt.cents(s.mySide == .yes ? s.entryProbability : 1 - s.entryProbability))'ten")
                        .font(.mono(10)).foregroundStyle(Palette.faint)
                    Text("·").foregroundStyle(Palette.faint)
                    Text("Sonuç \(s.outcome ? "EVET" : "HAYIR")")
                        .font(.system(size: 10)).foregroundStyle(Palette.muted)
                    Text("·").foregroundStyle(Palette.faint)
                    Text(Fmt.relative(s.date)).font(.system(size: 10))
                        .foregroundStyle(Palette.faint)
                }
            }
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 2) {
                Text(Fmt.signed(s.profit)).font(.mono(13, .bold))
                    .foregroundStyle(s.profit >= 0 ? Palette.yes : Palette.no)
                Text("Brier \(Fmt.decimal(s.brier, decimals: 2))")
                    .font(.mono(9)).foregroundStyle(Palette.faint)
            }
        }
        .card(padding: 13)
    }

    // MARK: İşlem geçmişi

    @ViewBuilder
    private var history: some View {
        if store.trades.isEmpty {
            EmptyState(icon: "list.bullet", title: "İşlem yok", message: "Yaptığın alım satımlar burada listelenir.")
                .card()
        } else {
            ForEach(store.trades) { t in
                HStack(spacing: 10) {
                    Text(t.action == .buy ? "AL" : "SAT")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(t.action == .buy ? Palette.yes : Palette.gold)
                        .frame(width: 30, height: 20)
                        .background((t.action == .buy ? Palette.yes : Palette.gold).opacity(0.13))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(t.marketQuestion).font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Palette.text).lineLimit(2)
                        Text("\(t.side.title) · \(Fmt.puan(t.shares)) adet · \(Fmt.cents(t.avgPrice))")
                            .font(.system(size: 10)).foregroundStyle(Palette.faint)
                    }
                    Spacer(minLength: 4)
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(Fmt.signed(-t.puan)).font(.mono(12, .semibold))
                            .foregroundStyle(t.puan <= 0 ? Palette.yes : Palette.text)
                        Text(Fmt.relative(t.date)).font(.system(size: 9))
                            .foregroundStyle(Palette.faint)
                    }
                }
                .card(padding: 12)
            }
        }
    }
}
