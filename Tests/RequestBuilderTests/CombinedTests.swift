import XCTest
import RequestBuilder

class CombinedTests: XCTestCase {

    static let baseURLString = "https://api.soryu2.net"
    let baseURL = URL(string: baseURLString)!

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testHelloWorld() {
        let exp = expectation(description: "")
        let mockSession = helloWorldJSONSession()
        
        let client = NetworkClient(baseURL: baseURL,
                                   session: mockSession)
        
        client.GET("hello")
            .sendJSONRequest()
            .then({ json in
                if let json = json as? [String: Any] {
                    XCTAssert(json["answer"] as? String == "Hello, World!")
                } else {
                    XCTFail()
                }
                exp.fulfill()
            }).catch({ error in
                print("Error: \(error)")
                XCTFail()
                exp.fulfill()
            })
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
}

func helloWorldJSONSession() -> MockURLSession {
    let error: Error? = nil
    let data          = "{ \"answer\": \"Hello, World!\" }".data(using: .utf8)
    let statusCode    = 200
    let response      = HTTPURLResponse(url: URL(string: "https://mock")!,
                                        statusCode: statusCode,
                                        httpVersion: nil,
                                        headerFields: [:])
    
    return MockURLSession(data: data, response: response, error: error)
}
