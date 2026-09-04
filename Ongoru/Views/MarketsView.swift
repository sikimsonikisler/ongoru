import SwiftUI

struct MarketsView: View {
    @EnvironmentObject var store: AppStore
    @State private var query: String = ""
    @State private var category: Category? = nil
    @State private var sort: SortKind = .hacim
    @State private var onlyWatched = false
    @State private var showResolved = false
    @State private var path: [String] = []

    enum SortKind: String, CaseIterable, Identifiable {
        case hacim = "Hacim"
        case hareket = "Hareket"
        case kapanis = "Kapanışa yakın"
        case yeni = "Yeni"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(spacing: 12, pinnedViews: []) {
                    BalanceHeader()
                    filterBar
                    if filtered.isEmpty {
                        EmptyState(icon: showResolved ? "checkmark.circle" : "magnifyingglass",
                                   title: showResolved ? "Henüz sonuçlanan piyasa yok" : "Sonuç yok",
                                   message: showResolved
                                     ? "Bir piyasa kapanınca sonucu burada arşivlenir. Sicil > Ayarlar > Demo araçları'ndan hemen bir tane sonuçlandırabilirsin."
                                     : "Aramanı veya kategori filtresini değiştirmeyi dene.")
                    } else {
                        ForEach(filtered) { m in
                            Button { path.append(m.id) } label: { MarketCard(market: m) }
                                .buttonStyle(.plain)
                        }
                    }
                    Color.clear.frame(height: 20)
                }
                .padding(.horizontal, 14)
                .padding(.top, 4)
            }
            .background(Palette.bg)
            .navigationTitle("Piyasalar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { sortMenu }
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Soru veya konu ara")
            .navigationDestination(for: String.self) { id in
                MarketDetailView(marketId: id)
            }
        }
    }

    private var sortMenu: some View {
        Menu {
            Picker("Sırala", selection: $sort) {
                ForEach(SortKind.allCases) { Text($0.rawValue).tag($0) }
            }
            Divider()
            Toggle("Sadece takip ettiklerim", isOn: $onlyWatched)
            Toggle("Sonuçlananları göster", isOn: $showResolved)
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 16, weight: .semibold))
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                chip(title: "Tümü", icon: "square.grid.2x2", tint: Palette.muted,
                     selected: category == nil) { category = nil }
                ForEach(Category.allCases) { c in
                    chip(title: c.title, icon: c.icon, tint: c.tint, selected: category == c) {
                        category = (category == c) ? nil : c
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .scrollClipDisabled()
    }

    private func chip(title: String, icon: String, tint: Color, selected: Bool,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 10, weight: .semibold))
                Text(title).font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(selected ? Palette.bg : tint)
            .padding(.horizontal, 11).padding(.vertical, 7)
            .background(selected ? tint : tint.opacity(0.12))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var filtered: [Market] {
        var list = showResolved
            ? store.markets.filter { $0.status == .resolved }
            : store.markets.filter { $0.status != .resolved }
        if let category { list = list.filter { $0.category == category } }
        if onlyWatched { list = list.filter { store.isWatched($0.id) } }
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty {
            list = list.filter {
                $0.question.lowercased().contains(q) ||
                $0.detail.lowercased().contains(q) ||
                $0.category.title.lowercased().contains(q)
            }
        }
        switch sort {
        case .hacim:   list.sort { $0.volume > $1.volume }
        case .hareket: list.sort { abs($0.change24h) > abs($1.change24h) }
        case .kapanis: list.sort { $0.closeDate < $1.closeDate }
        case .yeni:    list.sort { $0.createdAt > $1.createdAt }
        }
        return list
    }
}

// MARK: - Bakiye başlığı

