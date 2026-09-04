import SwiftUI

struct ThesisComposerView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let marketId: String
    @State private var side: Side = .yes
    @State private var text = ""
    @State private var sources: [EvidenceSource] = []
    @State private var newSource = ""

    private var market: Market? { store.market(id: marketId) }
    private var canPost: Bool { text.trimmingCharacters(in: .whitespaces).count >= 15 }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let market {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            CategoryBadge(category: market.category)
                            Text(market.question)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Palette.text)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        HStack(spacing: 8) {
                            ForEach(Side.allCases, id: \.self) { s in
                                Button { withAnimation(.easeOut(duration: 0.18)) { side = s } } label: {
                                    Text("\(s.title) · \(Fmt.cents(market.price(for: s)))")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(side == s ? Palette.bg : s.color)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 11)
                                        .background(side == s ? s.color : s.dimColor)
                                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        ThesisEditor(market: market, side: side, text: $text,
                                     sources: $sources, newSource: $newSource)

                        Color.clear.frame(height: 80)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .background(Palette.bg)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Gerekçe yaz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Vazgeç") { dismiss() }.foregroundStyle(Palette.muted)
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Divider().overlay(Palette.stroke)
                    Button {
                        store.postThesis(marketId: marketId, side: side, text: text, sources: sources)
                        dismiss()
                    } label: {
                        Text("Yayımla")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Palette.bg)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(canPost ? Palette.accent : Palette.faint)
                            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canPost)
                    .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 8)
                }
                .background(.ultraThinMaterial)
            }
        }
        .presentationBackground(Palette.bg)
    }
}
