import XCTest
import RequestBuilder

struct MyObject: Codable {
    var a: String
}

class JSONTests: XCTestCase {

    let testURL = URL(string: "https://json-api.soryu2.net")!

    func testJSONManual() {
        let exp = expectation(description: "")
        let testJSONData = "{\"a\":\"b\"}".data(using: .utf8)!

        let mockSession = VerifyingURLSession() { request in
            XCTAssertEqual(request.httpBody, "{\"a\":\"b\"}".data(using: .utf8))

            let headers = request.allHTTPHeaderFields!
            XCTAssertEqual(headers.count, 2)
            XCTAssertEqual(headers["Content-Type"], "application/json")
            XCTAssertEqual(headers["Accept"], "application/json")

            return response(to: request, data: testJSONData)
        }

        let client = NetworkClient(baseURL: testURL, session: mockSession)

        client.POST("/foo", data: "{\"a\":\"b\"}".data(using: .utf8))
            .withHeader(key: "Content-Type", value: "application/json")
            .withHeader(key: "Accept", value: "application/json")
            .sendRequest()
            .then({ result in // data -> JSON Object
                return try JSONSerialization.jsonObject(with: result.data)
            }).then({ json in // JSON Object check
                guard let json = json as? Dictionary<String, String> else {
                    throw NetworkClientError.InvalidResponse
                }
                XCTAssertEqual(json, ["a": "b"])
                exp.fulfill()
            }).catch { error in
                XCTFail()
                print("error: \(error)")
                exp.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }


    func testJSONCodable() {
        let exp = expectation(description: "")

        let testJSONData = "{\"a\":\"b\"}".data(using: .utf8)!

        let mockSession = VerifyingURLSession() { request in
            XCTAssertEqual(request.httpBody, testJSONData)

            let headers = request.allHTTPHeaderFields!
            XCTAssertEqual(headers.count, 2)
            XCTAssertEqual(headers["Content-Type"], "application/json")
            XCTAssertEqual(headers["Accept"], "application/json")

            return response(to: request, data: testJSONData)
        }

        let jsonClient = NetworkClient(baseURL: testURL, session: mockSession, defaultRequestBehavior: JSONRequestBehavior())

        let encoder = JSONEncoder()
        jsonClient.POST("/foo", data: try! encoder.encode(MyObject(a: "b")))
            .sendRequest()
            .then({ result in // data -> JSON Object
                return try JSONDecoder().decode(MyObject.self, from: result.data)
            }).then({ obj in
                XCTAssertEqual(obj.a, "b")
                exp.fulfill()
            }).catch { error in
                print("error: \(error)")
                exp.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

}
