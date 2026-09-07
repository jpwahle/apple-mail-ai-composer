import Foundation
import XCTest
@testable import AIMailComposer

final class LocalAIAuthenticationTests: XCTestCase {
    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(LocalAIServerStub.self)
    }

    override func tearDown() {
        URLProtocol.unregisterClass(LocalAIServerStub.self)
        super.tearDown()
    }

    func testAuthenticatedServerSupportsModelLoadingAndStreaming() async throws {
        try await checkServer(host: "protected", apiKey: "test-secret")
    }

    func testPastedKeyIsTrimmedForBothRequests() async throws {
        try await checkServer(host: "protected", apiKey: " \n test-secret\t ")
    }

    func testPublicServerReceivesNoAuthorizationForAbsentOrBlankKeys() async throws {
        for key: String? in [nil, "", " \n\t "] {
            try await checkServer(host: "public", apiKey: key)
        }
    }

    func testDefaultArgumentsKeepUnauthenticatedServersWorking() async throws {
        let baseURL = "http://public.local-ai.invalid"
        let models = try await ModelFetcher.fetchLocalAIModels(baseURL: baseURL)
        XCTAssertEqual(models.map(\.id), ["test-model"])
        let reply = try await LocalAIClient(baseURL: baseURL, model: "test-model")
            .complete(systemPrompt: "Test", userMessage: "Hello")
        XCTAssertEqual(reply, "Hello there")
    }

    func testRemovingKeyDoesNotReusePreviousAuthorization() async throws {
        try await checkServer(host: "protected", apiKey: "test-secret")
        try await checkServer(host: "public", apiKey: "")
    }

    func testProtectedServerRejectsMissingOrIncorrectKeyForBothRequests() async {
        let baseURL = "https://protected.local-ai.invalid"
        for key: String? in [nil, "wrong-key"] {
            do {
                _ = try await ModelFetcher.fetchLocalAIModels(baseURL: baseURL, apiKey: key)
                XCTFail("Model loading should fail without the correct key")
            } catch {
                XCTAssertTrue(error.localizedDescription.contains("Unauthorized"))
            }
            do {
                _ = try await LocalAIClient(baseURL: baseURL, model: "test-model", apiKey: key)
                    .complete(systemPrompt: "Test", userMessage: "Hello")
                XCTFail("Streaming should fail without the correct key")
            } catch {
                XCTAssertTrue(error.localizedDescription.contains("HTTP 401"))
            }
        }
    }

    private func checkServer(host: String, apiKey: String?) async throws {
        // Also exercise a remote HTTPS URL, a path prefix, and a trailing slash.
        let baseURL = "https://\(host).local-ai.invalid/inference/"
        let models = try await ModelFetcher.fetchLocalAIModels(baseURL: baseURL, apiKey: apiKey)
        XCTAssertEqual(models.map(\.id), ["test-model"])
        XCTAssertEqual(models.first?.provider, .local)
        let reply = try await LocalAIClient(baseURL: baseURL, model: "test-model", apiKey: apiKey)
            .complete(systemPrompt: "Test", userMessage: "Hello")
        XCTAssertEqual(reply, "Hello there")
    }
}

/// Intercepts only these test hosts; no real server or credentials are used.
private final class LocalAIServerStub: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host?.hasSuffix(".local-ai.invalid") == true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url else { return }
        let expectedKey = url.host == "protected.local-ai.invalid" ? "Bearer test-secret" : nil
        let authorized = request.value(forHTTPHeaderField: "Authorization") == expectedKey
        let isModelRequest = request.httpMethod == "GET" && url.path.hasSuffix("/v1/models")
        let isChatRequest = request.httpMethod == "POST" && url.path.hasSuffix("/v1/chat/completions")
        let status = !authorized ? 401 : (isModelRequest || isChatRequest ? 200 : 404)
        let body: String
        if status != 200 {
            body = status == 401 ? "Unauthorized" : "Not found"
        } else if isModelRequest {
            body = #"{"data":[{"id":"test-model"}]}"#
        } else {
            body = "data: {\"choices\":[{\"delta\":{\"content\":\"Hello \"}}]}\n\n"
                + "data: {\"choices\":[{\"delta\":{\"content\":\"there\"}}]}\n\n"
                + "data: [DONE]\n\n"
        }
        let response = HTTPURLResponse(
            url: url, statusCode: status, httpVersion: nil,
            headerFields: ["Content-Type": isChatRequest ? "text/event-stream" : "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
