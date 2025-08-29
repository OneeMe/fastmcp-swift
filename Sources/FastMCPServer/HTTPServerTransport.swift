import Foundation
import MCP
import Logging
#if canImport(Network)
import Network
#endif

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// HTTP streaming server transport for MCP
/// 
/// This transport implements the server side of the MCP Streamable HTTP transport protocol.
/// It creates an HTTP server that can accept connections from MCP clients using HTTPClientTransport.
///
/// The transport supports:
/// - HTTP POST requests with JSON-RPC messages
/// - Server-Sent Events (SSE) for streaming responses
/// - Session management using Mcp-Session-Id headers
/// - CORS headers for web browser support
public actor HTTPServerTransport: Transport {
    public nonisolated let logger: Logger
    
    private let host: String
    private let port: Int
    private let path: String
    
    private var isConnected = false
    private var sessions: [String: Session] = [:]
    
    private let messageStream: AsyncThrowingStream<Data, Swift.Error>
    private let messageContinuation: AsyncThrowingStream<Data, Swift.Error>.Continuation
    
    #if canImport(Network)
    private var listener: NWListener?
    #else
    // For platforms without Network framework, we'll need to use URLProtocol or other mechanisms
    #endif
    
    /// Session information for connected clients
    private struct Session {
        let id: String
        let createdAt: Date
        var sseConnection: SSEConnection?
        
        struct SSEConnection {
            let continuation: AsyncThrowingStream<Data, Swift.Error>.Continuation
            let task: Task<Void, Never>
        }
    }
    
    /// Initialize the HTTP server transport
    /// - Parameters:
    ///   - host: Host to bind to (default: "127.0.0.1")
    ///   - port: Port to listen on (default: 8000)  
    ///   - path: HTTP path for MCP endpoint (default: "/mcp")
    ///   - logger: Optional logger instance
    public init(
        host: String = "127.0.0.1",
        port: Int = 8000,
        path: String = "/mcp",
        logger: Logger? = nil
    ) {
        self.host = host
        self.port = port
        self.path = path
        self.logger = logger ?? Logger(label: "mcp.transport.http.server")
        
        var continuation: AsyncThrowingStream<Data, Swift.Error>.Continuation!
        self.messageStream = AsyncThrowingStream { continuation = $0 }
        self.messageContinuation = continuation
    }
    
    public func connect() async throws {
        #if canImport(Network)
        guard !isConnected else { return }
        
        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true
        
        // Create and start listener
        listener = try NWListener(using: parameters, on: NWEndpoint.Port(integerLiteral: UInt16(port)))
        
        listener?.newConnectionHandler = { [weak self] connection in
            Task { [weak self] in
                await self?.handleConnection(connection)
            }
        }
        
        listener?.stateUpdateHandler = { [weak self] state in
            Task { [weak self] in
                await self?.handleListenerState(state)
            }
        }
        
        listener?.start(queue: .main)
        isConnected = true
        
        await logger.info("HTTP server started", metadata: [
            "host": "\(host)",
            "port": "\(port)",
            "path": "\(path)"
        ])
        #else
        throw MCPError.internalError("Network framework not available on this platform")
        #endif
    }
    
    public func disconnect() async {
        #if canImport(Network)
        guard isConnected else { return }
        
        listener?.cancel()
        listener = nil
        isConnected = false
        
        // Clean up sessions
        for session in sessions.values {
            session.sseConnection?.task.cancel()
        }
        sessions.removeAll()
        
        messageContinuation.finish()
        await logger.info("HTTP server stopped")
        #endif
    }
    
    public func send(_ data: Data) async throws {
        // This method is called by the MCP Server to send responses back
        // We need to parse the response and deliver it to the waiting HTTP client
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let id = json["id"] {
                
                let requestId: String
                if let stringId = id as? String {
                    requestId = stringId
                } else if let intId = id as? Int {
                    requestId = String(intId)
                } else {
                    return // Invalid ID format
                }
                
                // Find and resume the waiting continuation
                let continuation = resolvePendingResponse(id: requestId)
                
                if let continuation = continuation {
                    continuation.resume(returning: data)
                }
            }
        } catch {
            await logger.error("Failed to parse response from MCP server", metadata: ["error": "\(error)"])
        }
    }
    
    public func receive() -> AsyncThrowingStream<Data, Swift.Error> {
        return messageStream
    }
    
    #if canImport(Network)
    private func handleListenerState(_ state: NWListener.State) async {
        switch state {
        case .ready:
            await logger.debug("HTTP listener is ready")
        case .failed(let error):
            await logger.error("HTTP listener failed", metadata: ["error": "\(error)"])
        case .cancelled:
            await logger.debug("HTTP listener cancelled")
        default:
            break
        }
    }
    
    private func handleConnection(_ connection: NWConnection) async {
        connection.stateUpdateHandler = { [weak self] state in
            Task { [weak self] in
                await self?.handleConnectionState(connection, state: state)
            }
        }
        
        connection.start(queue: .main)
        
        // Start receiving HTTP data
        await receiveHTTPData(from: connection)
    }
    
    private func handleConnectionState(_ connection: NWConnection, state: NWConnection.State) async {
        switch state {
        case .ready:
            await logger.debug("HTTP connection established")
        case .failed(let error):
            await logger.error("HTTP connection failed", metadata: ["error": "\(error)"])
        case .cancelled:
            await logger.debug("HTTP connection cancelled")
        default:
            break
        }
    }
    
    private func receiveHTTPData(from connection: NWConnection) async {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            Task { [weak self] in
                if let data = data, !data.isEmpty {
                    await self?.processHTTPRequest(data: data, connection: connection)
                }
                
                if !isComplete {
                    await self?.receiveHTTPData(from: connection)
                }
                
                if let error = error {
                    // 常见的连接取消（如客户端主动断开）会以 ECANCELED/posix 89 呈现，降级为 debug 以免噪声
                    let nsError = error as NSError
                    if nsError.domain == NSPOSIXErrorDomain && nsError.code == Int(ECANCELED) {
                        await self?.logger.debug("HTTP receive canceled", metadata: ["error": "\(error)"])
                    } else if error.localizedDescription.contains("Operation canceled") {
                        await self?.logger.debug("HTTP receive canceled", metadata: ["error": "\(error)"])
                    } else {
                        await self?.logger.error("HTTP receive error", metadata: ["error": "\(error)"])
                    }
                }
            }
        }
    }
    
    private func processHTTPRequest(data: Data, connection: NWConnection) async {
        // Parse HTTP request
        guard let requestString = String(data: data, encoding: .utf8) else {
            await sendHTTPResponse(connection: connection, status: 400, body: "Bad Request")
            return
        }
        
        let lines = requestString.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else {
            await sendHTTPResponse(connection: connection, status: 400, body: "Bad Request")
            return
        }
        
        let requestParts = requestLine.components(separatedBy: " ")
        guard requestParts.count >= 3 else {
            await sendHTTPResponse(connection: connection, status: 400, body: "Bad Request") 
            return
        }
        
        let method = requestParts[0]
        let requestPath = requestParts[1]
        
        // Check if this is a request to our MCP path
        guard requestPath == path else {
            await sendHTTPResponse(connection: connection, status: 404, body: "Not Found")
            return
        }
        
        // Parse headers
        var headers: [String: String] = [:]
        var bodyStartIndex = 0
        
        for (index, line) in lines.enumerated() {
            if line.isEmpty {
                bodyStartIndex = index + 1
                break
            }
            if index > 0, let colonIndex = line.firstIndex(of: ":") {
                let key = String(line[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                let value = String(line[line.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                headers[key.lowercased()] = value
            }
        }
        
        // Handle different HTTP methods
        switch method {
        case "POST":
            await handlePOSTRequest(headers: headers, body: extractHTTPBody(from: lines, startIndex: bodyStartIndex), connection: connection)
        case "GET":
            await handleGETRequest(headers: headers, connection: connection)
        case "OPTIONS":
            await handleOPTIONSRequest(connection: connection)
        default:
            await sendHTTPResponse(connection: connection, status: 405, body: "Method Not Allowed")
        }
    }
    
    private func extractHTTPBody(from lines: [String], startIndex: Int) -> Data? {
        guard startIndex < lines.count else { return nil }
        let bodyLines = Array(lines[startIndex...])
        let bodyString = bodyLines.joined(separator: "\r\n")
        return bodyString.data(using: .utf8)
    }
    
    private var pendingResponses: [String: CheckedContinuation<Data, Swift.Error>] = [:]
    
    private func storePendingResponse(id: String, continuation: CheckedContinuation<Data, Swift.Error>) {
        pendingResponses[id] = continuation
    }
    
    private func resolvePendingResponse(id: String) -> CheckedContinuation<Data, Swift.Error>? {
        return pendingResponses.removeValue(forKey: id)
    }
    
    private func handlePOSTRequest(headers: [String: String], body: Data?, connection: NWConnection) async {
        guard let body = body, !body.isEmpty else {
            await sendHTTPResponse(connection: connection, status: 400, body: "Missing request body")
            return
        }
        
        // Parse the JSON-RPC request to extract the ID
        let requestId: String
        do {
            if let json = try JSONSerialization.jsonObject(with: body) as? [String: Any],
               let id = json["id"] {
                if let stringId = id as? String {
                    requestId = stringId
                } else if let intId = id as? Int {
                    requestId = String(intId)
                } else {
                    requestId = UUID().uuidString
                }
            } else {
                requestId = UUID().uuidString
            }
        } catch {
            await sendHTTPResponse(connection: connection, status: 400, body: "Invalid JSON")
            return
        }
        
        // Get or create session
        let sessionId = headers["mcp-session-id"] ?? UUID().uuidString
        if sessions[sessionId] == nil {
            sessions[sessionId] = Session(id: sessionId, createdAt: Date())
        }
        
        // Send HTTP headers immediately to prevent timeout
        let responseHeaders = [
            "Content-Type: application/json",
            "Access-Control-Allow-Origin: *", 
            "Access-Control-Allow-Headers: Content-Type, Accept, Mcp-Session-Id",
            "Mcp-Session-Id: \(sessionId)",
            "Transfer-Encoding: chunked",
            "Connection: keep-alive"
        ]
        
        let headerResponse = "HTTP/1.1 200 OK\r\n" +
            responseHeaders.joined(separator: "\r\n") + "\r\n\r\n"
        
        if let headerData = headerResponse.data(using: .utf8) {
            connection.send(content: headerData, completion: .idempotent)
        }
        
        // Forward the JSON-RPC message to the MCP server and wait for response
        do {
            let responseData = try await withCheckedThrowingContinuation { continuation in
                storePendingResponse(id: requestId, continuation: continuation)
                
                // Forward to MCP server
                messageContinuation.yield(body)
            }
            
            // Send the response body as a chunked response
            await sendChunkedResponse(connection: connection, data: responseData)
            
        } catch {
            // Send error response as a chunk
            let errorResponse: [String: Any] = [
                "jsonrpc": "2.0",
                "id": requestId,
                "error": [
                    "code": -32603,
                    "message": "Internal error: \(error.localizedDescription)"
                ]
            ]
            
            do {
                let errorData = try JSONSerialization.data(withJSONObject: errorResponse)
                await sendChunkedResponse(connection: connection, data: errorData)
            } catch {
                await logger.error("Failed to serialize error response", metadata: ["error": "\(error)"])
                await sendChunkedResponse(connection: connection, data: "Internal Server Error".data(using: .utf8)!)
            }
        }
    }
    
    private func handleGETRequest(headers: [String: String], connection: NWConnection) async {
        let accept = headers["accept"] ?? ""
        
        if accept.contains("text/event-stream") {
            // Client wants SSE stream
            let sessionId = headers["mcp-session-id"] ?? UUID().uuidString
            await handleSSEConnection(sessionId: sessionId, connection: connection)
        } else {
            await sendHTTPResponse(connection: connection, status: 200, body: "FastMCP HTTP Server")
        }
    }
    
    private func handleOPTIONSRequest(connection: NWConnection) async {
        let corsHeaders = [
            "Access-Control-Allow-Origin: *",
            "Access-Control-Allow-Methods: GET, POST, OPTIONS",
            "Access-Control-Allow-Headers: Content-Type, Accept, Mcp-Session-Id",
            "Access-Control-Max-Age: 86400"
        ]
        
        await sendHTTPResponse(connection: connection, status: 200, body: "", additionalHeaders: corsHeaders)
    }
    
    private func handleSSEConnection(sessionId: String, connection: NWConnection) async {
        // Set up SSE connection
        if sessions[sessionId] == nil {
            sessions[sessionId] = Session(id: sessionId, createdAt: Date())
        }
        
        let sseHeaders = [
            "Content-Type: text/event-stream",
            "Cache-Control: no-cache",
            "Connection: keep-alive",
            "Access-Control-Allow-Origin: *",
            "Access-Control-Allow-Headers: Content-Type, Accept, Mcp-Session-Id",
            "Mcp-Session-Id: \(sessionId)"
        ]
        
        // Send SSE response headers
        let responseHeader = "HTTP/1.1 200 OK\r\n" +
            sseHeaders.joined(separator: "\r\n") + "\r\n\r\n"
        
        let responseData = responseHeader.data(using: .utf8)!
        connection.send(content: responseData, completion: .idempotent)
        
        // Send initial SSE event
        let initialEvent = "data: {\"type\":\"connection_established\",\"sessionId\":\"\(sessionId)\"}\n\n"
        let initialEventData = initialEvent.data(using: .utf8)!
        connection.send(content: initialEventData, completion: .idempotent)
        
        await logger.debug("SSE connection established", metadata: ["sessionId": "\(sessionId)"])
    }
    
    private func sendJSONDataResponse(connection: NWConnection, sessionId: String, data: Data) async {
        let headers = [
            "Content-Type: application/json",
            "Access-Control-Allow-Origin: *", 
            "Access-Control-Allow-Headers: Content-Type, Accept, Mcp-Session-Id",
            "Mcp-Session-Id: \(sessionId)"
        ]
        
        let responseString = String(data: data, encoding: .utf8) ?? ""
        await sendHTTPResponse(connection: connection, status: 200, body: responseString, additionalHeaders: headers)
    }
    
    private func sendJSONResponse(connection: NWConnection, sessionId: String, body: [String: Any]) async {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body)
            await sendJSONDataResponse(connection: connection, sessionId: sessionId, data: jsonData)
        } catch {
            await logger.error("Failed to serialize JSON response", metadata: ["error": "\(error)"])
            await sendHTTPResponse(connection: connection, status: 500, body: "Internal Server Error")
        }
    }
    
    private func sendChunkedResponse(connection: NWConnection, data: Data) async {
        // Send the data as a single HTTP chunk
        let hexSize = String(data.count, radix: 16).uppercased()
        let chunkHeader = "\(hexSize)\r\n"
        let chunkTrailer = "\r\n"
        let endChunk = "0\r\n\r\n"
        
        // Send chunk header
        if let headerData = chunkHeader.data(using: .utf8) {
            connection.send(content: headerData, completion: .idempotent)
        }
        
        // Send chunk data  
        connection.send(content: data, completion: .idempotent)
        
        // Send chunk trailer
        if let trailerData = chunkTrailer.data(using: .utf8) {
            connection.send(content: trailerData, completion: .idempotent)
        }
        
        // Send end chunk and close connection
        if let endData = endChunk.data(using: .utf8) {
            connection.send(content: endData, completion: .contentProcessed { error in
                if let error = error {
                    Task { [weak self] in
                        await self?.logger.error("Failed to send chunked response", metadata: ["error": "\(error)"])
                    }
                }
                connection.cancel()
            })
        }
    }
    
    private func sendHTTPResponse(connection: NWConnection, status: Int, body: String, additionalHeaders: [String] = []) async {
        let statusText = HTTPURLResponse.localizedString(forStatusCode: status)
        let contentLength = body.utf8.count
        
        var headers = [
            "Content-Length: \(contentLength)",
            "Connection: close"
        ]
        headers.append(contentsOf: additionalHeaders)
        
        let response = "HTTP/1.1 \(status) \(statusText)\r\n" +
            headers.joined(separator: "\r\n") + "\r\n\r\n" +
            body
        
        if let responseData = response.data(using: .utf8) {
            connection.send(content: responseData, completion: .contentProcessed { error in
                if let error = error {
                    Task { [weak self] in
                        await self?.logger.error("Failed to send response", metadata: ["error": "\(error)"])
                    }
                }
                connection.cancel()
            })
        }
    }
    #endif
}
