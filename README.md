# RequestBuilder

Originally inspired by http://khanlou.com/2017/01/request-behaviors/  
Depends on and includes a copy of Soroush Khanlou’s lovely Promise library, see https://github.com/khanlou/Promise


## Usage example

```swift
let client = NetworkClient(baseURL: URL(string: "https://github.com")!, defaultRequestBehavior: JSONRequestBehavior())

client.GET("/foo")
  .withQuery(["foo" : "bar"])
  .sendRequest()
  .then({ result in
      return try JSONDecoder().decode(MyObject.self, from: result.data)
  }).then({ object in
    // do something with object
  }).catch { error in
      print("error: \(error)")
  }
```
