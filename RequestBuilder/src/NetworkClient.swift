import Foundation
import KhanlouPromise

public typealias JSONType = Any // arrays and dicts

public enum NetworkClientError: Error {
    case MalformedRequest
    case InvalidResponse
    case InvalidJSON
}

public final class NetworkClient {
    
    let session: URLSessionProtocol
    public let baseURL: URL
    
    let defaultRequestBehavior: RequestBehavior
    
    public init(baseURL: URL,
         session: URLSessionProtocol = URLSession.shared,
         defaultRequestBehavior: RequestBehavior? = nil) {
        
        self.baseURL = baseURL
        self.session = session
        self.defaultRequestBehavior = defaultRequestBehavior ?? EmptyRequestBehavior()
    }
    
    private func _send(requestBuilder: RequestBuilder) -> Promise<(Data, HTTPURLResponse)> {
        guard let urlRequest = requestBuilder.request() else {
            return Promise<(Data, HTTPURLResponse)>(error: NetworkClientError.MalformedRequest)
        }
        
        let behavior = requestBuilder.behavior
        behavior.beforeSend(request: urlRequest)
        return session.data(with: urlRequest).then({ (data, response) in
            behavior.afterSuccess(request: urlRequest, response: response, result: data)
        }).catch({ (error) in
            behavior.afterFailure(request: urlRequest, response: nil, error: error)
        })
    }

}


// MARK: Convenience
extension NetworkClient {
    
    public func GET(_ path: String) -> ClientRequestBuilder {
        return ClientRequestBuilder(for: self, method: "GET", endpoint: path)
    }
    
    public func POST(_ path: String) -> ClientRequestBuilder {
        return ClientRequestBuilder(for: self, method: "POST", endpoint: path)
    }
    
}


// MARK: NetworkClientProtocol
extension NetworkClient : NetworkClientProtocol {

    public func send(requestBuilder: RequestBuilder) -> Promise<(Data, HTTPURLResponse)> {
        assert(baseURL == requestBuilder.baseURL)
        return _send(requestBuilder: requestBuilder.withBehavior(defaultRequestBehavior))
    }
    
    public func parseJSONReponse(_ response: HTTPURLResponse, data: Data) throws -> Promise<JSONType> {
        // TODO error handling
        if response.statusCode >= 400 {
            let info = [NSLocalizedDescriptionKey: "Request/Server error " + (String(data: data, encoding: .utf8) ?? "?")]
            throw NSError(domain: "NetworkClient", code: 10000 + response.statusCode, userInfo: info)
        }
        
        let value = try JSONSerialization.jsonObject(with: data) // may throw, which is fine with us (rejects promise)
        return Promise<JSONType>(value: value)
    }
    
    public func JSONData(for dict: Dictionary<String, Any>) throws -> Data? {
        return try JSONSerialization.data(withJSONObject: dict, options: [])
    }
    
}