struct BalanceHeader: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Palette.bg)
                    .frame(width: 18, height: 18)
                    .background(Palette.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                Text("ÖNGÖRÜ").font(.system(size: 10, weight: .black)).kerning(1.8)
                    .foregroundStyle(Palette.muted)
                Spacer()
                Text("Türkiye Tahmin Ligi · sezon 1")
                    .font(.system(size: 9)).foregroundStyle(Palette.faint)
            }
            HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("SEZON PUANIN").font(.system(size: 9, weight: .bold)).kerning(0.7)
                    .foregroundStyle(Palette.faint)
                Text(Fmt.puan(store.totalPoints))
                    .font(.mono(25, .bold))
                    .foregroundStyle(Palette.text)
                    .contentTransition(.numericText())
                HStack(spacing: 6) {
                    Text("Nakit \(Fmt.puan(store.state.me.cash))")
                        .font(.system(size: 10)).foregroundStyle(Palette.muted)
                    if !store.positions.isEmpty {
                        Text("·").foregroundStyle(Palette.faint)
                        HStack(spacing: 2) {
                            Image(systemName: store.openPnL >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 7, weight: .bold))
                            Text(Fmt.signed(store.openPnL))
                                .font(.mono(10, .semibold))
                        }
                        .foregroundStyle(store.openPnL >= 0 ? Palette.yes : Palette.no)
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 5) {
                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill").font(.system(size: 9))
                    Text("\(store.myRank).").font(.mono(13, .bold))
                }
                .foregroundStyle(Palette.gold)
                HStack(spacing: 4) {
                    Text("Skor").font(.system(size: 10)).foregroundStyle(Palette.muted)
                    Text("\(store.scoreCard.score)")
                        .font(.mono(13, .bold))
                        .foregroundStyle(store.scoreCard.score >= 60 ? Palette.yes : Palette.text)
                }
            }
            }
        }
        .card(padding: 15)
    }
}

// MARK: - Piyasa kartı

struct MarketCard: View {
    @EnvironmentObject var store: AppStore
    var market: Market

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 7) {
                CategoryBadge(category: market.category)
                Spacer()
                if store.isWatched(market.id) {
                    Image(systemName: "bookmark.fill").font(.system(size: 9))
                        .foregroundStyle(Palette.gold)
                }
                if market.status == .resolved, let outcome = market.resolvedOutcome {
                    Text("SONUÇ: \(outcome ? "EVET" : "HAYIR")")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(outcome ? Palette.yes : Palette.no)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background((outcome ? Palette.yes : Palette.no).opacity(0.14))
                        .clipShape(Capsule())
                } else {
                    Image(systemName: "clock").font(.system(size: 9)).foregroundStyle(Palette.faint)
                    Text(Fmt.kalan(market.closeDate))
                        .font(.system(size: 10, weight: .medium)).foregroundStyle(Palette.faint)
                }
            }

            Text(market.question)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Palette.text)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text("\(market.centsYes)¢")
                            .font(.mono(23, .bold))
                            .foregroundStyle(Palette.text)
                            .contentTransition(.numericText())
                        if market.status != .resolved {
                            ChangeTag(value: market.change24h)
                        }
                    }
                    Text(market.status == .resolved
                         ? "kapanış fiyatı"
                         : "EVET olasılığı %\(market.centsYes)")
                        .font(.system(size: 10)).foregroundStyle(Palette.faint)
                }
                Spacer()
                Sparkline(points: Array(market.history.suffix(48)),
                          color: market.change24h >= 0 ? Palette.yes : Palette.no)
                    .frame(width: 92, height: 34)
            }

            if market.status != .resolved {
                YesNoButtons(market: market, compact: true)
            }

            HStack(spacing: 10) {
                footerItem("arrow.left.arrow.right", Fmt.compact(market.volume) + " işlem")
                footerItem("person.2", Fmt.compact(market.participants) + " katılımcı")
                Spacer()
                if let pos = store.position(for: market.id), let side = pos.netSide {
                    HStack(spacing: 3) {
                        Circle().fill(side.color).frame(width: 5, height: 5)
                        Text("Pozisyonun var").font(.system(size: 10, weight: .medium))
                            .foregroundStyle(side.color)
                    }
                }
            }
        }
        .card()
    }

    private func footerItem(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 8))
            Text(text).font(.system(size: 10))
        }
        .foregroundStyle(Palette.faint)
    }
}
