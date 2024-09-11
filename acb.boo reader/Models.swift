//
//  Models.swift
//  acb.boo reader
//
//  Created by Aidan Cornelius-Bell on 10/9/2024.
//

import Foundation

struct Post: Identifiable, Codable, Equatable {
    let id: Int
    let type: String
    let date: String
    let title: String
    let slug: String?
    let excerpt: String?
    let tags: [String]?
    let url: String
    let comment: String?
}

struct FullPost: Identifiable, Codable {
    let id: Int
    let title: String
    let date: String
    let content: String
    let tags: [String]
    let url: String
    let readingTime: Int

    enum CodingKeys: String, CodingKey {
        case id, title, date, content, tags, url
        case readingTime = "reading_time"
    }
}

struct ApiResponse: Codable {
    let items: [Post]?
    let meta: Meta?
    let message: String?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case items, meta, message, error
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try container.decodeIfPresent([Post].self, forKey: .items)
        meta = try container.decodeIfPresent(Meta.self, forKey: .meta)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        error = try container.decodeIfPresent(String.self, forKey: .error)
    }
}

struct Meta: Codable {
    let currentPage: Int
    let totalPages: Int
    let perPage: Int
    let totalItems: Int

    enum CodingKeys: String, CodingKey {
        case currentPage = "current_page"
        case totalPages = "total_pages"
        case perPage = "per_page"
        case totalItems = "total_items"
    }
}
