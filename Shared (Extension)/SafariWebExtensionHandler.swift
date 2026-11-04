import AppKit
import os.log
import SafariServices

let SFExtensionMessageKey = "message"

private let appGroupId = "group.com.yourCompany.Authenticator"
private let driveAuthNotification = Notification.Name("com.yourCompany.Authenticator.driveAuth")

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        DispatchQueue.main.async {
            self.handle(context)
        }
    }

    private func handle(_ context: NSExtensionContext) {
        let item = context.inputItems.first as? NSExtensionItem
        let message = item?.userInfo?[SFExtensionMessageKey] as? [String: Any]
        os_log(.default, "Received native message")

        guard
            message?["action"] as? String == "drive-auth",
            let urlString = message?["url"] as? String,
            let url = URL(string: urlString),
            url.scheme == "https",
            url.host == "accounts.google.com"
        else {
            complete(context, ["ok": false, "error": "unsupported"])
            return
        }

        guard let defaults = UserDefaults(suiteName: appGroupId) else {
            complete(context, ["ok": false, "error": "failed"])
            return
        }

        defaults.removeObject(forKey: "driveAuthCallback")
        defaults.removeObject(forKey: "driveAuthError")
        defaults.set(urlString, forKey: "driveAuthURL")
        defaults.set("pending", forKey: "driveAuthState")
        defaults.synchronize()

        openContainerApp()
        DistributedNotificationCenter.default().post(name: driveAuthNotification, object: nil)
        poll(context: context, defaults: defaults, deadline: Date().addingTimeInterval(180))
    }

    private func poll(
        context: NSExtensionContext,
        defaults: UserDefaults,
        deadline: Date
    ) {
        let state = defaults.string(forKey: "driveAuthState")
        if state == "done", let callback = defaults.string(forKey: "driveAuthCallback") {
            clear(defaults)
            complete(context, ["ok": true, "url": callback])
            return
        }
        if state == "error" {
            let error = defaults.string(forKey: "driveAuthError") ?? "failed"
            clear(defaults)
            complete(context, ["ok": false, "error": error])
            return
        }
        if Date() > deadline {
            clear(defaults)
            complete(context, ["ok": false, "error": "timeout"])
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.poll(context: context, defaults: defaults, deadline: deadline)
        }
    }

    private func clear(_ defaults: UserDefaults) {
        defaults.removeObject(forKey: "driveAuthCallback")
        defaults.removeObject(forKey: "driveAuthError")
        defaults.removeObject(forKey: "driveAuthURL")
        defaults.set("idle", forKey: "driveAuthState")
        defaults.synchronize()
    }

    private func complete(_ context: NSExtensionContext, _ body: [String: Any]) {
        let response = NSExtensionItem()
        response.userInfo = [SFExtensionMessageKey: body]
        context.completeRequest(returningItems: [response], completionHandler: nil)
    }

    private func openContainerApp() {
        let appURL = Bundle.main.bundleURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.openApplication(at: appURL, configuration: config) { _, error in
            if error != nil {
                os_log(.error, "Could not open Authen")
            }
        }
    }
}
