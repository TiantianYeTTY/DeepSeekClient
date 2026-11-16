// Designed by TiantianYe
import Foundation

enum StreamChunk {
    case content(String)
    case reasoning(String)
}

/// 流式文本块修剪：在正式内容出现前跳过纯空白块（服务商常把首块发成 "\n\n"）。
/// 提取为纯函数便于单元测试，避免依赖网络。
/// - Parameters:
///   - chunk: 当前文本块
///   - started: 之前是否已输出过实际内容
/// - Returns: (是否输出, 输出内容, 更新后的 started)
func trimmedStreamChunk(_ chunk: String, started: Bool) -> (shouldEmit: Bool, text: String, started: Bool) {
    if chunk.isEmpty { return (false, "", started) }
    if started { return (true, chunk, true) }

    let leadingTrimmed = String(chunk.drop(while: { $0.isWhitespace }))
    if leadingTrimmed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        return (false, "", false)
    }
    return (true, leadingTrimmed, true)
}

enum APIError: LocalizedError {
    case invalidURL
    case missingAPIKey
    case http(status: Int, body: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "API 地址无效，请检查设置中的 Base URL。"
        case .missingAPIKey:
            return "尚未填写 API Key，请在「设置 → 账号管理」中配置。"
        case .http(let status, let body):
            let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
            let preview = String(trimmed.prefix(400))
            return "API 请求失败（HTTP \(status)）：\(preview.isEmpty ? "无响应内容" : preview)"
        }
    }
}

final class ChatService {
    static let shared = ChatService()

    /// 构建请求体（提取为纯函数，便于单元测试验证两个开关确实生效）
    static func makeRequestBody(
        configuration: APIConfiguration,
        messages: [ChatMessage],
        deepThinking: Bool,
        webSearch: Bool
    ) -> [String: Any] {
        let payloadMessages: [[String: Any]] = messages.map { message in
            var payload: [String: Any] = [
                "role": message.role.rawValue
            ]

            if message.role == .user, let imageData = message.imageData {
                // 多模态：文本 + base64 图片（OpenAI 兼容 image_url 格式）
                var parts: [[String: Any]] = []
                let text = message.content.isEmpty ? "请描述这张图片" : message.content
                parts.append(["type": "text", "text": text])
                let base64 = imageData.base64EncodedString()
                parts.append([
                    "type": "image_url",
                    "image_url": ["url": "data:image/jpeg;base64,\(base64)"]
                ])
                payload["content"] = parts
            } else {
                var text = message.content
                if let name = message.attachmentName, let attachment = message.attachmentText {
                    let block = "[附件：\(name)]\n\(attachment)"
                    text = text.isEmpty ? block : "\(text)\n\n\(block)"
                }
                payload["content"] = text
            }

            if message.role == .assistant, let reasoning = message.reasoning, !reasoning.isEmpty {
                payload["reasoning_content"] = reasoning
            }
            return payload
        }

        var body: [String: Any] = [
            "model": deepThinking ? configuration.reasonerModel : configuration.model,
            "messages": payloadMessages,
            "stream": true
        ]
        if webSearch {
            body["web_search"] = true
        }
        return body
    }

    func stream(
        configuration: APIConfiguration,
        apiKey: String,
        messages: [ChatMessage],
        deepThinking: Bool,
        webSearch: Bool
    ) -> AsyncThrowingStream<StreamChunk, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    try await perform(
                        configuration: configuration,
                        apiKey: apiKey,
                        messages: messages,
                        deepThinking: deepThinking,
                        webSearch: webSearch,
                        continuation: continuation
                    )
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    private func perform(
        configuration: APIConfiguration,
        apiKey: String,
        messages: [ChatMessage],
        deepThinking: Bool,
        webSearch: Bool,
        continuation: AsyncThrowingStream<StreamChunk, Error>.Continuation
    ) async throws {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { throw APIError.missingAPIKey }

        let base = configuration.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: base + "/chat/completions") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = Self.makeRequestBody(
            configuration: configuration,
            messages: messages,
            deepThinking: deepThinking,
            webSearch: webSearch
        )
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 120

        let (bytes, response) = try await URLSession.shared.bytes(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.http(status: -1, body: "无效响应")
        }

        guard http.statusCode == 200 else {
            var data = Data()
            for try await byte in bytes {
                data.append(byte)
            }
            let text = String(data: data, encoding: .utf8) ?? ""
            throw APIError.http(status: http.statusCode, body: text)
        }

        // 部分服务商会把正文首块发成 "\n\n"，
        // 在正式文字出现前跳过纯空白块，避免气泡首行空一行。
        var contentStarted = false
        var reasoningStarted = false

        for try await line in bytes.lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("data:") else { continue }

            let payload = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespaces)
            if payload == "[DONE]" { break }
            guard let data = payload.data(using: .utf8),
                  let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = object["choices"] as? [[String: Any]],
                  let first = choices.first,
                  let delta = first["delta"] as? [String: Any] else {
                continue
            }

            if let reasoning = delta["reasoning_content"] as? String {
                let result = trimmedStreamChunk(reasoning, started: reasoningStarted)
                reasoningStarted = result.started
                if result.shouldEmit { continuation.yield(.reasoning(result.text)) }
            }

            if let content = delta["content"] as? String {
                let result = trimmedStreamChunk(content, started: contentStarted)
                contentStarted = result.started
                if result.shouldEmit { continuation.yield(.content(result.text)) }
            }
        }
    }
}
