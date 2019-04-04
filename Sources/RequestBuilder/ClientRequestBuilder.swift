import Foundation
import Dispatch
import Promise

public class ClientRequestBuilder: RequestBuilder {
    
    let client: NetworkClientSendProtocol

    internal init(for client: NetworkClientSendProtocol, baseURL: URL, method: String, endpoint: String) {
        self.client = client
        super.init(baseURL: baseURL, method: method, endpoint: endpoint)
    }
        
    public func sendRequest() -> DataResponsePromise {
        return client.send(requestBuilder: self)
    }
    
}


