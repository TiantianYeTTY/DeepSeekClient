// Designed by TiantianYe
import Foundation

enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    var role: MessageRole
    var content: String
    var reasoning: String?
    var imageData: Data?
    var attachmentName: String?
    var attachmentText: String?
    var isStreaming: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String = "",
        reasoning: String? = nil,
        imageData: Data? = nil,
        attachmentName: String? = nil,
        attachmentText: String? = nil,
        isStreaming: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.reasoning = reasoning
        self.imageData = imageData
        self.attachmentName = attachmentName
        self.attachmentText = attachmentText
        self.isStreaming = isStreaming
        self.createdAt = createdAt
    }
}

struct Conversation: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var messages: [ChatMessage]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String = "新对话",
        messages: [ChatMessage] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var preview: String {
        messages.last(where: { $0.role == .user })?.content ?? "暂无消息"
    }
}
