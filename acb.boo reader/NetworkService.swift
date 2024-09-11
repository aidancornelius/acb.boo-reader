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
    
    private var apiKey: String {
        return UserDefaults.standard.string(forKey: "apiKey") ?? ""
    }

    private func addApiKeyToRequest(_ request: inout URLRequest) {
        print("DEBUG: Current API Key: \(apiKey)")
        if !apiKey.isEmpty {
            if request.httpMethod == "GET" {
                var components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
                var queryItems = components.queryItems ?? []
                queryItems.append(URLQueryItem(name: "api_key", value: apiKey))
                components.queryItems = queryItems
                request.url = components.url
            } else {
                // For POST requests, add API key to the body
                var bodyString = String(data: request.httpBody ?? Data(), encoding: .utf8) ?? ""
                if !bodyString.isEmpty {
                    bodyString += "&"
                }
                bodyString += "api_key=\(apiKey)"
                request.httpBody = bodyString.data(using: .utf8)
            }
        }
        print("DEBUG: Final request URL: \(request.url?.absoluteString ?? "nil")")
        print("DEBUG: Final request body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "nil")")
    }

    func fetchPosts(page: Int = 1, perPage: Int = 15, filter: String = "all") -> AnyPublisher<ApiResponse, Error> {
        let urlString = "\(baseURL)?request=list&page=\(page)&per_page=\(perPage)&filter=\(filter)"
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addApiKeyToRequest(&request)

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("DEBUG: Response status code: \(httpResponse.statusCode)")
                }
                print("DEBUG: Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
                return data
            }
            .decode(type: ApiResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func fetchFullPost(year: String, slug: String) -> AnyPublisher<FullPost, Error> {
        let urlString = "\(baseURL)?request=post&year=\(year)&slug=\(slug)"
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addApiKeyToRequest(&request)

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("DEBUG: Response status code: \(httpResponse.statusCode)")
                }
                print("DEBUG: Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
                return data
            }
            .decode(type: FullPost.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func addPost(title: String, content: String, tags: String) -> AnyPublisher<ApiResponse, Error> {
        let urlString = "\(baseURL)?request=add_post"
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let parameters: [String: String] = [
            "title": title,
            "content": content,
            "tags": tags
        ]
        request.httpBody = parameters.percentEncoded()

        addApiKeyToRequest(&request)

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("DEBUG: Response status code: \(httpResponse.statusCode)")
                }
                print("DEBUG: Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
                return data
            }
            .decode(type: ApiResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func editPost(id: Int, title: String, content: String, tags: String) -> AnyPublisher<ApiResponse, Error> {
        let urlString = "\(baseURL)?request=edit_post"
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let parameters: [String: String] = [
            "id": String(id),
            "title": title,
            "content": content,
            "tags": tags
        ]
        request.httpBody = parameters.percentEncoded()

        addApiKeyToRequest(&request)

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("DEBUG: Response status code: \(httpResponse.statusCode)")
                }
                print("DEBUG: Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
                return data
            }
            .decode(type: ApiResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func deletePost(id: Int) -> AnyPublisher<ApiResponse, Error> {
        let urlString = "\(baseURL)?request=delete_post"
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let parameters: [String: String] = [
            "id": String(id)
        ]
        request.httpBody = parameters.percentEncoded()

        addApiKeyToRequest(&request)

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("DEBUG: Response status code: \(httpResponse.statusCode)")
                }
                print("DEBUG: Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
                return data
            }
            .decode(type: ApiResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func addBookmark(bookmarkURL: String, comment: String, starred: Bool) -> AnyPublisher<ApiResponse, Error> {
        let urlString = "\(baseURL)?request=add_bookmark"
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let parameters: [String: String] = [
            "url": bookmarkURL,
            "comment": comment,
            "starred": starred ? "1" : "0"
        ]
        request.httpBody = parameters.percentEncoded()

        addApiKeyToRequest(&request)

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("DEBUG: Response status code: \(httpResponse.statusCode)")
                }
                print("DEBUG: Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
                return data
            }
            .decode(type: ApiResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func deleteBookmark(id: Int) -> AnyPublisher<ApiResponse, Error> {
        let urlString = "\(baseURL)?request=delete_bookmark"
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let parameters: [String: String] = [
            "id": String(id)
        ]
        request.httpBody = parameters.percentEncoded()

        addApiKeyToRequest(&request)

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("DEBUG: Response status code: \(httpResponse.statusCode)")
                }
                print("DEBUG: Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
                return data
            }
            .decode(type: ApiResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func saveSharedBookmark(url: String, comment: String, starred: Bool) -> AnyPublisher<ApiResponse, Error> {
        let urlString = "\(baseURL)?request=add_bookmark"
        guard let requestURL = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let parameters: [String: String] = [
            "url": url,
            "comment": comment,
            "starred": starred ? "1" : "0"
        ]
        request.httpBody = parameters.percentEncoded()

        addApiKeyToRequest(&request)

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("DEBUG: Response status code: \(httpResponse.statusCode)")
                }
                print("DEBUG: Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
                return data
            }
            .decode(type: ApiResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

extension Dictionary {
    func percentEncoded() -> Data? {
        return map { key, value in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return escapedKey + "=" + escapedValue
        }
        .joined(separator: "&")
        .data(using: .utf8)
    }
}
