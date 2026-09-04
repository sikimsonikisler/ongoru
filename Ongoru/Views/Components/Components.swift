import SwiftUI
import Charts

// MARK: - Kart yüzeyi

struct CardBackground: ViewModifier {
    var padding: CGFloat = 14
    var radius: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Palette.stroke.opacity(0.7), lineWidth: 0.7)
            )
    }
}

extension View {
    func card(padding: CGFloat = 14, radius: CGFloat = 16) -> some View {
        modifier(CardBackground(padding: padding, radius: radius))
    }
}

// MARK: - Sparkline

struct Sparkline: View {
    var points: [PricePoint]
    var color: Color
    var lineWidth: CGFloat = 1.6
    var filled: Bool = true

    private func geometry(_ size: CGSize) -> (line: Path, area: Path) {
        let values = points.map(\.p)
        guard values.count > 1 else { return (Path(), Path()) }
        let lo = (values.min() ?? 0) - 0.02
        let hi = (values.max() ?? 1) + 0.02
        let range = max(hi - lo, 0.04)

        func point(_ i: Int, _ v: Double) -> CGPoint {
            CGPoint(x: size.width * CGFloat(i) / CGFloat(values.count - 1),
                    y: size.height * (1 - CGFloat((v - lo) / range)))
        }

        var line = Path()
        for (i, v) in values.enumerated() {
            let pt = point(i, v)
            if i == 0 { line.move(to: pt) } else { line.addLine(to: pt) }
        }
        var area = line
        area.addLine(to: CGPoint(x: size.width, y: size.height))
        area.addLine(to: CGPoint(x: 0, y: size.height))
        area.closeSubpath()
        return (line, area)
    }

    var body: some View {
        GeometryReader { geo in
            let paths = geometry(geo.size)
            ZStack {
                if filled {
                    paths.area.fill(
                        LinearGradient(colors: [color.opacity(0.26), color.opacity(0.0)],
                                       startPoint: .top, endPoint: .bottom))
                }
                paths.line.stroke(color, style: StrokeStyle(lineWidth: lineWidth,
                                                            lineCap: .round, lineJoin: .round))
            }
        }
    }
}

// MARK: - Fiyat grafiği (detay)

struct PriceChart: View {
    var points: [PricePoint]
    var color: Color

    var body: some View {
        Chart {
            ForEach(points) { pt in
                AreaMark(x: .value("Zaman", pt.t), y: .value("Fiyat", pt.p * 100))
                    .foregroundStyle(
                        LinearGradient(colors: [color.opacity(0.30), color.opacity(0.01)],
                                       startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.monotone)
            }
            ForEach(points) { pt in
                LineMark(x: .value("Zaman", pt.t), y: .value("Fiyat", pt.p * 100))
                    .foregroundStyle(color)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                    .interpolationMethod(.monotone)
            }
            if let last = points.last {
                PointMark(x: .value("Zaman", last.t), y: .value("Fiyat", last.p * 100))
                    .foregroundStyle(color)
                    .symbolSize(60)
            }
            RuleMark(y: .value("Yarı", 50))
                .foregroundStyle(Palette.stroke.opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 0.7, dash: [3, 3]))
        }
        .chartYScale(domain: 0...100)
        .chartYAxis {
            AxisMarks(position: .trailing, values: [0, 25, 50, 75, 100]) { v in
                AxisGridLine().foregroundStyle(Palette.stroke.opacity(0.35))
                AxisValueLabel {
                    if let n = v.as(Int.self) { Text("\(n)¢").font(.system(size: 9)).foregroundStyle(Palette.faint) }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine().foregroundStyle(Palette.stroke.opacity(0.2))
                AxisValueLabel(format: .dateTime.day().month(.abbreviated), centered: false)
                    .font(.system(size: 9))
                    .foregroundStyle(Palette.faint)
            }
        }
    }
}

// MARK: - EVET / HAYIR fiyat düğmeleri

struct YesNoButtons: View {
    var market: Market
    var compact: Bool = false
    var onTap: ((Side) -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            button(.yes, cents: market.centsYes)
            button(.no, cents: market.centsNo)
        }
    }

    private func button(_ side: Side, cents: Int) -> some View {
        Button {
            onTap?(side)
        } label: {
            HStack(spacing: 6) {
                Text(side.title)
                    .font(.system(size: compact ? 11 : 12, weight: .bold))
                Spacer(minLength: 2)
                Text("\(cents)¢")
                    .font(.mono(compact ? 13 : 15, .bold))
            }
            .foregroundStyle(side.color)
            .padding(.horizontal, 11)
            .padding(.vertical, compact ? 8 : 11)
            .frame(maxWidth: .infinity)
            .background(side.dimColor)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(side.color.opacity(0.28), lineWidth: 0.8))
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }
}

// MARK: - Olasılık şeridi

