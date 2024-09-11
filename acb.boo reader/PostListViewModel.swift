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
        }

        isLoading = true
        error = nil

        NetworkService.shared.fetchPosts(page: currentPage)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error.localizedDescription
                    self?.canLoadMore = false
                }
            } receiveValue: { [weak self] response in
                if let newPosts = response.items {
                    if loadMore {
                        self?.posts.append(contentsOf: newPosts)
                    } else {
                        self?.posts = newPosts
                    }
                    self?.canLoadMore = response.meta?.currentPage ?? 0 < response.meta?.totalPages ?? 0
                } else {
                    self?.error = "No posts found"
                    self?.canLoadMore = false
                }
            }
            .store(in: &cancellables)
    }
    
    func addPost(title: String, content: String, tags: String, completion: @escaping (Bool, String) -> Void) {
        isLoading = true
        error = nil

        NetworkService.shared.addPost(title: title, content: content, tags: tags)
            .sink { [weak self] completionResult in
                self?.isLoading = false
                if case .failure(let error) = completionResult {
                    self?.error = error.localizedDescription
                    completion(false, error.localizedDescription)
                }
            } receiveValue: { [weak self] response in
                if let errorMessage = response.error {
                    completion(false, errorMessage)
                } else if let successMessage = response.message {
                    self?.loadPosts() // Refresh the list after adding
                    completion(true, successMessage)
                } else {
                    completion(true, "Post added successfully")
                }
            }
            .store(in: &cancellables)
    }

    func editPost(id: Int, title: String, content: String, tags: String, completion: @escaping (Bool, String) -> Void) {
        isLoading = true
        error = nil

        NetworkService.shared.editPost(id: id, title: title, content: content, tags: tags)
            .sink { [weak self] completionResult in
                self?.isLoading = false
                if case .failure(let error) = completionResult {
                    self?.error = error.localizedDescription
                    completion(false, error.localizedDescription)
                }
            } receiveValue: { [weak self] response in
                if let errorMessage = response.error {
                    completion(false, errorMessage)
                } else if let successMessage = response.message {
                    self?.loadPosts() // Refresh the list after editing
                    completion(true, successMessage)
                } else {
                    completion(true, "Post edited successfully")
                }
            }
            .store(in: &cancellables)
    }

    func deletePost(id: Int, completion: @escaping (Bool, String) -> Void) {
        isLoading = true
        error = nil

        NetworkService.shared.deletePost(id: id)
            .sink { [weak self] completionResult in
                self?.isLoading = false
                if case .failure(let error) = completionResult {
                    self?.error = error.localizedDescription
                    completion(false, error.localizedDescription)
                }
            } receiveValue: { [weak self] response in
                if let errorMessage = response.error {
                    completion(false, errorMessage)
                } else if let successMessage = response.message {
                    self?.loadPosts() // Refresh the list after deleting
                    completion(true, successMessage)
                } else {
                    completion(true, "Post deleted successfully")
                }
            }
            .store(in: &cancellables)
    }

    func addBookmark(url: String, comment: String, starred: Bool, completion: @escaping (Bool, String) -> Void) {
        isLoading = true
        error = nil

        NetworkService.shared.addBookmark(bookmarkURL: url, comment: comment, starred: starred)
            .sink { [weak self] completionResult in
                self?.isLoading = false
                if case .failure(let error) = completionResult {
                    self?.error = error.localizedDescription
                    completion(false, error.localizedDescription)
                }
            } receiveValue: { [weak self] response in
                if let errorMessage = response.error {
                    completion(false, errorMessage)
                } else if let successMessage = response.message {
                    self?.loadPosts() // Refresh the list after adding
                    completion(true, successMessage)
                } else {
                    completion(true, "Bookmark added successfully")
                }
            }
            .store(in: &cancellables)
    }

    func deleteBookmark(id: Int, completion: @escaping (Bool, String) -> Void) {
        isLoading = true
        error = nil

        NetworkService.shared.deleteBookmark(id: id)
            .sink { [weak self] completionResult in
                self?.isLoading = false
                if case .failure(let error) = completionResult {
                    self?.error = error.localizedDescription
                    completion(false, error.localizedDescription)
                }
            } receiveValue: { [weak self] response in
                if let errorMessage = response.error {
                    completion(false, errorMessage)
                } else if let successMessage = response.message {
                    self?.loadPosts() // Refresh the list after deleting
                    completion(true, successMessage)
                } else {
                    completion(true, "Bookmark deleted successfully")
                }
            }
            .store(in: &cancellables)
    }

    func fetchFullPost(year: String, slug: String, completion: @escaping (Result<FullPost, Error>) -> Void) {
        NetworkService.shared.fetchFullPost(year: year, slug: slug)
            .sink { completionResult in
                if case .failure(let error) = completionResult {
                    completion(.failure(error))
                }
            } receiveValue: { fullPost in
                completion(.success(fullPost))
            }
            .store(in: &cancellables)
    }
}
