//
//  acb_boo_readerApp.swift
//  acb.boo reader
//
//  Created by Aidan Cornelius-Bell on 10/9/2024.
//

import SwiftUI
import UIKit
import Combine

@main
struct acb_boo_readerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appSettings = AppSettings()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appSettings)
        }
    }
}

extension Notification.Name {
    static let bookmarkAdded = Notification.Name("bookmarkAdded")
}

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    let sharedDefaults = UserDefaults(suiteName: "group.com.aidancorneliusbell.acbbooreader")
    
    private var cancellables = Set<AnyCancellable>()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        NSLog("Application did finish launching")
        processPendingBookmarks()
        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        NSLog("Application will enter foreground")
        processPendingBookmarks()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        NSLog("Application did become active")
        processPendingBookmarks()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        NSLog("Application will resign active")
        processPendingBookmarks()
    }

    private func processPendingBookmarks() {
        NSLog("Processing pending bookmarks")
        guard let sharedDefaults = sharedDefaults,
              let bookmarks = sharedDefaults.array(forKey: "pendingBookmarks") as? [[String: Any]] else {
            NSLog("No pending bookmarks found")
            return
        }
        
        NSLog("Found \(bookmarks.count) pending bookmarks")
        
        for bookmark in bookmarks {
            if let url = bookmark["url"] as? String,
               let comment = bookmark["comment"] as? String {
                NSLog("Processing bookmark: URL = \(url), Comment = \(comment)")
                saveBookmark(url: url, comment: comment)
            } else {
                NSLog("Invalid bookmark data")
            }
        }
        
        sharedDefaults.removeObject(forKey: "pendingBookmarks")
        NSLog("Cleared pending bookmarks")
    }

    private func saveBookmark(url: String, comment: String) {
        NSLog("Saving bookmark to API: URL = \(url), Comment = \(comment)")
        NetworkService.shared.addBookmark(bookmarkURL: url, comment: comment, starred: false)
            .sink { completion in
                switch completion {
                case .finished:
                    NSLog("Bookmark save operation completed")
                case .failure(let error):
                    NSLog("Failed to save bookmark: \(error.localizedDescription)")
                }
            } receiveValue: { response in
                if let message = response.message {
                    NSLog("Bookmark saved successfully: \(message)")
                } else if let error = response.error {
                    NSLog("Failed to save bookmark: \(error)")
                }
            }
            .store(in: &cancellables)
    }
}
