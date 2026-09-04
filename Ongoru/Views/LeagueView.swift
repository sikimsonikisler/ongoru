import SwiftUI

struct LeagueView: View {
    @EnvironmentObject var store: AppStore
    @State private var kind: AppStore.LeagueKind = .points

    private var ranks: [AppStore.Rank] { store.league(kind) }
    private var mine: AppStore.Rank? { ranks.first { $0.isMe } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    Picker("", selection: $kind) {
                        Text(L("Puan ligi", "Points league")).tag(AppStore.LeagueKind.points)
                        Text(L("İsabet ligi", "Accuracy league")).tag(AppStore.LeagueKind.score)
                    }
                    .pickerStyle(.segmented)

                    explainer
                    podium
                    ForEach(ranks.dropFirst(3)) { r in row(r) }
                    Color.clear.frame(height: 20)
                }
                .padding(.horizontal, 14)
                .padding(.top, 4)
            }
            .background(Palette.bg)
            .navigationTitle(L("Türkiye Tahmin Ligi", "Türkiye Forecast League"))
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) { myRankBar }
        }
    }

    private var explainer: some View {
        HStack(spacing: 9) {
            Image(systemName: kind == .points ? "circle.hexagongrid.fill" : "target")
                .font(.system(size: 12)).foregroundStyle(Palette.gold)
            Text(kind == .points
                 ? L("Sezon puanı: nakit + açık pozisyonların güncel değeri. Sezon başında herkes 10.000 puanla başlar.",
                     "Season points: cash plus the current value of open positions. Everyone starts each season with 10,000.")
                 : L("Öngörü Skoru: verdiğin olasılıkların ne kadar kalibre olduğunu ölçer. 50 = yazı tura, 100 = kusursuz.",
                     "Forecast Score measures how well calibrated your probabilities are. 50 = coin flip, 100 = perfect."))
                .font(.system(size: 11))
                .foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .card(padding: 12)
    }

    private var podium: some View {
        HStack(alignment: .bottom, spacing: 9) {
            if ranks.count >= 3 {
                podiumCard(ranks[1], height: 108)
                podiumCard(ranks[0], height: 128)
                podiumCard(ranks[2], height: 96)
            }
        }
    }

    private func podiumCard(_ r: AppStore.Rank, height: CGFloat) -> some View {
        let medal = ["🥇", "🥈", "🥉"][min(r.position - 1, 2)]
        return VStack(spacing: 7) {
            Text(medal).font(.system(size: r.position == 1 ? 26 : 21))
            Avatar(initials: initials(r.name), seed: r.name.hashValue, size: r.position == 1 ? 42 : 34)
            Text(r.name).font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Palette.text).lineLimit(1).minimumScaleFactor(0.7)
            Text(kind == .points ? Fmt.puan(r.points) : "\(r.score)")
                .font(.mono(r.position == 1 ? 15 : 13, .bold))
                .foregroundStyle(r.position == 1 ? Palette.gold : Palette.text)
            if kind == .score {
                Text(L("\(Fmt.pctInt(Int(r.accuracy * 100))) isabet",
                       "\(Fmt.pctInt(Int(r.accuracy * 100))) accurate")).font(.system(size: 9))
                    .foregroundStyle(Palette.faint)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .padding(.vertical, 10)
        .background(r.isMe ? Palette.accent.opacity(0.10) : Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous)
            .strokeBorder(r.isMe ? Palette.accent.opacity(0.5)
                          : (r.position == 1 ? Palette.gold.opacity(0.35) : Palette.stroke), lineWidth: 1))
    }

    private func row(_ r: AppStore.Rank) -> some View {
        HStack(spacing: 11) {
            Text("\(r.position)")
                .font(.mono(13, .bold))
                .foregroundStyle(r.isMe ? Palette.accent : Palette.faint)
                .frame(width: 24, alignment: .trailing)
            Avatar(initials: initials(r.name), seed: r.name.hashValue, size: 32)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(r.name).font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Palette.text)
                    if r.isMe {
                        Text(L("sen", "you")).font(.system(size: 8, weight: .bold))
                            .foregroundStyle(Palette.bg)
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(Palette.accent).clipShape(Capsule())
                    }
                    if r.streak >= 3 {
                        HStack(spacing: 1) {
                            Image(systemName: "flame.fill").font(.system(size: 7))
                            Text("\(r.streak)").font(.mono(8, .bold))
                        }
                        .foregroundStyle(Palette.gold)
                    }
                }
                Text(subtitle(r)).font(.system(size: 10)).foregroundStyle(Palette.faint)
            }
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 1) {
                Text(kind == .points ? Fmt.puan(r.points) : "\(r.score)")
                    .font(.mono(14, .bold))
                    .foregroundStyle(kind == .score && r.score >= 70 ? Palette.yes : Palette.text)
                Text(kind == .points ? L("puan", "pts") : L("skor", "score")).font(.system(size: 9))
                    .foregroundStyle(Palette.faint)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(r.isMe ? Palette.accent.opacity(0.08) : Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous)
            .strokeBorder(r.isMe ? Palette.accent.opacity(0.45) : Palette.stroke.opacity(0.7), lineWidth: 0.8))
    }

    private func subtitle(_ r: AppStore.Rank) -> String {
        if r.resolved == 0 {
            return L("@\(r.handle) · henüz sicil yok", "@\(r.handle) · no record yet")
        }
        let base = L("\(r.resolved) tahmin · \(Fmt.pctInt(Int(r.accuracy * 100))) isabet",
                     "\(r.resolved) predictions · \(Fmt.pctInt(Int(r.accuracy * 100))) accurate")
        if let t = r.title { return base + " · " + t }
        return base
    }

    private var myRankBar: some View {
        Group {
            if let mine, mine.position > 3 {
                HStack(spacing: 11) {
                    Text("\(mine.position).").font(.mono(14, .bold)).foregroundStyle(Palette.accent)
                    Avatar(initials: initials(mine.name), seed: mine.name.hashValue, size: 28)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(L("Senin sıran", "Your rank")).font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Palette.text)
                        Text(L("\(ranks.count) katılımcı arasında", "among \(ranks.count) traders"))
                            .font(.system(size: 9)).foregroundStyle(Palette.faint)
                    }
                    Spacer()
                    Text(kind == .points ? Fmt.puan(mine.points) : "\(mine.score)")
                        .font(.mono(15, .bold)).foregroundStyle(Palette.text)
                }
                .padding(.horizontal, 14).padding(.vertical, 11)
                .background(.ultraThinMaterial)
                .overlay(Divider().overlay(Palette.stroke), alignment: .top)
            }
        }
    }

    private func initials(_ name: String) -> String {
        let parts = name.split(separator: " ")
        let a = parts.first?.first.map(String.init) ?? "?"
        let b = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (a + b).uppercased()
    }
}
