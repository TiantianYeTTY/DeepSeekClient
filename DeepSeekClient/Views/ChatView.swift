// Designed by TiantianYe
import SwiftUI
import AVFoundation

struct ChatView: View {
    @EnvironmentObject private var store: ConversationStore
    @EnvironmentObject private var preferences: AppPreferences
    @Binding var showSidebar: Bool
    @Binding var showSettings: Bool

    @State private var inputText = ""
    @State private var deepThinking = false
    @State private var webSearch = false
    @State private var isSending = false
    @State private var alertMessage: String?
    @State private var pendingImage: Data?
    @State private var pendingAttachmentName: String?
    @State private var pendingAttachmentText: String?
    @State private var showingPhotoPicker = false
    @State private var showingCamera = false
    @State private var showingDocumentPicker = false
    @State private var speechEnabled = false
    @State private var attachmentsExpanded = false
    @Namespace private var glassNamespace

    private let synthesizer = AVSpeechSynthesizer()

    private var messages: [ChatMessage] { store.currentConversation?.messages ?? [] }
    private var hasMessages: Bool { !messages.isEmpty }
    private var messageCount: Int { messages.count }
    private var lastContent: String { messages.last?.content ?? "" }
    private var hasAttachment: Bool { pendingImage != nil || pendingAttachmentName != nil }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11: return "早上好，有什么我能帮你的吗?"
        case 11..<13: return "中午好，有什么我能帮你的吗?"
        case 13..<18: return "下午好，有什么我能帮你的吗?"
        default: return "晚上好，有什么我能帮你的吗?"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            if hasMessages {
                messageScrollView
            } else {
                Spacer(minLength: 0)
                hero
                Spacer(minLength: 0)
            }

