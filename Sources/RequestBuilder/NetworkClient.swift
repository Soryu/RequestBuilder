import Foundation
import Promise
import Dispatch

public enum NetworkClientError: Error {
    case MalformedRequest
    case InvalidResponse
}

public final class NetworkClient {
    
    let session: URLSessionProtocol
    public let baseURL: URL
    public let dispatchQueue: DispatchQueue
    
    let defaultRequestBehavior: RequestBehavior
    
    public init(baseURL: URL,
         session: URLSessionProtocol = URLSession.shared,
         defaultRequestBehavior: RequestBehavior? = nil,
         dispatchQueue: DispatchQueue = DispatchQueue.main) {
        
        self.baseURL = baseURL
        self.session = session
        self.defaultRequestBehavior = defaultRequestBehavior ?? EmptyRequestBehavior()
        self.dispatchQueue = dispatchQueue
    }
    
    private func _send(requestBuilder: RequestBuilder) -> DataResponsePromise {
        guard let urlRequest = requestBuilder.request() else {
            return DataResponsePromise(error: NetworkClientError.MalformedRequest)
        }
        
        let behavior = requestBuilder.behavior
        behavior.beforeSend(request: urlRequest)
        return session.data(with: urlRequest).then(on: dispatchQueue, { (data, response) -> (Data, HTTPURLResponse) in
            try behavior.afterSuccess(request: urlRequest, response: response, data: data)
            return (data, response)
        }).catch(on: dispatchQueue, { (error) in
            behavior.afterFailure(request: urlRequest, response: nil, error: error)
        })
    }

}


// MARK: Convenience
extension NetworkClient {
    
    public func GET(_ path: String) -> ClientRequestBuilder {
        return ClientRequestBuilder(for: self, baseURL: baseURL, method: "GET", endpoint: path)
    }
    
    public func POST(_ path: String, data: Data? = nil) -> ClientRequestBuilder {
        return ClientRequestBuilder(for: self, baseURL: baseURL, method: "POST", endpoint: path).withBody(data)
    }
    
}


// MARK: NetworkClientSendProtocol
extension NetworkClient : NetworkClientSendProtocol {

    public func send(requestBuilder: RequestBuilder) -> DataResponsePromise {
        assert(baseURL == requestBuilder.baseURL)
        return _send(requestBuilder: requestBuilder.withBehavior(defaultRequestBehavior))
    }
    
}
