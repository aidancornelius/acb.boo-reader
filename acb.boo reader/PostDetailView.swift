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
    @ObservedObject var viewModel: PostListViewModel
    @State private var fullPost: FullPost?
    @State private var isLoading = false
    @State private var error: String?
    @State private var isEditing = false
    @State private var editedTitle: String
    @State private var editedContent: String
    @State private var editedTags: String
    @State private var showingDeleteAlert = false
    @Environment(\.presentationMode) var presentationMode
    var showToast: (String, Bool) -> Void

    init(post: Post, viewModel: PostListViewModel, showToast: @escaping (String, Bool) -> Void) {
        self.post = post
        self.viewModel = viewModel
        self.showToast = showToast
        _editedTitle = State(initialValue: post.title)
        _editedContent = State(initialValue: "")
        _editedTags = State(initialValue: post.tags?.joined(separator: ", ") ?? "")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if isEditing {
                    TextField("Title", text: $editedTitle)
                        .font(.largeTitle)
                    TextEditor(text: $editedContent)
                        .frame(height: 200)
                    TextField("Tags", text: $editedTags)
                        .font(.subheadline)
                } else {
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
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    if isEditing {
                        Button("Save") {
                            saveChanges()
                        }
                    } else {
                        Button("Edit") {
                            startEditing()
                        }
                        Button("Delete") {
                            showingDeleteAlert = true
                        }
                    }
                }
            }
        }
        .onAppear(perform: loadFullPost)
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Delete Post"),
                message: Text("Are you sure you want to delete this post?"),
                primaryButton: .destructive(Text("Delete")) {
                    deletePost()
                },
                secondaryButton: .cancel()
            )
        }
    }

    private func loadFullPost() {
        guard let slug = post.slug else {
            self.error = "No slug available for this post"
            return
        }

        let year = String(post.date.prefix(4))
        isLoading = true
        error = nil

        viewModel.fetchFullPost(year: year, slug: slug) { result in
            isLoading = false
            switch result {
            case .success(let fullPost):
                self.fullPost = fullPost
                self.editedContent = fullPost.content
            case .failure(let error):
                self.error = error.localizedDescription
            }
        }
    }

    private func startEditing() {
        isEditing = true
        editedTitle = post.title
        editedContent = fullPost?.content ?? ""
        editedTags = post.tags?.joined(separator: ", ") ?? ""
    }

    private func saveChanges() {
        viewModel.editPost(id: post.id, title: editedTitle, content: editedContent, tags: editedTags) { success, message in
            if success {
                isEditing = false
                loadFullPost() // Reload the full post to reflect changes
                showToast("Post updated successfully", false)
            } else {
                showToast("Failed to update post: \(message)", true)
            }
        }
    }

    private func deletePost() {
        viewModel.deletePost(id: post.id) { success, message in
            if success {
                showToast("Post deleted successfully", false)
                presentationMode.wrappedValue.dismiss()
            } else {
                showToast("Failed to delete post: \(message)", true)
            }
        }
    }
}
