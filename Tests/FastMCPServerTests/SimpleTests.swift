import XCTest
@testable import FastMCPServer

final class SimpleTests: XCTestCase {
    
    func testSimpleFastMCPInitialization() {
        let server = SimpleFastMCP("Test Server", version: "1.0.0")
        XCTAssertEqual(server.name, "Test Server")
        XCTAssertEqual(server.version, "1.0.0")
    }
    
    func testSimpleFastMCPClientInitialization() {
        let client = SimpleFastMCPClient(name: "Test Client", version: "1.0.0")
        XCTAssertNotNil(client)
    }
}