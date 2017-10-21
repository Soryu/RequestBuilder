import Foundation
import KhanlouPromise

public protocol NetworkClientProtocol {
    
    var baseURL: URL { get }
    
    init(baseURL: URL, session: URLSessionProtocol, defaultRequestBehavior: RequestBehavior?)
    
    func send(requestBuilder: RequestBuilder) -> Promise<(Data, HTTPURLResponse)>
    func parseJSONReponse(_ response: HTTPURLResponse, data: Data) throws -> Promise<JSONType>
    func JSONData(for dict: Dictionary<String, Any>) throws -> Data?
    
}
