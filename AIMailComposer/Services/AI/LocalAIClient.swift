import Foundation

/// Client for local or remote OpenAI-compatible servers, including LM Studio,
/// Ollama, and vLLM. The base URL is configurable and the API key is optional.
final class LocalAIClient: AIClient {
    let provider = AIProvider.local
    private let baseURL: String
    private let model: String
    private let apiKey: String?

    init(baseURL: String, model: String, apiKey: String? = nil) {
        self.baseURL = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        self.model = model
        self.apiKey = apiKey?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func stream(systemPrompt: String, userMessage: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    guard let url = URL(string: "\(self.baseURL)/v1/chat/completions") else {
                        throw AIClientError.requestFailed("Invalid Local AI base URL: \(self.baseURL)")
                    }
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "content-type")
                    if let apiKey = self.apiKey, !apiKey.isEmpty {
                        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    }

                    let body: [String: Any] = [
                        "model": self.model,
                        "stream": true,
                        "messages": [
                            ["role": "system", "content": systemPrompt],
                            ["role": "user", "content": userMessage],
                        ],
                    ]
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)

                    guard let http = response as? HTTPURLResponse else {
                        throw AIClientError.requestFailed("No HTTP response")
                    }
                    guard http.statusCode == 200 else {
                        var errorBody = ""
                        for try await line in bytes.lines {
                            errorBody += line + "\n"
                            if errorBody.count > 1024 {
                                errorBody += "...[truncated]"
                                break
                            }
                        }
                        throw AIClientError.requestFailed("HTTP \(http.statusCode): \(errorBody)")
                    }

                    for try await line in bytes.lines {
                        try Task.checkCancellation()
                        switch OpenAICompatibleStream.parse(line: line) {
                        case .delta(let text): continuation.yield(text)
                        case .done: continuation.finish(); return
                        case .none: continue
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