struct ProbabilityBar: View {
    var p: Double
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Palette.no.opacity(0.35))
                Capsule().fill(Palette.yes)
                    .frame(width: max(2, geo.size.width * p))
            }
        }
        .frame(height: height)
    }
}

// MARK: - Kategori rozeti

struct CategoryBadge: View {
    var category: Category
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.icon).font(.system(size: 9, weight: .semibold))
            Text(category.title).font(.system(size: 10, weight: .semibold))
        }
        .foregroundStyle(category.tint)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(category.tint.opacity(0.13))
        .clipShape(Capsule())
    }
}

// MARK: - Değişim etiketi

struct ChangeTag: View {
    var value: Double
    var suffix: String = "p"
    var body: some View {
        let up = value >= 0
        HStack(spacing: 2) {
            Image(systemName: up ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 8, weight: .bold))
            Text(Fmt.puan(abs(value), decimals: 1) + suffix)
                .font(.mono(11, .semibold))
        }
        .foregroundStyle(up ? Palette.yes : Palette.no)
    }
}

// MARK: - Skor halkası

struct ScoreRing: View {
    var score: Int
    var size: CGFloat = 116
    var label: String

    private var color: Color {
        switch score {
        case 70...: return Palette.yes
        case 55..<70: return Palette.gold
        case 45..<55: return Palette.muted
        default: return Palette.no
        }
    }

    var body: some View {
        ZStack {
            Circle().stroke(Palette.stroke, lineWidth: 9)
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(color, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.6), value: score)
            VStack(spacing: 0) {
                Text("\(score)").font(.mono(size * 0.30, .bold)).foregroundStyle(Palette.text)
                Text(label).font(.system(size: size * 0.09, weight: .semibold)).foregroundStyle(Palette.muted)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - İstatistik kutusu

struct StatTile: View {
    var label: String
    var value: String
    var accent: Color = Palette.text
    var sub: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold)).kerning(0.6)
                .foregroundStyle(Palette.faint)
            Text(value).font(.mono(17, .bold)).foregroundStyle(accent)
                .lineLimit(1).minimumScaleFactor(0.55)
            if let sub {
                Text(sub).font(.system(size: 10)).foregroundStyle(Palette.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Avatar

struct Avatar: View {
    var initials: String
    var seed: Int
    var size: CGFloat = 34

    private static let palettes: [[Color]] = [
        [Color(red: 0.20, green: 0.72, blue: 0.55), Color(red: 0.13, green: 0.50, blue: 0.62)],
        [Color(red: 0.62, green: 0.42, blue: 0.92), Color(red: 0.36, green: 0.28, blue: 0.72)],
        [Color(red: 0.95, green: 0.60, blue: 0.28), Color(red: 0.80, green: 0.34, blue: 0.30)],
        [Color(red: 0.30, green: 0.62, blue: 0.95), Color(red: 0.20, green: 0.36, blue: 0.75)],
        [Color(red: 0.92, green: 0.40, blue: 0.60), Color(red: 0.66, green: 0.24, blue: 0.52)],
        [Color(red: 0.42, green: 0.78, blue: 0.82), Color(red: 0.22, green: 0.52, blue: 0.62)],
    ]

    var body: some View {
        let colors = Avatar.palettes[abs(seed) % Avatar.palettes.count]
        Circle()
            .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: size, height: size)
            .overlay(
                Text(initials)
                    .font(.system(size: size * 0.38, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.95))
            )
    }
}

// MARK: - Asistan kartı

struct InsightRow: View {
    var insight: Insight

    private var tint: Color {
        switch insight.tone {
        case .positive: return Palette.yes
        case .negative: return Palette.no
        case .warning:  return Palette.gold
        case .neutral:  return Color(red: 0.45, green: 0.62, blue: 0.95)
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: insight.icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 26, height: 26)
                .background(tint.opacity(0.13))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(insight.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.text)
                    .fixedSize(horizontal: false, vertical: true)
                Text(insight.body)
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Bölüm başlığı

struct SectionHeader: View {
    var title: String
    var sub: String? = nil
    var action: (() -> Void)? = nil
    var actionLabel: String = "Tümü"

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Palette.text)
                if let sub {
                    Text(sub).font(.system(size: 11)).foregroundStyle(Palette.faint)
                }
            }
            Spacer()
            if let action {
                Button(actionLabel, action: action)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Palette.accent)
            }
        }
    }
}

// MARK: - Toast

struct ToastView: View {
    var text: String
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(Palette.text)
            .padding(.horizontal, 16).padding(.vertical, 11)
            .background(Palette.surfaceHigh)
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(Palette.stroke, lineWidth: 0.8))
            .shadow(color: .black.opacity(0.4), radius: 14, y: 6)
    }
}

// MARK: - Boş durum

struct EmptyState: View {
    var icon: String
    var title: String
    var message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(Palette.faint)
            Text(title).font(.system(size: 15, weight: .semibold)).foregroundStyle(Palette.text)
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(Palette.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 30)
    }
}
