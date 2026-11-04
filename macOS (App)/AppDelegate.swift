//
//  AppDelegate.swift
//  macOS (App)
//
//  Created by penlv on 12/31/21.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        DriveAuth.shared.startObserving()
        DispatchQueue.main.async {
            DriveAuth.shared.startIfPending()
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        DriveAuth.shared.startIfPending()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

}
