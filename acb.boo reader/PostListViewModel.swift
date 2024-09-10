//
//  PostListViewModel.swift
//  acb.boo reader
//
//  Created by Aidan Cornelius-Bell on 10/9/2024.
//

import Foundation
import Combine

class PostListViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var error: String?

    private var currentPage = 1
    private var canLoadMore = true
    private var cancellables = Set<AnyCancellable>()

    func loadMoreIfNeeded() {
        guard !isLoading && canLoadMore else { return }
        loadPosts(loadMore: true)
    }

    func loadPosts(loadMore: Bool = false) {
        if loadMore {
            currentPage += 1
        } else {
            currentPage = 1
            posts = []
        }

        isLoading = true
        error = nil

        NetworkService.shared.fetchPosts(page: currentPage)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error.localizedDescription
                    self?.canLoadMore = false
                }
            } receiveValue: { [weak self] response in
                if loadMore {
                    self?.posts += response.items
                } else {
                    self?.posts = response.items
                }
                self?.canLoadMore = response.meta.currentPage < response.meta.totalPages
            }
            .store(in: &cancellables)
    }
}
