// Designed by TiantianYe
import SwiftUI

struct SettingsView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var preferences: AppPreferences
    @EnvironmentObject private var store: ConversationStore
    @State private var showAPIConfig = false
    @State private var showDataManagement = false

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 16) {
                    settingsGroup("账户") {
                        settingRow(
                            icon: "person.circle",
                            title: "账号管理",
                            value: preferences.isConfigured ? "已配置" : "未配置"
                        ) { showAPIConfig = true }
                        Divider().padding(.leading, 50)
                        settingRow(icon: "externaldrive", title: "数据管理") { showDataManagement = true }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 30)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .sheet(isPresented: $showAPIConfig) {
            APIConfigView().environmentObject(preferences)
        }
        .sheet(isPresented: $showDataManagement) {
            DataManagementView()
                .environmentObject(store)
                .environmentObject(preferences)
        }
    }

    private var header: some View {
        ZStack {
            Text("设置")
                .font(.system(size: 17, weight: .semibold))

            HStack {
                Spacer()
                GlassIconButton(symbol: "xmark", accessibilityLabelText: "关闭设置") {
                    isPresented = false
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Color(uiColor: .systemGroupedBackground))
    }

    @ViewBuilder
    private func settingsGroup<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if !title.isEmpty {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
            }

            GlassCard(cornerRadius: 14) {
                VStack(spacing: 0) {
                    content()
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func settingRow(
        icon: String,
        title: String,
        value: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(.primary)
                    .frame(width: 24)

                Text(title)
                    .font(.system(size: 17))

                Spacer(minLength: 6)

                if let value = value {
                    Text(value)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .accessibilityLabel(title)
    }
}

// 玻璃卡片容器（保留给设置分组使用，基于原生 glassEffect）
struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    let content: Content

    init(cornerRadius: CGFloat = 18, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    @ViewBuilder
    var body: some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            content
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
                }
        }
    }
}

struct APIConfigView: View {
    @EnvironmentObject private var preferences: AppPreferences
    @Environment(\.presentationMode) private var presentationMode
    @State private var baseURL = ""
    @State private var apiKey = ""
    @State private var model = ""
    @State private var reasonerModel = ""
    @State private var status = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("接口")) {
                    TextField("Base URL", text: $baseURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                    TextField("对话模型", text: $model)
                        .textInputAutocapitalization(.never)
                    TextField("深度思考模型", text: $reasonerModel)
                        .textInputAutocapitalization(.never)
                }

                Section(header: Text("密钥")) {
                    SecureField("API Key", text: $apiKey)
                        .textInputAutocapitalization(.never)
                    Text("密钥仅保存在本机钥匙串，不会上传到任何服务器。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !status.isEmpty {
                    Section {
                        Text(status)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("账号管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        save()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .onAppear {
            baseURL = preferences.configuration.baseURL
            apiKey = preferences.apiKey
            model = preferences.configuration.model
            reasonerModel = preferences.configuration.reasonerModel
        }
    }

    private func save() {
        let trimmedBase = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedBase.isEmpty else { return }
        preferences.configuration = APIConfiguration(
            baseURL: trimmedBase,
            model: model.isEmpty ? "deepseek-chat" : model,
            reasonerModel: reasonerModel.isEmpty ? "deepseek-reasoner" : reasonerModel
        )
        preferences.apiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct DataManagementView: View {
    @EnvironmentObject private var store: ConversationStore
    @EnvironmentObject private var preferences: AppPreferences
    @Environment(\.presentationMode) private var presentationMode
    @State private var showClearConfirm = false
    @State private var showResetConfirm = false

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("对话")) {
                    Button(role: .destructive) {
                        showClearConfirm = true
                    } label: {
                        Text("清除全部对话记录（\(store.conversations.count) 个）")
                    }
                }

                Section(header: Text("连接")) {
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Text("重置 API 配置")
                    }
                    Text("重置后需要重新填写 Base URL、模型与 API Key。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("数据管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { presentationMode.wrappedValue.dismiss() }
                }
            }
        }
        .alert("清除全部对话", isPresented: $showClearConfirm) {
            Button("取消", role: .cancel) {}
            Button("清除", role: .destructive) { store.clearAll() }
        } message: {
            Text("所有本地对话记录将被删除，此操作不可撤销。")
        }
        .alert("重置 API 配置", isPresented: $showResetConfirm) {
            Button("取消", role: .cancel) {}
            Button("重置", role: .destructive) {
                preferences.configuration = .default
                preferences.apiKey = ""
            }
        } message: {
            Text("API Key 会从钥匙串中移除。")
        }
    }
}
