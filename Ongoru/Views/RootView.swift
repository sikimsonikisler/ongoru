import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: AppStore
    @State private var tab: Int = 0

    var body: some View {
        ZStack {
            Palette.bg.ignoresSafeArea()

            if store.state.onboarded {
                TabView(selection: $tab) {
                    MarketsView()
                        .tabItem { Label(L("Piyasalar", "Markets"), systemImage: "chart.bar.doc.horizontal") }
                        .tag(0)
                    IndexView()
                        .tabItem { Label(L("Endeks", "Index"), systemImage: "waveform.path.ecg") }
                        .tag(1)
                    PortfolioView()
                        .tabItem { Label(L("Portföy", "Portfolio"), systemImage: "briefcase") }
                        .tag(2)
                    LeagueView()
                        .tabItem { Label(L("Lig", "League"), systemImage: "trophy") }
                        .tag(3)
                    ProfileView()
                        .tabItem { Label(L("Sicil", "Record"), systemImage: "person.crop.circle") }
                        .tag(4)
                }
                .transition(.opacity)
            } else {
                AuthView()
                    .transition(.opacity)
            }

            if let toast = store.toast {
                VStack {
                    Spacer()
                    ToastView(text: toast)
                        .padding(.bottom, 92)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .allowsHitTesting(false)
            }
        }
        // Dil değişince tüm ağaç yeniden kurulsun; `L(...)` gövde
        // değerlendirmesi sırasında okunduğu için bu şart.
        .id(store.language)
        .animation(.easeInOut(duration: 0.28), value: store.state.onboarded)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: store.toast)
        .onAppear { store.start() }
        .onChange(of: store.toast) { _, new in
            guard new != nil else { return }
            Task {
                try? await Task.sleep(nanoseconds: 2_400_000_000)
                if store.toast == new { store.toast = nil }
            }
        }
    }
}

// MARK: - Dil seçici (her yerde kullanılabilir)

struct LanguageMenu: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        Menu {
            Picker("", selection: Binding(
                get: { store.language },
                set: { store.setLanguage($0) }
            )) {
                ForEach(AppLanguage.allCases) { lang in
                    // Seçim işaretini Picker kendisi koyar; ayrıca ikon
                    // eklersek çift tik görünüyor.
                    Text(lang.label).tag(lang)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "globe").font(.system(size: 12, weight: .semibold))
                Text(store.language == .system
                     ? store.language.resolved.rawValue.uppercased()
                     : store.language.rawValue.uppercased())
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(Palette.muted)
        }
        .accessibilityLabel(L("Dil seç", "Choose language"))
    }
}