            composer
        }
        // 点击输入框及附件按钮以外的任意区域收起键盘（作用于整个内容区）
        .contentShape(Rectangle())
        .onTapGesture { dismissKeyboard() }
        .alert(
            "无法发送",
            isPresented: Binding(
                get: { alertMessage != nil },
                set: { if !$0 { alertMessage = nil } }
            )
        ) {
            Button("取消", role: .cancel) { alertMessage = nil }
            Button("去配置") {
                showSettings = true
                alertMessage = nil
            }
        } message: {
            Text(alertMessage ?? "")
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoLibraryPicker { data in
                pendingImage = data
                pendingAttachmentName = nil
                pendingAttachmentText = nil
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraPicker { data in
                pendingImage = data
                pendingAttachmentName = nil
                pendingAttachmentText = nil
            }
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker { name, text in
                pendingAttachmentName = name
                pendingAttachmentText = text
                pendingImage = nil
            }
        }
    }

    /// 原版右上角设计：一个玻璃胶囊内「静音 + 新建会话」两个按钮
    private var header: some View {
        HStack {
            GlassIconButton(symbol: "line.horizontal.3", accessibilityLabelText: "打开对话列表") {
                showSidebar = true
            }
            .appGlassID("menu", in: glassNamespace)

            Spacer()

            // 单个融合胶囊（与参考图一致）：原生 glass 效果 + 内部两个图标按钮
            HStack(spacing: 0) {
                Button {
                    speechEnabled.toggle()
                    if !speechEnabled { synthesizer.stopSpeaking(at: .immediate) }
                } label: {
                    Image(systemName: speechEnabled ? "speaker.wave.2" : "speaker.slash")
                        .font(.system(size: 17, weight: .medium))
                        .frame(width: 38, height: 34)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(speechEnabled ? "关闭朗读" : "开启朗读")

                Rectangle()
                    .fill(Color.primary.opacity(0.12))
                    .frame(width: 1, height: 18)

                Button {
                    _ = store.createConversation()
                    dismissKeyboard()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 38, height: 34)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("新建会话")
            }
            .appGlassCard(cornerRadius: 20)
            .fixedSize()
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    private var hero: some View {
        Text(greeting)
            .font(.system(size: 27, weight: .bold))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
    }

    private var messageScrollView: some View {
        ScrollView {
            ScrollViewReader { proxy in
                LazyVStack(spacing: 18) {
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .onAppear { scrollToBottom(proxy) }
                .onChange(of: messageCount) { _ in scrollToBottom(proxy) }
                .onChange(of: lastContent) { _ in scrollToBottom(proxy) }
            }
        }
    }

    @ViewBuilder
    private var attachmentPreview: some View {
        if let imageData = pendingImage, let uiImage = UIImage(data: imageData) {
            HStack(spacing: 10) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Text("图片已添加")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                Spacer()
                Button { pendingImage = nil } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("移除图片")
            }
        } else if let name = pendingAttachmentName {
            HStack(spacing: 8) {
                Image(systemName: "doc.text").foregroundStyle(Color.accentColor)
                Text(name).font(.system(size: 14)).lineLimit(1)
                Spacer()
                Button {
                    pendingAttachmentName = nil
                    pendingAttachmentText = nil
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("移除文件")
            }
        } else {
            EmptyView()
        }
    }

    private var composer: some View {
        VStack(spacing: 0) {
        VStack(alignment: .leading, spacing: 8) {
            attachmentPreview

            TextField("发消息或按住说话", text: $inputText)
                .textFieldStyle(.plain)
                .font(.system(size: 18))
                .padding(.horizontal, 4)
                .padding(.vertical, 10)
                .frame(minHeight: 46)
                .onSubmit { send() }

            HStack(spacing: 6) {
                modeChip(title: "深度思考", symbol: "brain", isOn: $deepThinking)
                modeChip(title: "智能搜索", symbol: "globe", isOn: $webSearch)

                Spacer(minLength: 2)

                // 原版：输入框内的 + 点击后展开拍照/相册/文件；声波位置为发送（无语音识别，用箭头）
                GlassIconButton(
                    symbol: attachmentsExpanded ? "xmark.circle" : "plus.circle",
                    accessibilityLabelText: attachmentsExpanded ? "收起附件" : "展开附件",
                    iconSize: 22,
                    hitSize: 30
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) { attachmentsExpanded.toggle() }
                    dismissKeyboard()
                }

                // 原版右下角发送按钮：普通箭头图标 + 圆形玻璃按钮（无 circle.fill，不套娃）
                GlassIconButton(
                    symbol: "arrow.up",
                    accessibilityLabelText: "发送",
                    prominent: !inputText.isEmpty || hasAttachment,
                    tintColor: !inputText.isEmpty || hasAttachment ? Color.accentColor : nil,
                    iconSize: 18,
                    hitSize: 30
                ) {
                    if inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !hasAttachment {
                        alertMessage = "请先输入要发送的内容。"
                    } else {
                        send()
                    }
                }
                .disabled(isSending)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .appGlassCard(cornerRadius: 22)
        .padding(.horizontal, 16)
        .padding(.bottom, 6)

        // 原版：点击输入框 + 后才展开（最近照片 + 拍照/相册/文件）
        if attachmentsExpanded {
            RecentPhotosStrip { data in
                pendingImage = data
                pendingAttachmentName = nil
                pendingAttachmentText = nil
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            HStack(spacing: 10) {
                attachmentButton(symbol: "camera", title: "拍照") { showingCamera = true }
                attachmentButton(symbol: "photo", title: "相册") { showingPhotoPicker = true }
                attachmentButton(symbol: "paperclip", title: "文件") { showingDocumentPicker = true }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
        }
    }

    private func attachmentButton(symbol: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .medium))
                Text(title)
                    .font(.system(size: 13))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 66)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(uiColor: .secondarySystemBackground))
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .accessibilityLabel(title)
    }

    @ViewBuilder
    private func modeChip(title: String, symbol: String, isOn: Binding<Bool>) -> some View {
        let content = HStack(spacing: 5) {
            Image(systemName: isOn.wrappedValue ? "\(symbol).fill" : symbol)
            Text(title)
        }
        .font(.system(size: 15, weight: .semibold))
        .frame(height: 34)
        .padding(.horizontal, 12)
        .fixedSize()
        .contentShape(Capsule())

        if isOn.wrappedValue {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isOn.wrappedValue.toggle() }
            } label: { content }
            .appGlassProminentButton()
            .buttonBorderShape(.capsule)
            .controlSize(.small)
            .tint(Color.accentColor)
            .accessibilityLabel(title)
            .accessibilityValue("已开启")
        } else {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isOn.wrappedValue.toggle() }
            } label: { content }
            .appGlassButton()
            .buttonBorderShape(.capsule)
            .controlSize(.small)
            .accessibilityLabel(title)
            .accessibilityValue("已关闭")
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo("bottom", anchor: .bottom)
        }
    }

    private func speak(_ text: String) {
        guard speechEnabled else { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        synthesizer.speak(utterance)
    }

    private func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty || hasAttachment else { return }

        guard preferences.isConfigured else {
            alertMessage = "尚未填写 API Key。请前往「设置 → 账号管理」填写 Base URL、模型和 API Key。"
            return
        }

        store.appendMessage(ChatMessage(
            role: .user,
            content: text.isEmpty ? "请处理这个附件" : text,
            imageData: pendingImage,
            attachmentName: pendingAttachmentName,
            attachmentText: pendingAttachmentText
        ))
        inputText = ""
        pendingImage = nil
        pendingAttachmentName = nil
        pendingAttachmentText = nil
        isSending = true
        dismissKeyboard()

        let assistantID = UUID()
        store.appendMessage(
            ChatMessage(id: assistantID, role: .assistant, content: "", isStreaming: true)
        )

        guard let conversationID = store.currentID else {
            isSending = false
            return
        }

        let history = messages.filter { $0.id != assistantID }
        let configuration = preferences.configuration
        let apiKey = preferences.apiKey

        Task {
            do {
                let stream = ChatService.shared.stream(
                    configuration: configuration,
                    apiKey: apiKey,
                    messages: history,
                    deepThinking: deepThinking,
                    webSearch: webSearch
                )
                for try await chunk in stream {
                    let captured = chunk
                    await MainActor.run {
                        store.updateMessage(assistantID, in: conversationID) { message in
                            switch captured {
                            case .content(let value):
                                message.content += value
                            case .reasoning(let value):
                                message.reasoning = (message.reasoning ?? "") + value
                            }
                        }
                    }
                }
                let finalText = await MainActor.run {
                    store.currentConversation?.messages.first(where: { $0.id == assistantID })?.content ?? ""
                }
                speak(finalText)
            } catch {
                await MainActor.run {
                    store.updateMessage(assistantID, in: conversationID) { message in
                        message.content = "请求失败：\(error.localizedDescription)"
                    }
                }
            }

            await MainActor.run {
                store.finishStreaming(in: conversationID)
                isSending = false
            }
        }
    }
}
