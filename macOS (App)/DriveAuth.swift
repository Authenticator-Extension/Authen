import AuthenticationServices
import Cocoa

private let appGroupId = "group.com.rebornix.Authen"
private let driveAuthNotification = Notification.Name("com.rebornix.Authen.driveAuth")
private let driveRedirect = URL(string: "https://authenticator.cc/oauth")!

final class DriveAuth: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = DriveAuth()

    private var session: ASWebAuthenticationSession?

    func startObserving() {
        DistributedNotificationCenter.default().addObserver(
            forName: driveAuthNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.startIfPending()
        }
    }

    func startIfPending() {
        guard session == nil else {
            return
        }
        guard let defaults = UserDefaults(suiteName: appGroupId) else {
            return
        }
        guard defaults.string(forKey: "driveAuthState") == "pending",
            let urlString = defaults.string(forKey: "driveAuthURL"),
            let url = URL(string: urlString),
            url.scheme == "https",
            url.host == "accounts.google.com"
        else {
            return
        }

        let session = ASWebAuthenticationSession(
            url: url,
            callback: .https(host: driveRedirect.host ?? "authenticator.cc", path: driveRedirect.path),
            completionHandler: { [weak self] callbackURL, error in
                self?.finish(callbackURL: callbackURL, error: error)
            }
        )
        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = false
        self.session = session
        if !session.start() {
            finish(callbackURL: nil, error: nil)
        }
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return NSApplication.shared.keyWindow
            ?? NSApplication.shared.windows.first
            ?? ASPresentationAnchor()
    }

    private func finish(callbackURL: URL?, error: Error?) {
        let defaults = UserDefaults(suiteName: appGroupId)
        if let callbackURL = callbackURL,
            callbackURL.scheme == "https",
            callbackURL.host == driveRedirect.host,
            callbackURL.path == driveRedirect.path
        {
            defaults?.set(callbackURL.absoluteString, forKey: "driveAuthCallback")
            defaults?.set("done", forKey: "driveAuthState")
        } else {
            let cancelled = (error as NSError?)?.code == ASWebAuthenticationSessionError.canceledLogin.rawValue
            defaults?.set(cancelled ? "cancelled" : "failed", forKey: "driveAuthError")
            defaults?.set("error", forKey: "driveAuthState")
        }
        defaults?.removeObject(forKey: "driveAuthURL")
        defaults?.synchronize()
        session = nil
    }
}
