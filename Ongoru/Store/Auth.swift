import Foundation
import AuthenticationServices
import CryptoKit
import UIKit

// MARK: - Hesap

struct Account: Codable, Hashable, Identifiable {
    enum Provider: String, Codable, Hashable {
        case local, apple, google

        var label: String {
            switch self {
            case .local:  return L("Öngörü hesabı", "Öngörü account")
            case .apple:  return L("Apple ile", "with Apple")
            case .google: return L("Google ile", "with Google")
            }
        }

        var icon: String {
            switch self {
            case .local:  return "person.crop.circle"
            case .apple:  return "apple.logo"
            case .google: return "g.circle.fill"
            }
        }
    }

    var id: String
    var provider: Provider
    var displayName: String
    var email: String?
    var createdAt: Date

    /// Sağlayıcıdan gelen kimlik; ileride sunucu tarafında eşleştirme anahtarı.
    var providerUserId: String?
}

// MARK: - Hatalar

enum AuthError: LocalizedError, Equatable {
    case cancelled
    case appleUnavailable(String)
    case googleNotConfigured
    case network(String)
    case badResponse

    var errorDescription: String? {
        switch self {
        case .cancelled:
            return L("Giriş iptal edildi.", "Sign-in cancelled.")
        case .appleUnavailable(let detail):
            return L("Apple ile giriş bu derlemede kullanılamıyor. \(detail)",
                     "Sign in with Apple isn't available in this build. \(detail)")
        case .googleNotConfigured:
            return L("Google ile giriş için önce bir OAuth istemci kimliği tanımlanmalı.",
                     "Sign in with Google needs an OAuth client ID first.")
        case .network(let m):
            return L("Bağlantı hatası: \(m)", "Network error: \(m)")
        case .badResponse:
            return L("Sağlayıcıdan beklenmeyen yanıt geldi.", "Unexpected response from the provider.")
        }
    }
}

// MARK: - Google yapılandırması

/// Google ile giriş SDK'sız çalışır: OAuth 2.0 Authorization Code + PKCE akışı
/// `ASWebAuthenticationSession` üzerinden yürütülür. Canlıya almak için tek
/// gereken, Google Cloud Console'da bir **iOS OAuth istemcisi** oluşturup
/// aşağıdaki `clientID`'yi doldurmak. Bundle kimliği: `com.ongoru.tahmin`.
///
/// Yönlendirme adresi ters çevrilmiş istemci kimliğidir; ayrıca Info.plist'e
/// URL şeması eklemek gerekmez — oturumu `ASWebAuthenticationSession` yakalar.
enum GoogleConfig {
    /// Örn. "123456789-abc123.apps.googleusercontent.com"
    static let clientID = ""

    static var isConfigured: Bool { !clientID.isEmpty }

    static var reversedClientID: String {
        clientID.split(separator: ".").reversed().joined(separator: ".")
    }

    static var redirectURI: String { "\(reversedClientID):/oauth2redirect" }

    static let scope = "openid email profile"
    static let authEndpoint = "https://accounts.google.com/o/oauth2/v2/auth"
    static let tokenEndpoint = "https://oauth2.googleapis.com/token"
}

// MARK: - Servis

@MainActor
final class AuthService: NSObject, ObservableObject {

    // MARK: Apple

    /// SwiftUI'ın `SignInWithAppleButton`'ından gelen sonucu hesaba çevirir.
    func account(from authorization: ASAuthorization) throws -> Account {
        guard let cred = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AuthError.badResponse
        }
        // Ad yalnızca ilk girişte gelir; sonrasında saklanan ad kullanılmalı.
        let full = [cred.fullName?.givenName, cred.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)

