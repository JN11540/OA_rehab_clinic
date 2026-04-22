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
                .preferredColorScheme(.light)  // SwiftUI 視圖層級強制 Light Mode
        }
    }
}
