import XCTest
@testable import RequestBuilder

class RequestBuilderTests: XCTestCase {
    
    static let baseURLString = "http://api.soryu2.net"
    let baseURL = URL(string: baseURLString)!
    
    func testGet() {
        let request = RequestBuilder
            .GET("get-endpoint", baseURL: baseURL)
            .request()
        
        XCTAssert(request != nil)
        XCTAssert(request?.url?.absoluteString == "\(RequestBuilderTests.baseURLString)/get-endpoint")
        XCTAssert(request?.httpMethod == "GET")
    }

    func testPost1() {
        let data = "some string".data(using: .utf8)!
        let request = RequestBuilder
            .POST("post-endpoint", data: data, baseURL: baseURL)
            .request()
        
        XCTAssert(request != nil)
        XCTAssert(request?.url?.absoluteString == "\(RequestBuilderTests.baseURLString)/post-endpoint")
        XCTAssert(request?.httpMethod == "POST")
        XCTAssert(request?.httpBody == data)
    }

    func testPost2() {
        let data = "some string".data(using: .utf8)!
        let request = RequestBuilder
            .POST("post-endpoint", baseURL: baseURL)
            .withBody(data)
            .request()
        
        XCTAssert(request != nil)
        XCTAssert(request?.url?.absoluteString == "\(RequestBuilderTests.baseURLString)/post-endpoint")
        XCTAssert(request?.httpMethod == "POST")
        XCTAssert(request?.httpBody == data)
    }
    
    func testQuery() {
        let request = RequestBuilder
            .GET("get-endpoint", baseURL: baseURL)
            .withQuery(["a": "1", "foobar": "!@#$%^&*()_+", "c": nil, "other_thing": "😡"])
            .request()

        XCTAssert(request != nil)
        XCTAssert(request!.httpMethod == "GET")
        XCTAssert(request!.url!.path == "/get-endpoint")
        let comps = URLComponents(url: request!.url!, resolvingAgainstBaseURL: false)!
        XCTAssert(comps.queryItems!.contains(URLQueryItem(name: "a", value: "1")))
        XCTAssert(comps.queryItems!.contains(URLQueryItem(name: "foobar", value: "!@#$%^&*()_+")))
        XCTAssert(comps.queryItems!.contains(URLQueryItem(name: "other_thing", value: "😡")))
    }

    func testRepeatedQuery() {
        let request = RequestBuilder
            .GET("get-endpoint", baseURL: baseURL)
            .withQuery(["a": "1"])
            .withQuery(["b": "2"])
            .request()
        
        XCTAssert(request != nil)
        XCTAssert(request!.httpMethod == "GET")
        XCTAssert(request!.url!.path == "/get-endpoint")
        let comps = URLComponents(url: request!.url!, resolvingAgainstBaseURL: false)!
        XCTAssert(comps.queryItems!.contains(URLQueryItem(name: "a", value: "1")))
        XCTAssert(comps.queryItems!.contains(URLQueryItem(name: "b", value: "2")))
    }

    func testQueryItems() {
        let request = RequestBuilder
            .GET("get-endpoint", baseURL: baseURL)
            .withQueryItems([URLQueryItem(name: "foo", value: "bar")])
            .request()
        
        XCTAssert(request != nil)
        XCTAssert(request!.httpMethod == "GET")
        XCTAssert(request!.url!.path == "/get-endpoint")
        let comps = URLComponents(url: request!.url!, resolvingAgainstBaseURL: false)!
        XCTAssert(comps.queryItems!.contains(URLQueryItem(name: "foo", value: "bar")))
    }

    
    func testBehaviorAddsHeaders() {
        let behaviour = AuthenticatingRequestBehavior(headerName: "Access-Token", value: "abc")
        let request = RequestBuilder
            .GET("get-endpoint", baseURL: baseURL)
            .withBehavior(behaviour)
            .request()
        
        XCTAssert(request != nil)
        XCTAssert(request!.allHTTPHeaderFields?["Access-Token"] == "abc")
    }
    
    func testBehaviorsAreAdded() {
        
        class RB1: RequestBehavior {}
        class RB2: RequestBehavior {}
        
        let request = RequestBuilder
            .GET("get-endpoint", baseURL: baseURL)
            .withBehavior(RB1())
            .withBehavior(RB2())
        
        let behavior = request.behavior as! CombinedRequestBehavior // implicit assert
        XCTAssert(behavior.behaviors.filter({ $0 as? RB1 != nil }).count == 1)
        XCTAssert(behavior.behaviors.filter({ $0 as? RB2 != nil }).count == 1)
    }
    
}
