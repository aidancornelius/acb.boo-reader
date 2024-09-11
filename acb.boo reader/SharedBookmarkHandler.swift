//
//  SharedBookmarkHandler.swift
//  acb.boo reader
//
//  Created by Aidan Cornelius-Bell on 11/9/2024.
//

import Foundation
import Combine

class SharedBookmarkHandler {
    static let shared = SharedBookmarkHandler()
    private init() {}
    
    private var cancellables = Set<AnyCancellable>()
    
    func saveSharedBookmark(url: String, comment: String, starred: Bool, completion: @escaping (Bool, String) -> Void) {
        NetworkService.shared.saveSharedBookmark(url: url, comment: comment, starred: starred)
            .sink { result in
                switch result {
                case .finished:
                    break
                case .failure(let error):
                    completion(false, "Failed to save bookmark: \(error.localizedDescription)")
                }
            } receiveValue: { response in
                if let error = response.error {
                    completion(false, "Failed to save bookmark: \(error)")
                } else {
                    completion(true, "Bookmark saved successfully")
                }
            }
            .store(in: &cancellables)
    }
}
