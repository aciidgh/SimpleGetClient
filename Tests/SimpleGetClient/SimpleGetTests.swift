@testable import SimpleGetClient
import XCTest

class SimpleGetTests: XCTestCase {

    let client = GetClient()

    func testGetRequestWithOneArg() {   
        
        let result = client.fetch("http://httpbin.org/get?a=b")
        guard case let json as NSDictionary = try? NSJSONSerialization.JSONObjectWithData((result.response as NSString).dataUsingEncoding(NSUTF8StringEncoding)!, options: NSJSONReadingOptions.AllowFragments) else {
            XCTFail("Couldn't parse data")
            return
        }
        
        XCTAssertEqual(json["args"]?["a"], "b", "Incorrect value received from server")
    }
    
    func testGetRequestStatusCode() {
        let result = client.fetch("http://httpbin.org/status/419")
        XCTAssertEqual(result.responseCode, "419", "Incorrect value received from server")
    }
}