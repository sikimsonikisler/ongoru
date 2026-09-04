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
                        .tabItem { Label("Piyasalar", systemImage: "chart.bar.doc.horizontal") }
                        .tag(0)
                    IndexView()
                        .tabItem { Label("Endeks", systemImage: "waveform.path.ecg") }
                        .tag(1)
                    PortfolioView()
                        .tabItem { Label("Portföy", systemImage: "briefcase") }
                        .tag(2)
                    LeagueView()
                        .tabItem { Label("Lig", systemImage: "trophy") }
                        .tag(3)
                    ProfileView()
                        .tabItem { Label("Sicil", systemImage: "person.crop.circle") }
                        .tag(4)
                }
                .transition(.opacity)
            } else {
                OnboardingView()
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
        .animation(.easeInOut(duration: 0.28), value: store.state.onboarded)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: store.toast)
        .onAppear { store.start() }
        .onChange(of: store.toast) { _, new in
            guard new != nil else { return }
            Task {
                try? await Task.sleep(nanoseconds: 2_200_000_000)
                if store.toast == new { store.toast = nil }
            }
        }
    }
}
