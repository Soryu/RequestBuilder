import Foundation

public class RequestBuilder {
    
    private let method: String
    private var urlComponents: URLComponents
    private var body: Data?
    private (set) var behavior: RequestBehavior = EmptyRequestBehavior()
    private(set) var baseURL: URL

    public init(baseURL: URL, method: String, endpoint: String) {
        self.baseURL       = baseURL
        self.method        = method
        
        urlComponents = URLComponents(url: baseURL.appendingPathComponent(endpoint), resolvingAgainstBaseURL: false)!
    }
    
}

// MARK: convenience
public extension RequestBuilder {

    static func GET(_ endpoint: String, baseURL: URL) -> RequestBuilder {
        return RequestBuilder(baseURL: baseURL, method: "GET", endpoint: endpoint)
    }
    
    static func POST(_ endpoint: String, data: Data? = nil, baseURL: URL) -> RequestBuilder {
        let rb = RequestBuilder(baseURL: baseURL, method: "POST", endpoint: endpoint)
        
        if let data = data {
            rb.withBody(data)
        }
        
        return rb
    }

    static func PUT(_ endpoint: String, data: Data? = nil, baseURL: URL) -> RequestBuilder {
        let rb = RequestBuilder(baseURL: baseURL, method: "PUT", endpoint: endpoint)

        if let data = data {
            rb.withBody(data)
        }

        return rb
    }

}

// MARK: builder
public extension RequestBuilder {

    @discardableResult func withQuery(_ dictionary: Dictionary<String, String?>) -> Self {
        var queryItems = urlComponents.queryItems ?? [URLQueryItem]()
        queryItems.append(contentsOf: dictionary.compactMap { key, value -> URLQueryItem? in
            guard let value = value else { return nil }
            return URLQueryItem(name: key, value: value)
        })
        
        urlComponents.queryItems = queryItems
        
        return self
    }

    @discardableResult func withQueryItems(_ items: [URLQueryItem]) -> Self {
        var queryItems = urlComponents.queryItems ?? [URLQueryItem]()
        queryItems.append(contentsOf: items)
        urlComponents.queryItems = queryItems
        
        return self
    }

    @discardableResult func withBody(_ data: Data) -> Self {
        assert(["POST", "PUT"].contains(method))
        assert(body == nil)
        
        body = data
        return self
    }
    
    @discardableResult func withBehavior(_ newBehavior: RequestBehavior) -> Self {
        
        if var combinedBehavior = behavior as? CombinedRequestBehavior {
            combinedBehavior.addBehaviour(newBehavior)
            behavior = combinedBehavior
        } else {
            behavior = CombinedRequestBehavior(behaviors: [behavior, newBehavior])
        }
        
        return self
    }

    func request() -> URLRequest? {
        guard let url = urlComponents.url else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        if let body = body {
            request.httpBody = body
        }
        
        behavior.additionalHeaders.forEach({ (field, value) in
            request.addValue(value, forHTTPHeaderField: field)
        })
        
        return request
    }
    
}
