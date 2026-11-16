// Designed by TiantianYe
import XCTest
@testable import DeepSeekClient

final class ChatServiceTests: XCTestCase {
    /// 验证服务商把首块发成 "\n\n" 时不会产生前导空行（纯函数，不依赖网络）
    func testLeadingBlankChunksAreTrimmed() {
        let first = trimmedStreamChunk("\n\n", started: false)
        XCTAssertFalse(first.shouldEmit, "纯空白首块不应输出")
        XCTAssertFalse(first.started, "纯空白首块不应标记为已开始")

        let second = trimmedStreamChunk("\n你好", started: first.started)
        XCTAssertTrue(second.shouldEmit, "首块实际文字应输出")
        XCTAssertEqual(second.text, "你好", "应去掉开头换行")
        XCTAssertTrue(second.started)

        let third = trimmedStreamChunk("，这是模拟流式回复。", started: second.started)
        XCTAssertEqual(third.text, "，这是模拟流式回复。", "后续块应原样保留")

        let combined = second.text + third.text
        XCTAssertFalse(combined.hasPrefix("\n"))
        XCTAssertEqual(combined, "你好，这是模拟流式回复。")
    }

    /// 验证「深度思考 / 智能搜索」两个开关真实改变请求体
    func testModeTogglesChangeRequestBody() {
        let configuration = APIConfiguration(
            baseURL: "https://example.com/v1",
            model: "chat-model",
            reasonerModel: "reasoner-model"
        )
        let messages = [ChatMessage(role: .user, content: "你好")]

        let plain = ChatService.makeRequestBody(
            configuration: configuration,
            messages: messages,
            deepThinking: false,
            webSearch: false
        )
        XCTAssertEqual(plain["model"] as? String, "chat-model")
        XCTAssertNil(plain["web_search"], "关闭智能搜索时不应带 web_search")

        let thinking = ChatService.makeRequestBody(
            configuration: configuration,
            messages: messages,
            deepThinking: true,
            webSearch: false
        )
        XCTAssertEqual(thinking["model"] as? String, "reasoner-model", "深度思考应切换模型")

        let searching = ChatService.makeRequestBody(
            configuration: configuration,
            messages: messages,
            deepThinking: false,
            webSearch: true
        )
        XCTAssertEqual(searching["web_search"] as? Bool, true, "智能搜索应带 web_search 参数")
    }

    /// 验证图片附件会以多模态 image_url 格式进入请求体
    func testImageAttachmentBuildsMultimodalContent() {
        let configuration = APIConfiguration(
            baseURL: "https://example.com/v1",
            model: "chat-model",
            reasonerModel: "reasoner-model"
        )
        let imageMessage = ChatMessage(
            role: .user,
            content: "这是什么",
            imageData: Data([0x01, 0x02, 0x03])
        )
        let body = ChatService.makeRequestBody(
            configuration: configuration,
            messages: [imageMessage],
            deepThinking: false,
            webSearch: false
        )
        let messages = body["messages"] as? [[String: Any]]
        let content = messages?.first?["content"] as? [[String: Any]]
        XCTAssertNotNil(content, "带图片时 content 应为多模态数组")
        XCTAssertEqual(content?.first?["type"] as? String, "text")
        XCTAssertEqual(content?.last?["type"] as? String, "image_url")
        let imageURL = (content?.last?["image_url"] as? [String: Any])?["url"] as? String
        XCTAssertTrue(imageURL?.hasPrefix("data:image/jpeg;base64,") == true)
    }
}