        return Account(
            id: "apple:" + cred.user,
            provider: .apple,
            displayName: full.isEmpty ? L("Apple kullanıcısı", "Apple user") : full,
            email: cred.email,
            createdAt: Date(),
            providerUserId: cred.user)
    }

    /// Apple'ın hata kodlarını kullanıcıya anlamlı cümleye çevirir.
    func describe(_ error: Error) -> AuthError {
        let ns = error as NSError
        if ns.domain == ASAuthorizationError.errorDomain {
            switch ASAuthorizationError.Code(rawValue: ns.code) {
            case .canceled:
                return .cancelled
            case .unknown, .invalidResponse, .notHandled, .failed:
                return .appleUnavailable(
                    L("Xcode'da hedefe “Sign in with Apple” yetkilendirmesi eklenmeli ve bir geliştirici ekibi seçilmeli.",
                      "Add the “Sign in with Apple” capability to the target in Xcode and select a development team."))
            default:
                return .appleUnavailable(ns.localizedDescription)
            }
        }
        return .network(ns.localizedDescription)
    }

    // MARK: Google (PKCE)

    func signInWithGoogle() async throws -> Account {
        guard GoogleConfig.isConfigured else { throw AuthError.googleNotConfigured }

        let verifier = Self.randomURLSafeString(length: 64)
        let challenge = Self.codeChallenge(for: verifier)
        let state = Self.randomURLSafeString(length: 24)

        var comps = URLComponents(string: GoogleConfig.authEndpoint)!
        comps.queryItems = [
            .init(name: "client_id", value: GoogleConfig.clientID),
            .init(name: "redirect_uri", value: GoogleConfig.redirectURI),
            .init(name: "response_type", value: "code"),
            .init(name: "scope", value: GoogleConfig.scope),
            .init(name: "code_challenge", value: challenge),
            .init(name: "code_challenge_method", value: "S256"),
            .init(name: "state", value: state)
        ]

        let callback = try await webAuth(url: comps.url!,
                                         scheme: GoogleConfig.reversedClientID)

        let items = URLComponents(url: callback, resolvingAgainstBaseURL: false)?.queryItems ?? []
        guard items.first(where: { $0.name == "state" })?.value == state else {
            throw AuthError.badResponse
        }
        guard let code = items.first(where: { $0.name == "code" })?.value else {
            throw AuthError.cancelled
        }
        return try await exchange(code: code, verifier: verifier)
    }

    private func webAuth(url: URL, scheme: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: scheme) { url, error in
                if let url {
                    continuation.resume(returning: url)
                } else if let error = error as? ASWebAuthenticationSessionError,
                          error.code == .canceledLogin {
                    continuation.resume(throwing: AuthError.cancelled)
                } else {
                    continuation.resume(throwing: AuthError.network(
                        error?.localizedDescription ?? "unknown"))
                }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }
    }

    private func exchange(code: String, verifier: String) async throws -> Account {
        var request = URLRequest(url: URL(string: GoogleConfig.tokenEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var body = URLComponents()
        body.queryItems = [
            .init(name: "client_id", value: GoogleConfig.clientID),
            .init(name: "code", value: code),
            .init(name: "code_verifier", value: verifier),
            .init(name: "grant_type", value: "authorization_code"),
            .init(name: "redirect_uri", value: GoogleConfig.redirectURI)
        ]
        request.httpBody = body.query?.data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: request)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let idToken = json["id_token"] as? String,
              let claims = Self.decodeJWT(idToken) else {
            throw AuthError.badResponse
        }
        let sub = claims["sub"] as? String ?? UUID().uuidString
        return Account(
            id: "google:" + sub,
            provider: .google,
            displayName: (claims["name"] as? String)
                ?? (claims["email"] as? String)
                ?? L("Google kullanıcısı", "Google user"),
            email: claims["email"] as? String,
            createdAt: Date(),
            providerUserId: sub)
    }

    // MARK: Yerel hesap
    //
    // Parola tutulmaz. Sunucu olmadan parolayı cihazda saklamak, güvenlik
    // hissi veren ama korumayan bir şey olurdu; hesap kimliği cihazda üretilir
    // ve ilerleme cihazda saklanır. Cihazlar arası taşıma için sunucu şart.

    func localAccount(name: String) -> Account {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return Account(
            id: "local:" + UUID().uuidString,
            provider: .local,
            displayName: trimmed.isEmpty ? L("Misafir", "Guest") : trimmed,
            email: nil,
            createdAt: Date(),
            providerUserId: nil)
    }

    // MARK: PKCE yardımcıları

    private static func randomURLSafeString(length: Int) -> String {
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
        return String((0..<length).map { _ in chars.randomElement()! })
    }

    private static func codeChallenge(for verifier: String) -> String {
        let digest = SHA256.hash(data: Data(verifier.utf8))
        return Data(digest).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private static func decodeJWT(_ token: String) -> [String: Any]? {
        let parts = token.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        var payload = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while payload.count % 4 != 0 { payload.append("=") }
        guard let data = Data(base64Encoded: payload) else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
}

extension AuthService: ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first { $0.isKeyWindow } ?? ASPresentationAnchor()
        }
    }
}
