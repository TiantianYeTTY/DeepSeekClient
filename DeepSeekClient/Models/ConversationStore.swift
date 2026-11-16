// Designed by TiantianYe
import Foundation
import SwiftUI

@MainActor
final class ConversationStore: ObservableObject {
    @Published private(set) var conversations: [Conversation] = []
    @Published var currentID: UUID?

    private let fileManager = FileManager.default
    private let fileURL: URL

    init() {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = documents.appendingPathComponent("conversations.json")
        load()

        if conversations.isEmpty {
            _ = createConversation()
        } else if currentID == nil || !conversations.contains(where: { $0.id == currentID }) {
            currentID = conversations.first?.id
        }
    }

    var currentConversation: Conversation? {
        conversations.first { $0.id == currentID }
    }

    func createConversation() -> Conversation {
        let conversation = Conversation()
        conversations.insert(conversation, at: 0)
        currentID = conversation.id
        save()
        return conversation
    }

    func select(_ id: UUID) {
        currentID = id
    }

    func delete(_ id: UUID) {
        conversations.removeAll { $0.id == id }
        if currentID == id {
            currentID = conversations.first?.id
        }
        if conversations.isEmpty {
            _ = createConversation()
        } else {
            save()
        }
    }

    func rename(_ id: UUID, to title: String) {
        guard let index = conversations.firstIndex(where: { $0.id == id }) else { return }
        conversations[index].title = title
        conversations[index].updatedAt = Date()
        save()
    }

    func appendMessage(_ message: ChatMessage, to id: UUID? = nil) {
        let targetID = id ?? currentID
        guard let index = conversations.firstIndex(where: { $0.id == targetID }) else { return }
        conversations[index].messages.append(message)
        conversations[index].updatedAt = Date()
        if conversations[index].messages.count == 1 && message.role == .user {
            let title = String(message.content.prefix(14))
            conversations[index].title = title.isEmpty ? "新对话" : title
        }
        save()
    }

    func updateMessage(_ messageID: UUID, in conversationID: UUID? = nil, transform: (inout ChatMessage) -> Void) {
        let targetID = conversationID ?? currentID
        guard let index = conversations.firstIndex(where: { $0.id == targetID }),
              let messageIndex = conversations[index].messages.firstIndex(where: { $0.id == messageID }) else {
            return
        }
        transform(&conversations[index].messages[messageIndex])
        conversations[index].updatedAt = Date()
    }

    func finishStreaming(in conversationID: UUID? = nil) {
        let targetID = conversationID ?? currentID
        guard let index = conversations.firstIndex(where: { $0.id == targetID }) else { return }
        for messageIndex in conversations[index].messages.indices {
            conversations[index].messages[messageIndex].isStreaming = false
        }
        save()
    }

    func clearAll() {
        conversations = []
        _ = createConversation()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([Conversation].self, from: data) else {
            return
        }
        conversations = decoded.sorted { $0.updatedAt > $1.updatedAt }
        currentID = conversations.first?.id
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(conversations) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
