//
//  Utilities.swift
//  acb.boo reader
//
//  Created by Aidan Cornelius-Bell on 10/9/2024.
//

import Foundation
import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = true
        configuration.barCollapsingEnabled = false
        let safariViewController = SFSafariViewController(url: url, configuration: configuration)
        safariViewController.preferredControlTintColor = .black  // Or any color that fits your app's theme
        safariViewController.preferredBarTintColor = .white  // Or any color that fits your app's theme
        return safariViewController
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {}
}

extension String {
    func htmlAttributedString() -> AttributedString {
        guard let data = self.data(using: .utf8) else { return AttributedString(self) }
        do {
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]
            let attributedString = try NSAttributedString(data: data, options: options, documentAttributes: nil)

            let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)

            // Apply custom styling
            mutableAttributedString.enumerateAttributes(in: NSRange(location: 0, length: mutableAttributedString.length), options: []) { (attributes, range, _) in
                var newAttributes = attributes

                // Set font for all text
                newAttributes[.font] = UIFont.preferredFont(forTextStyle: .body)

                // Adjust heading sizes
                if let fontAttribute = attributes[.font] as? UIFont {
                    if fontAttribute.fontDescriptor.symbolicTraits.contains(.traitBold) {
                        if fontAttribute.pointSize > UIFont.preferredFont(forTextStyle: .body).pointSize {
                            newAttributes[.font] = UIFont.preferredFont(forTextStyle: .title2)
                        } else {
                            newAttributes[.font] = UIFont.preferredFont(forTextStyle: .headline)
                        }
                    }
                }

                mutableAttributedString.setAttributes(newAttributes, range: range)
            }

            return AttributedString(mutableAttributedString)
        } catch {
            print("Error converting HTML to AttributedString: \(error)")
            return AttributedString(self)
        }
    }
}
