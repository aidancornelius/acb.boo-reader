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

    private let baseURL = "https://acb.boo/api/v1/api"
    
    private var apiKey: String {
        return UserDefaults.standard.string(forKey: "apiKey") ?? ""
    }

    func setApiKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "apiKey")
    }

    private func createRequest(path: String, method: String, parameters: [String: Any]) -> URLRequest? {
        guard var components = URLComponents(string: baseURL) else {
            return nil
        }
        
        if !path.isEmpty {
            components.path += "/\(path)"
        }
        
        if method == "GET" {
            var queryItems = parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
            queryItems.append(URLQueryItem(name: "api_key", value: apiKey))
            components.queryItems = queryItems
        }
        
        guard let url = components.url else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        if method == "POST" {
            var bodyParameters = parameters
            bodyParameters["api_key"] = apiKey
            request.httpBody = try? JSONSerialization.data(withJSONObject: bodyParameters)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        
        return request
    }

    private func performRequest<T: Decodable>(_ request: URLRequest) -> AnyPublisher<T, Error> {
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("DEBUG: Response status code: \(httpResponse.statusCode)")
                }
                print("DEBUG: Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
                return data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func fetchPosts(page: Int = 1, perPage: Int = 15, filter: String = "all") -> AnyPublisher<ApiResponse, Error> {
        let parameters: [String: Any] = [
            "request": "list",
            "page": page,
            "per_page": perPage,
            "filter": filter
        ]
        
        guard let request = createRequest(path: "", method: "GET", parameters: parameters) else {
            NSLog("Failed to create request for fetching posts")
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        NSLog("Fetching posts with URL: \(request.url?.absoluteString ?? "nil")")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    NSLog("Invalid response type")
                    throw URLError(.badServerResponse)
                }
                NSLog("Response status code: \(httpResponse.statusCode)")
                
                if let responseString = String(data: data, encoding: .utf8) {
                    NSLog("Response body: \(responseString)")
                }
                
                if (200...299).contains(httpResponse.statusCode) {
                    return data
                } else {
                    NSLog("Server error with status code: \(httpResponse.statusCode)")
                    throw NSError(domain: "ServerError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server responded with status code \(httpResponse.statusCode)"])
                }
            }
            .decode(type: ApiResponse.self, decoder: JSONDecoder())
            .mapError { error -> Error in
                if let decodingError = error as? DecodingError {
                    NSLog("Decoding error: \(decodingError)")
                    return NSError(domain: "DecodingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to decode response: \(decodingError.localizedDescription)"])
                } else {
                    NSLog("Network error: \(error.localizedDescription)")
                    return error
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }


    func fetchFullPost(year: String, slug: String) -> AnyPublisher<FullPost, Error> {
        let parameters: [String: Any] = [
            "request": "post",
            "year": year,
            "slug": slug
        ]
        
        guard let request = createRequest(path: "", method: "GET", parameters: parameters) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        return performRequest(request)
    }

    func addPost(title: String, content: String, tags: String) -> AnyPublisher<ApiResponse, Error> {
        let parameters: [String: Any] = [
            "request": "add_post",
            "post_type": "dispatch",
            "title": title,
            "content": content,
            "tags": tags
        ]
        
        guard let request = createRequest(path: "", method: "POST", parameters: parameters) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        return performRequest(request)
    }

    func editPost(id: Int, title: String, content: String, tags: String) -> AnyPublisher<ApiResponse, Error> {
        let parameters: [String: Any] = [
            "request": "edit_post",
            "id": id,
            "title": title,
            "content": content,
            "tags": tags
        ]
        
        guard let request = createRequest(path: "", method: "POST", parameters: parameters) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        return performRequest(request)
    }

    func deletePost(id: Int) -> AnyPublisher<ApiResponse, Error> {
        let parameters: [String: Any] = [
            "request": "delete_post",
            "id": id
        ]
        
        guard let request = createRequest(path: "", method: "POST", parameters: parameters) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        return performRequest(request)
    }

    func addBookmark(bookmarkURL: String, comment: String, starred: Bool) -> AnyPublisher<ApiResponse, Error> {
        let parameters: [String: Any] = [
            "request": "add_bookmark",
            "url": bookmarkURL,
            "title": "",
            "comment": comment,
            "starred": starred ? "1" : "0"
        ]
        
        guard let request = createRequest(path: "", method: "POST", parameters: parameters) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        return performRequest(request)
    }

    func deleteBookmark(id: Int) -> AnyPublisher<ApiResponse, Error> {
        let parameters: [String: Any] = [
            "request": "delete_bookmark",
            "id": id
        ]
        
        guard let request = createRequest(path: "", method: "POST", parameters: parameters) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        return performRequest(request)
    }

    func saveSharedBookmark(url: String, comment: String, starred: Bool) -> AnyPublisher<ApiResponse, Error> {
        return addBookmark(bookmarkURL: url, comment: comment, starred: starred)
    }
}
