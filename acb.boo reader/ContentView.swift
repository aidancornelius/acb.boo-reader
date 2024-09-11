//
//  ContentView.swift
//  acb.boo reader
//
//  Created by Aidan Cornelius-Bell on 10/9/2024.
//

import SwiftUI
import os
import SafariServices

struct ContentView: View {
    @StateObject private var viewModel = PostListViewModel()
    @StateObject private var appSettings = AppSettings()
    @State private var selectedBookmarkURL: URL?
    @State private var showingAddSheet = false
    @State private var isAddingPost = false
    @State private var showingSettingsSheet = false
    @State private var toastMessage = ""
    @State private var isShowingToast = false
    @State private var isToastError = false

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
                            .swipeActions {
                                Button(role: .destructive) {
                                    viewModel.deleteBookmark(id: post.id) { success, message in
                                        if success {
                                            showToast(message: "Bookmark deleted successfully", isError: false)
                                        } else {
                                            showToast(message: "Failed to delete bookmark: \(message)", isError: true)
                                        }
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        } else {
                            NavigationLink(destination: PostDetailView(post: post, viewModel: viewModel, showToast: showToast)) {
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { showingAddSheet = true }) {
                            Image(systemName: "plus")
                        }
                        Button(action: { showingSettingsSheet = true }) {
                            Image(systemName: "gear")
                        }
                    }
                }
            }
            .onAppear {
                if viewModel.posts.isEmpty {
                    viewModel.loadPosts()
                }
            }
            .refreshable {
                viewModel.loadPosts()
            }
            .sheet(isPresented: $showingAddSheet) {
                AddItemView(isAddingPost: $isAddingPost, viewModel: viewModel, showToast: showToast)
            }
            .sheet(isPresented: $showingSettingsSheet) {
                NavigationView {
                    SettingsView(appSettings: appSettings)
                }
            }
            .overlay(
                Toast(message: toastMessage, isError: isToastError, isShowing: $isShowingToast)
            )
        }
        .sheet(item: $selectedBookmarkURL) { url in
            SafariView(url: url)
                .edgesIgnoringSafeArea(.all)
        }
    }

    private func showToast(message: String, isError: Bool) {
        toastMessage = message
        isToastError = isError
        isShowingToast = true
    }
}

// Update AddItemView to use the new functionality
struct AddItemView: View {
    @Binding var isAddingPost: Bool
    @ObservedObject var viewModel: PostListViewModel
    @State private var title = ""
    @State private var content = ""
    @State private var tags = ""
    @State private var url = ""
    @State private var comment = ""
    @State private var isStarred = false
    @Environment(\.presentationMode) var presentationMode
    var showToast: (String, Bool) -> Void

    var body: some View {
        NavigationView {
            Form {
                Picker("Type", selection: $isAddingPost) {
                    Text("Post").tag(true)
                    Text("Bookmark").tag(false)
                }
                .pickerStyle(SegmentedPickerStyle())

                if isAddingPost {
                    TextField("Title", text: $title)
                    TextEditor(text: $content)
                        .frame(height: 200)
                    TextField("Tags", text: $tags)
                } else {
                    TextField("URL", text: $url)
                    TextField("Comment", text: $comment)
                    Toggle("Starred", isOn: $isStarred)
                }

                Button(action: addItem) {
                    Text("Add")
                }
            }
            .navigationTitle(isAddingPost ? "Add Post" : "Add Bookmark")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }

    private func addItem() {
        if isAddingPost {
            viewModel.addPost(title: title, content: content, tags: tags) { success, message in
                showToast(message, !success)
                if success {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        } else {
            viewModel.addBookmark(url: url, comment: comment, starred: isStarred) { success, message in
                showToast(message, !success)
                if success {
                    presentationMode.wrappedValue.dismiss()
                }
            }
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
