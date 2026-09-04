import SwiftUI

struct MarketsView: View {
    @EnvironmentObject var store: AppStore
    @State private var query: String = ""
    @State private var category: Category? = nil
    @State private var sort: SortKind = .hacim
    @State private var scope: Scope = .active
    @State private var path: [String] = []
    @State private var showPropose = false

    enum SortKind: String, CaseIterable, Identifiable {
        case hacim, hareket, kapanis, yeni
        var id: String { rawValue }
        var label: String {
            switch self {
            case .hacim:   return L("Hacim", "Volume")
            case .hareket: return L("Hareket", "Movement")
            case .kapanis: return L("Kapanışa yakın", "Closing soon")
            case .yeni:    return L("Yeni", "Newest")
            }
        }
    }

    enum Scope: String, CaseIterable, Identifiable {
        case active, watchlist, resolved
        var id: String { rawValue }
        var label: String {
            switch self {
            case .active:    return L("Aktif", "Active")
            case .watchlist: return L("Takip listem", "Watchlist")
            case .resolved:  return L("Sonuçlanan", "Resolved")
            }
        }
        var icon: String {
            switch self {
            case .active:    return "bolt"
            case .watchlist: return "bookmark"
            case .resolved:  return "checkmark.seal"
            }
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(spacing: 12) {
                    BalanceHeader()
                    scopeBar
                    filterBar
                    if filtered.isEmpty {
                        emptyState
                    } else {
                        ForEach(filtered) { m in
                            Button {
                                Haptics.tap()
                                path.append(m.id)
                            } label: { MarketCard(market: m) }
                                .buttonStyle(.plain)
                        }
                    }
                    proposeButton
                    Color.clear.frame(height: 20)
                }
                .padding(.horizontal, 14)
                .padding(.top, 4)
            }
            .refreshable {
                store.refreshNow()
                Haptics.tap()
            }
            .background(Palette.bg)
            .navigationTitle(L("Piyasalar", "Markets"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { LanguageMenu() }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        showPropose = true
                    } label: {
                        Image(systemName: "plus").font(.system(size: 15, weight: .semibold))
                    }
                    .accessibilityLabel(L("Piyasa öner", "Propose a market"))
                }
                ToolbarItem(placement: .topBarTrailing) { sortMenu }
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always),
                        prompt: L("Soru veya konu ara", "Search a question or topic"))
            .navigationDestination(for: String.self) { id in
                MarketDetailView(marketId: id)
            }
            .sheet(isPresented: $showPropose) {
                ProposeMarketView().environmentObject(store)
            }
        }
    }

    private var emptyState: some View {
        EmptyState(
            icon: scope == .resolved ? "checkmark.circle"
                : (scope == .watchlist ? "bookmark" : "magnifyingglass"),
            title: scope == .resolved
                ? L("Henüz sonuçlanan piyasa yok", "No resolved markets yet")
                : (scope == .watchlist
                   ? L("Takip listen boş", "Your watchlist is empty")
                   : L("Sonuç yok", "No results")),
            message: scope == .resolved
                ? L("Bir piyasa kapanınca sonucu burada arşivlenir. Sicil › Ayarlar › Demo araçları'ndan hemen bir tane sonuçlandırabilirsin.",
                    "Once a market closes its result is archived here. You can resolve one right away from Record › Settings › Demo tools.")
                : (scope == .watchlist
                   ? L("Bir piyasanın sağ üstündeki yer imi simgesine dokunarak takibe al.",
                       "Tap the bookmark icon at the top right of any market to follow it.")
                   : L("Aramanı veya kategori filtresini değiştirmeyi dene.",
                       "Try changing your search or category filter.")))
    }

    private var scopeBar: some View {
        HStack(spacing: 7) {
            ForEach(Scope.allCases) { s in
                Button {
                    Haptics.select()
                    scope = s
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: s.icon).font(.system(size: 10, weight: .semibold))
                        Text(s.label).font(.system(size: 12, weight: .semibold))
                            .lineLimit(1).minimumScaleFactor(0.8)
                        if s == .watchlist, !store.watchlist.isEmpty {
                            Text("\(store.watchlist.count)")
                                .font(.mono(10, .bold))
                                .foregroundStyle(scope == s ? Palette.bg.opacity(0.7) : Palette.faint)
                        }
                    }
                    .foregroundStyle(scope == s ? Palette.bg : Palette.muted)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(scope == s ? Palette.accent : Palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(scope == s ? .clear : Palette.stroke, lineWidth: 0.8))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(scope == s ? [.isSelected] : [])
            }
        }
    }

    private var sortMenu: some View {
        Menu {
            Picker(L("Sırala", "Sort"), selection: $sort) {
                ForEach(SortKind.allCases) { Text($0.label).tag($0) }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 14, weight: .semibold))
        }
        .accessibilityLabel(L("Sırala", "Sort"))
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                chip(title: L("Tümü", "All"), icon: "square.grid.2x2", tint: Palette.muted,
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
        Button {
            Haptics.select()
            action()
        } label: {
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
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    private var proposeButton: some View {
        Button {
            Haptics.tap()
            showPropose = true
        } label: {
            HStack(spacing: 9) {
                Image(systemName: "plus.circle").font(.system(size: 14, weight: .semibold))
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("Piyasa öner", "Propose a market"))
                        .font(.system(size: 13, weight: .semibold))
                    Text(L("Sorun kurallardan geçerse anında yayına girer",
                           "If your question passes the rules it goes live instantly"))
                        .font(.system(size: 11)).foregroundStyle(Palette.faint)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(Palette.accent)
            .padding(.horizontal, 14).padding(.vertical, 13)
            .background(Palette.accent.opacity(0.09))
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder(Palette.accent.opacity(0.25), lineWidth: 0.8))
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }

    private var filtered: [Market] {
        var list: [Market]
        switch scope {
        case .active:    list = store.markets.filter { $0.status != .resolved }
        case .resolved:  list = store.markets.filter { $0.status == .resolved }
        case .watchlist: list = store.markets.filter { store.isWatched($0.id) }
        }
        if let category { list = list.filter { $0.category == category } }

        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty {
            list = list.filter {
                $0.question.searchable.contains(q) ||
                $0.detail.searchable.contains(q) ||
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
                Text(L("Türkiye Tahmin Ligi · sezon 1", "Türkiye Forecast League · season 1"))
                    .font(.system(size: 9)).foregroundStyle(Palette.faint)
            }
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(L("SEZON PUANIN", "SEASON POINTS"))
                        .font(.system(size: 9, weight: .bold)).kerning(0.7)
                        .foregroundStyle(Palette.faint)
                    Text(Fmt.puan(store.totalPoints))
                        .font(.mono(25, .bold))
                        .foregroundStyle(Palette.text)
                        .contentTransition(.numericText())
                    HStack(spacing: 6) {
                        Text(L("Nakit \(Fmt.puan(store.state.me.cash))",
                               "Cash \(Fmt.puan(store.state.me.cash))"))
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
                        Text(L("Skor", "Score")).font(.system(size: 10)).foregroundStyle(Palette.muted)
                        Text("\(store.scoreCard.score)")
                            .font(.mono(13, .bold))
                            .foregroundStyle(store.scoreCard.score >= 60 ? Palette.yes : Palette.text)
                    }
                }
            }
        }
        .card(padding: 15)
        .accessibilityElement(children: .combine)
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
                if market.origin == .community {
                    Text(L("topluluk", "community"))
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Palette.gold)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Palette.gold.opacity(0.13))
                        .clipShape(Capsule())
                }
                Spacer()
                if store.isWatched(market.id) {
                    Image(systemName: "bookmark.fill").font(.system(size: 9))
                        .foregroundStyle(Palette.gold)
                }
                if market.status == .resolved, let outcome = market.resolvedOutcome {
                    Text(L("SONUÇ: ", "RESULT: ") + (outcome ? L("EVET", "YES") : L("HAYIR", "NO")))
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

            Text(market.question.s)
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
                         ? L("kapanış fiyatı", "closing price")
                         : L("EVET olasılığı \(Fmt.pctInt(market.centsYes))",
                             "YES probability \(Fmt.pctInt(market.centsYes))"))
                        .font(.system(size: 10)).foregroundStyle(Palette.faint)
                }
                Spacer()
                Sparkline(points: market.recentSlice(),
                          color: market.sliceTrend() >= 0 ? Palette.yes : Palette.no)
                    .frame(width: 92, height: 34)
                    .accessibilityHidden(true)
            }

            if market.status != .resolved {
                YesNoButtons(market: market, compact: true)
            }

            HStack(spacing: 10) {
                footerItem("arrow.left.arrow.right",
                           Fmt.compact(market.volume) + L(" işlem", " trades"))
                footerItem("person.2",
                           Fmt.compact(market.participants) + L(" katılımcı", " traders"))
                Spacer()
                if let pos = store.position(for: market.id), let side = pos.netSide {
                    HStack(spacing: 3) {
                        Image(systemName: side.glyph).font(.system(size: 7, weight: .bold))
                        Text(L("Pozisyonun var", "You hold a position"))
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(side.color)
                }
            }
        }
        .card()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(market.question.s + ". " +
            L("EVET \(market.centsYes) kuruş", "YES \(market.centsYes) cents")))
    }

    private func footerItem(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 8))
            Text(text).font(.system(size: 10))
        }
        .foregroundStyle(Palette.faint)
    }
}
