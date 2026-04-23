//
//  OA_rehab_clinicApp.swift
//  OA_rehab_clinic
//
//  Created by CHIENMING LO on 2025/1/17.
//

import SwiftUI
import UIKit

@main
struct OA_rehab_clinicApp: App {
    @StateObject private var importManager = StateManager.shared

    init() {
        // 強制使用 Light Mode - 支援 iOS 17
        if #available(iOS 17.0, *) {
            UIWindow.appearance().overrideUserInterfaceStyle = .light
        } else {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.windows.first?.overrideUserInterfaceStyle = .light
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            WelcomeView()
                .preferredColorScheme(.light)
                .overlay(alignment: .top) {
                    ToastView(manager: importManager)
                }
                .onOpenURL { url in
                    Task { @MainActor in
                        importManager.state = .importing
                        do {
                            let message = try JSONImportService.shared.importJSON(from: url)
                            importManager.setSuccess(message)
                        } catch {
                            importManager.setFailure(error.localizedDescription)
                        }
                    }
                }
        }
    }
}
