// Designed by TiantianYe
import SwiftUI

/// 系统版本兼容层：iOS 26+ 使用原生 Liquid Glass（系统自带按压高光、融合形变等动效），
/// iOS 15–25 回退到系统材质 / 系统按钮样式。
/// 方案与水课帮、实验数据拟合保持一致，全部基于 Apple 官方 API：
/// - ButtonStyle.glass / .glassProminent（iOS 26+）
/// - View.glassEffect(_:in:) + Glass.interactive()（iOS 26+）
/// - GlassEffectContainer / glassEffectID（iOS 26+）
extension View {
    /// 卡片玻璃：iOS 26+ 带 interactive 触摸高光
    @ViewBuilder
    func appGlassCard(cornerRadius: CGFloat) -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
        } else {
            background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
                }
        }
    }

    /// 融合容器：iOS 26+ 让相邻玻璃元素靠近时自然粘合/形变
    @ViewBuilder
    func appGlassContainer(spacing: CGFloat) -> some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) { self }
        } else {
            self
        }
    }

    /// 融合标识：配合容器实现玻璃元素间的 morph 动效
    @ViewBuilder
    func appGlassID(_ id: String, in namespace: Namespace.ID) -> some View {
        if #available(iOS 26.0, *) {
            glassEffectID(id, in: namespace)
        } else {
            self
        }
    }

    /// 原生玻璃按钮样式（透明）
    @ViewBuilder
    func appGlassButton() -> some View {
        if #available(iOS 26.0, *) {
            buttonStyle(.glass)
        } else {
            buttonStyle(.bordered)
        }
    }

    /// 原生玻璃按钮样式（实心强调）
    @ViewBuilder
    func appGlassProminentButton() -> some View {
        if #available(iOS 26.0, *) {
            buttonStyle(.glassProminent)
        } else {
            buttonStyle(.borderedProminent)
        }
    }
}

/// 原生圆形图标按钮：使用系统 .glass 按钮样式 + .circle 轮廓，
/// 由系统负责按压时的液态玻璃形变/高光动效（非自绘）。
struct GlassIconButton: View {
    let symbol: String
    let accessibilityLabelText: String
    var prominent: Bool = false
    var tintColor: Color? = nil
    var iconSize: CGFloat = 16
    var hitSize: CGFloat = 34
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: iconSize, weight: .semibold))
                .frame(width: hitSize, height: hitSize)
                .contentShape(Circle())
        }
        .modifier(GlassButtonStyleModifier(prominent: prominent))
        .modifier(CircleBorderShapeModifier())
        .controlSize(.small)
        .clipShape(Circle())
        .ifLet(tintColor) { view, color in
            view.tint(color)
        }
        .accessibilityLabel(accessibilityLabelText)
    }
}

/// .circle 轮廓 iOS 17+ 才有；iOS 15/16 用 .capsule + clipShape 得到正圆
private struct CircleBorderShapeModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.buttonBorderShape(.circle)
        } else {
            content.buttonBorderShape(.capsule)
        }
    }
}

private struct GlassButtonStyleModifier: ViewModifier {
    let prominent: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            if prominent {
                content.buttonStyle(.glassProminent)
            } else {
                content.buttonStyle(.glass)
            }
        } else {
            if prominent {
                content.buttonStyle(.borderedProminent)
            } else {
                content.buttonStyle(.bordered)
            }
        }
    }
}

extension View {
    @ViewBuilder
    func ifLet<Value, Content: View>(_ value: Value?, transform: (Self, Value) -> Content) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
}
