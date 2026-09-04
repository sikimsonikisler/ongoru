import UIKit

/// Dokunsal geri bildirim. Tahmin borsalarında işlem onayı ve fiyat
/// etkileşimleri dokunmatik teyit ister; sessiz kalan buton "oldu mu?"
/// sorusunu doğurur.
enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func select() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
