import SwiftUI

@main
struct OngoruApp: App {
    @StateObject private var store = AppStore()
    @Environment(\.scenePhase) private var phase

    init() { Appearance.apply() }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .tint(Palette.accent)
                .environment(\.locale, Locale(identifier: "tr_TR"))
        }
        .onChange(of: phase) { _, new in
            switch new {
            case .active:     store.start()
            case .background: store.stop()
            default:          break
            }
        }
    }
}

enum Appearance {
    static func apply() {
        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = UIColor(Palette.bg)
        tab.shadowColor = UIColor(Palette.stroke)
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab

        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = UIColor(Palette.bg)
        nav.shadowColor = .clear
        nav.titleTextAttributes = [.foregroundColor: UIColor(Palette.text)]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor(Palette.text)]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
    }
}
