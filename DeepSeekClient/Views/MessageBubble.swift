// Designed by TiantianYe
import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage
    @State private var showReasoning = false

    private var isUser: Bool { message.role == .user }
    private var bubbleWidth: CGFloat { UIScreen.main.bounds.width * 0.78 }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if isUser { Spacer(minLength: 24) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 8) {
                if !isUser, let reasoning = message.reasoning, !reasoning.isEmpty {
                    DisclosureGroup(isExpanded: $showReasoning) {
                        Text(reasoning)
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } label: {
                        Label("已深度思考", systemImage: "brain")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(uiColor: .secondarySystemBackground))
                    }
                }

                if message.content.isEmpty {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.75)
                        Text("正在思考…")
                            .font(.system(size: 17))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(uiColor: .secondarySystemBackground))
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        if let imageData = message.imageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 220, maxHeight: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        if let name = message.attachmentName {
                            Label(name, systemImage: "doc.text")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                        Text(message.content)
                            .font(.system(size: 17))
                            .textSelection(.enabled)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(isUser ? Color.accentColor.opacity(0.14) : Color(uiColor: .secondarySystemBackground))
                    }
                }
            }
            .frame(maxWidth: bubbleWidth, alignment: isUser ? .trailing : .leading)

            if !isUser { Spacer(minLength: 24) }
        }
        .contextMenu {
            Button {
                UIPasteboard.general.string = message.content
            } label: {
                Label("复制内容", systemImage: "doc.on.doc")
            }
        }
    }
}
