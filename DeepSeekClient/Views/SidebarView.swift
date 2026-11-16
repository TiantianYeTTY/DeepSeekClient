// Designed by TiantianYe
import SwiftUI
import UIKit

/// 系统原生搜索栏包装：iOS 26+ 自动呈现 Liquid Glass 外观，位置可控（顶部）。
struct NativeSearchBar: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String

    func makeUIView(context: Context) -> UISearchBar {
        let bar = UISearchBar()
        bar.placeholder = placeholder
        bar.searchBarStyle = .minimal
        bar.delegate = context.coordinator
        bar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
        bar.backgroundColor = .clear
        return bar
    }

    func updateUIView(_ uiView: UISearchBar, context: Context) {
        if uiView.text != text { uiView.text = text }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    final class Coordinator: NSObject, UISearchBarDelegate {
        var text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text.wrappedValue = searchText
        }

        func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
            searchBar.setShowsCancelButton(true, animated: true)
        }

        func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            searchBar.text = nil
            searchBar.resignFirstResponder()
            searchBar.setShowsCancelButton(false, animated: true)
            text.wrappedValue = ""
        }

        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
        }
    }
}

/// 列表背景透明（iOS 16+ 原生修饰，iOS 15 用系统默认列表背景）
private struct ClearListBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .scrollContentBackground(.hidden)
                .background(Color(uiColor: .systemBackground))
        } else {
            content
        }
    }
}

struct SidebarView: View {
    @Binding var isPresented: Bool
    @Binding var showSettings: Bool
    @EnvironmentObject private var store: ConversationStore
    @State private var searchText = ""
    @State private var renameTarget: Conversation?
    @State private var renameText = ""

    private var drawerWidth: CGFloat { min(UIScreen.main.bounds.width * 0.86, 350) }

    private var sections: [(title: String, items: [Conversation])] {
        let all = store.conversations
        let filtered: [Conversation]
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            filtered = all
        } else {
            filtered = all.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.preview.localizedCaseInsensitiveContains(searchText)
            }
        }

        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now

        let today = filtered.filter { calendar.isDateInToday($0.updatedAt) }
        let recent = filtered.filter { !calendar.isDateInToday($0.updatedAt) && $0.updatedAt > weekAgo }
        let older = filtered.filter { !calendar.isDateInToday($0.updatedAt) && $0.updatedAt <= weekAgo }

        var result: [(title: String, items: [Conversation])] = []
        if !today.isEmpty { result.append((title: "今天", items: today)) }
        if !recent.isEmpty { result.append((title: "7 天内", items: recent)) }
        if !older.isEmpty { result.append((title: "更早", items: older)) }
        return result
    }

    var body: some View {
        ZStack(alignment: .leading) {
            if isPresented {
                Color.black.opacity(0.28)
                    .ignoresSafeArea()
                    .onTapGesture { isPresented = false }
                    .transition(.opacity)
            }

            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    drawerContent
                    footer
                }
                .frame(width: drawerWidth)
                .background(Color(uiColor: .systemBackground))

                Spacer(minLength: 0)
            }
            .offset(x: isPresented ? 0 : -drawerWidth - 24)
            .animation(.easeInOut(duration: 0.26), value: isPresented)
        }
        .allowsHitTesting(isPresented)
        .alert(
            "重命名对话",
            isPresented: Binding(
                get: { renameTarget != nil },
                set: { if !$0 { renameTarget = nil } }
            )
        ) {
            TextField("标题", text: $renameText)
            Button("取消", role: .cancel) { renameTarget = nil }
            Button("保存") {
                if let target = renameTarget {
                    store.rename(target.id, to: renameText)
                }
                renameTarget = nil
            }
        }
    }

    private var drawerContent: some View {
        VStack(spacing: 0) {
            NativeSearchBar(text: $searchText, placeholder: "搜索对话内容")
                .padding(.horizontal, 10)
                .padding(.top, 4)

            List {
                ForEach(sections, id: \.title) { section in
                    Section(header: Text(section.title)) {
                        ForEach(section.items) { conversation in
                            conversationRow(conversation)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .modifier(ClearListBackgroundModifier())
        }
    }

    private func conversationRow(_ conversation: Conversation) -> some View {
        HStack(spacing: 8) {
            Text(conversation.title)
                .font(.system(size: 17, weight: .medium))
                .lineLimit(1)
                .foregroundStyle(store.currentID == conversation.id ? Color.accentColor : Color.primary)

            Spacer(minLength: 4)

            Menu {
                Button {
                    renameTarget = conversation
                    renameText = conversation.title
                } label: {
                    Label("重命名", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    store.delete(conversation.id)
                } label: {
                    Label("删除", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 30, height: 30)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            store.select(conversation.id)
            isPresented = false
        }
    }

    private var footer: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.65)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    Text("T")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 38, height: 38)

                Text("TiantianYe")
                    .font(.system(size: 17, weight: .semibold))
                    .lineLimit(1)

                Spacer(minLength: 4)

                GlassIconButton(symbol: "ellipsis", accessibilityLabelText: "打开设置") {
                    showSettings = true
                    isPresented = false
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(uiColor: .systemBackground))
    }
}
