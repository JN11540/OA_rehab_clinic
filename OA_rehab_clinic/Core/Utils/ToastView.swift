import SwiftUI

struct ToastView: View {
    @ObservedObject var manager: StateManager

    var body: some View {
        Group {
            switch manager.state {
            case .idle:
                EmptyView()

            case .importing:
                toastCard {
                    HStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("正在匯入資料...")
                            .foregroundColor(.white)
                            .font(.subheadline)
                    }
                }
                .background(Color.blue.opacity(0.9))

            case .success(let msg):
                toastCard {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                        Text(msg)
                            .foregroundColor(.white)
                            .font(.subheadline)
                    }
                }
                .background(Color.green.opacity(0.9))

            case .failure(let msg):
                toastCard {
                    HStack(spacing: 12) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                        Text(msg)
                            .foregroundColor(.white)
                            .font(.subheadline)
                    }
                }
                .background(Color.red.opacity(0.9))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isVisible)
        .padding(.top, 20)
    }

    private var isVisible: Bool {
        if case .idle = manager.state { return false }
        return true
    }

    @ViewBuilder
    private func toastCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}
