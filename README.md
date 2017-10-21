# RequestBuilder

Originally inspired by http://khanlou.com/2017/01/request-behaviors/  
Depends on and includes a copy of Soroush Khanlou’s lovely Promise library, see https://github.com/khanlou/Promise


## Usage

```swift
    let client = NetworkClient(baseURL: URL(string: "https://github.com")!)        
    client.GET("/foo")
        .withQuery(["foo" : "bar"])
        .sendJSONRequest()
        .then({ json in
            guard let json = json as? Dictionary<String, String> else {
                throw NetworkClientError.InvalidJSON
            }
            
            // ... maybe do something with the JSON?
        })
```
