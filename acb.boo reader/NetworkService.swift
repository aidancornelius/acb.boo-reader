//
//  NetworkService.swift
//  acb.boo reader
//
//  Created by Aidan Cornelius-Bell on 10/9/2024.
//

import Foundation
import Combine

class NetworkService {
    static let shared = NetworkService()
    private init() {}

    private let baseURL = "https://acb.boo/api.php"
    private let apiKey = "your_api_key_here"

    func fetchPosts(page: Int = 1, perPage: Int = 15, filter: String = "all") -> AnyPublisher<ApiResponse, Error> {
        let urlString = "\(baseURL)?api_key=\(apiKey)&request=list&page=\(page)&per_page=\(perPage)&filter=\(filter)"
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: ApiResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func fetchFullPost(year: String, slug: String) -> AnyPublisher<FullPost, Error> {
        let urlString = "\(baseURL)?api_key=\(apiKey)&request=post&year=\(year)&slug=\(slug)"
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: FullPost.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
