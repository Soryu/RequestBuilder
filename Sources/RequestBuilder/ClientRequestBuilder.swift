import Foundation
import Dispatch
import Promise

public class ClientRequestBuilder: RequestBuilder {
    
    let client: NetworkClientProtocol

    public init(for client: NetworkClientProtocol, method: String, endpoint: String) {
        self.client = client
        super.init(baseURL: client.baseURL, method: method, endpoint: endpoint)
    }
        
    public func sendRequest() -> Promise<(Data, HTTPURLResponse)> {
        return client.send(requestBuilder: self)
    }
    
    public func sendJSONRequest(json dict: Dictionary<String, Any>? = nil) -> Promise<JSONType> {
        withBehavior(JSONRequestBehavior())
        
        do {
            if  let dict = dict,
                let data = try client.JSONData(for: dict) {
                
                withBody(data)
            }
        } catch let error {
            print("error producing JSON: \(error)")
            return Promise<JSONType>(error: error)
        }
        
        return sendRequest().then(on: client.dispatchQueue, { data, response in
            return try self.client.parseJSONReponse(response, data: data)
        })
    }
    
}


