import Foundation

enum Persistence {
    private static let filename = "ongoru-state.json"

    private static var url: URL? {
        let fm = FileManager.default
        guard let dir = try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                    appropriateFor: nil, create: true) else { return nil }
        return dir.appendingPathComponent(filename)
    }

    static func load() -> AppState? {
        guard let url, let data = try? Data(contentsOf: url) else { return nil }
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return try? dec.decode(AppState.self, from: data)
    }

    static func save(_ state: AppState) {
        guard let url else { return }
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        guard let data = try? enc.encode(state) else { return }
        try? data.write(to: url, options: .atomic)
    }

    static func wipe() {
        guard let url else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
