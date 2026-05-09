import Foundation

@MainActor
class StateManager: ObservableObject {
    static let shared = StateManager()

    enum ImportState {
        case idle
        case importing
        case success(String)
        case failure(String)
    }

    @Published var state: ImportState = .idle

    private init() {}

    func setSuccess(_ message: String) {
        state = .success(message)
        autoDismiss()
    }

    func setFailure(_ message: String) {
        state = .failure(message)
        autoDismiss()
    }

    private func autoDismiss() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.state = .idle
        }
    }
}
