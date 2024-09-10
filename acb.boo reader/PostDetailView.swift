//
//  PostDetailView.swift
//  acb.boo reader
//
//  Created by Aidan Cornelius-Bell on 10/9/2024.
//

import SwiftUI
import Combine

struct PostDetailView: View {
    let post: Post
    @State private var fullPost: FullPost?
    @State private var isLoading = false
    @State private var error: String?
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(post.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                if let fullPost = fullPost {
                    Text("Reading time: \(fullPost.readingTime) min")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if !fullPost.tags.isEmpty {
                        Text("Tags: \(fullPost.tags.joined(separator: ", "))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    if isLoading {
                        ProgressView()
                    } else {
                        Text(fullPost.content.htmlAttributedString())
                            .font(.body)
                    }
                } else if let error = error {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                } else {
                    ProgressView()
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: sharePost) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .onAppear(perform: loadFullPost)
    }

    private func loadFullPost() {
        guard let slug = post.slug else {
            self.error = "No slug available for this post"
            return
        }

        let year = String(post.date.prefix(4))

        isLoading = true
        error = nil

        NetworkService.shared.fetchFullPost(year: year, slug: slug)
            .sink { completion in
                isLoading = false
                if case .failure(let error) = completion {
                    self.error = error.localizedDescription
                }
            } receiveValue: { fullPost in
                self.fullPost = fullPost
            }
            .store(in: &cancellables)
    }

    private func sharePost() {
        let baseURL = "https://acb.boo"
        let fullURL = "\(baseURL)/\(post.date.prefix(4))/\(post.slug ?? "")"
        guard let url = URL(string: fullURL) else { return }
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityViewController, animated: true, completion: nil)
        }
    }
}
