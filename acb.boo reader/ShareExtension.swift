//
//  ShareExtension.swift
//  acb.boo reader
//
//  Created by Aidan Cornelius-Bell on 11/9/2024.
//

import Foundation
import UIKit
import Social
import MobileCoreServices

@objc(ShareViewController)
class ShareViewController: UIViewController {

    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var commentTextField: UITextField!
    
    let sharedDefaults = UserDefaults(suiteName: "group.com.aidancorneliusbell.acbbooreader")

    override func viewDidLoad() {
        super.viewDidLoad()
        print("ShareViewController loaded")
        loadSharedData()
    }
    
    private func loadSharedData() {
        if let item = extensionContext?.inputItems.first as? NSExtensionItem,
           let itemProvider = item.attachments?.first {
            
            if itemProvider.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
                itemProvider.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil) { [weak self] (url, error) in
                    DispatchQueue.main.async {
                        if let shareURL = url as? URL {
                            print("Shared URL: \(shareURL.absoluteString)")
                            self?.urlTextField.text = shareURL.absoluteString
                        } else if let error = error {
                            print("Error loading shared URL: \(error.localizedDescription)")
                        }
                    }
                }
            } else {
                print("No URL found in shared content")
            }
        }
    }
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        guard let url = urlTextField.text, !url.isEmpty else {
            print("Error: URL is empty")
            return
        }
        
        let comment = commentTextField.text ?? ""
        
        print("Attempting to save bookmark: URL = \(url), Comment = \(comment)")
        saveBookmark(url: url, comment: comment)
        
        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    private func saveBookmark(url: String, comment: String) {
        guard let sharedDefaults = sharedDefaults else {
            print("Error: Could not access shared UserDefaults")
            return
        }
        
        let bookmark = ["url": url, "comment": comment, "date": Date().timeIntervalSince1970] as [String : Any]
        
        if var bookmarks = sharedDefaults.array(forKey: "pendingBookmarks") as? [[String: Any]] {
            bookmarks.append(bookmark)
            sharedDefaults.set(bookmarks, forKey: "pendingBookmarks")
            print("Added bookmark to existing pendingBookmarks. Total count: \(bookmarks.count)")
        } else {
            sharedDefaults.set([bookmark], forKey: "pendingBookmarks")
            print("Created new pendingBookmarks with 1 bookmark")
        }
        
        print("Bookmark saved to shared UserDefaults")
    }
}
