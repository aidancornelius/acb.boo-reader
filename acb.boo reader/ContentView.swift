//
//  ContentView.swift
//  acb.boo reader
//
//  Created by Aidan Cornelius-Bell on 10/9/2024.
//

import SwiftUI
import SafariServices

struct ContentView: View {
    @StateObject private var viewModel = PostListViewModel()
    @State private var selectedBookmarkURL: URL?

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.posts) { post in
                    ListRowWrapper {
                        if post.type == "bookmark" {
                            Button(action: {
                                if let url = URL(string: post.url) {
                                    selectedBookmarkURL = url
                                }
                            }) {
                                PostRow(post: post)
                            }
                        } else {
                            NavigationLink(destination: PostDetailView(post: post)) {
                                PostRow(post: post)
                            }
                        }
                    }
                    .onAppear {
                        if post.id == viewModel.posts.last?.id {
                            viewModel.loadMoreIfNeeded()
                        }
                    }
                }

                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle("acb.boo")
            .onAppear {
                if viewModel.posts.isEmpty {
                    viewModel.loadPosts()
                }
            }
            .refreshable {
                viewModel.loadPosts()
            }
        }
        .sheet(item: $selectedBookmarkURL) { url in
            SafariView(url: url)
                .edgesIgnoringSafeArea(.all)
        }
    }
}

struct ListRowWrapper<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
    }
}

struct BookmarkRow: View {
    let post: Post
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            PostRow(post: post)
        }
    }
}

extension URL: Identifiable {
    public var id: String { self.absoluteString }
}

struct PostRow: View {
    let post: Post

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(post.type == "post" ? "✳︎" : "❥")
                .font(.title2)
                .foregroundColor(post.type == "post" ? Color(hex: 0xfabd2f) : Color(hex: 0xe6416e))
                .frame(width: 30, alignment: .center)

            VStack(alignment: .leading, spacing: 4) {
                Text(post.title)
                    .font(.headline)
                    .lineLimit(2)
                Text(post.date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                if post.type == "post", let excerpt = post.excerpt {
                    Text(excerpt)
                        .font(.subheadline)
                        .lineLimit(2)
                        .foregroundColor(.secondary)
                } else if post.type == "bookmark", let comment = post.comment {
                    Text(comment)
                        .font(.subheadline)
                        .lineLimit(2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// Make sure to include your Color extension for hex colors
extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

#Preview {
    ContentView()
}
