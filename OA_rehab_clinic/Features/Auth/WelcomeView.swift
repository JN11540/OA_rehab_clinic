import SwiftUI

struct WelcomeView: View {
    @State private var showMainApp = false
    @StateObject private var userModel = UserModel.shared
    
    var body: some View {
        if showMainApp {
            // 主應用視圖
            CasesView()
                .environmentObject(userModel)
                .environmentObject(TrainingScheduleStore.shared)
                .environmentObject(TrainingMenuStore.shared)
        } else {
            // 歡迎畫面
            NavigationStack {
                GeometryReader { geometry in
                    ZStack {
                        // Background gradient with wave
                        VStack {
                            Spacer()
                            WaveShape()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(#colorLiteral(red: 0.4, green: 0.8, blue: 0.8, alpha: 1)),
                                            Color(#colorLiteral(red: 0.2, green: 0.6, blue: 0.8, alpha: 1))
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(height: geometry.size.height * 0.3)
                        }
                        .ignoresSafeArea()
                        
                        // Content
                        VStack(spacing: 20) {
                            Spacer()
                            
                            // Welcome text
                            VStack(spacing: 8) {
                                Text("歡迎")
                                    .font(.system(size: 36, weight: .medium))
                                    .foregroundColor(.gray.opacity(0.8))
                                
                                Text("註冊成功")
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(.black.opacity(0.8))
                            }
                            
                            // Orange decorative line
                            Rectangle()
                                .frame(width: 60, height: 4)
                                .foregroundColor(.orange)
                                .padding(.top, 10)
                            
                            Spacer()
                            Spacer()
                        }
                        .padding()
                    }
                }
                .statusBar(hidden: true)
                .onAppear {
                    // 檢查是否為首次啟動
                    let isFirstLaunch = UserDefaults.standard.object(forKey: "hasLaunched") == nil
                    
                    if isFirstLaunch {
                        // 首次啟動時設置預設值
                        let preview = UserModel.preview
                        userModel.name = preview.name
                        userModel.email = preview.email
                        userModel.department = preview.department
                        userModel.role = preview.role
                        
                        // 標記已啟動過
                        UserDefaults.standard.set(true, forKey: "hasLaunched")
                    }
                    
                    // 1秒後進入主應用
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showMainApp = true
                        }
                    }
                }
            }
        }
    }
}

// Wave shape
struct WaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: 0, y: rect.height))
        
        // Wave pattern
        let width = rect.width
        let height = rect.height
        let midHeight = height * 0.8
        
        path.addCurve(
            to: CGPoint(x: width, y: height),
            control1: CGPoint(x: width * 0.4, y: midHeight),
            control2: CGPoint(x: width * 0.6, y: height * 1.2)
        )
        
        // Complete the shape
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        
        return path
    }
}

#Preview {
    WelcomeView()
} 