import SwiftUI

struct NavigationHeader: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode
    let patient: Patient
    @EnvironmentObject private var userModel: UserModel
    var pageTitle: String = ""
    @State private var showingUserProfile = false
    
    var body: some View {
        GridRow {
            HStack {
                // 左側導航
                if pageTitle.isEmpty {
                    // 在 CaseManageView 中
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Text("個案管理")
                            Text(">")
                            Text("\(patient.name) \(patient.id)")
                        }
                        .foregroundColor(.gray)
                    }
                } else {
                    // 在其他視圖中
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Text("個案管理")
                            Text(">")
                            Text("\(patient.name) \(patient.id)")
                            Text(">")
                            Text(pageTitle)
                        }
                        .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // 右側醫師資訊和功能按鈕
                HStack(spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.gray)
                        Text("\(userModel.name) \(userModel.role.rawValue)")
                             .foregroundColor(.gray)
                        Text(userModel.department)
                            .foregroundColor(.gray)
                    }
                    
                    // 功能按鈕
                    Button(action: {
                        showingUserProfile = true
                    }) {
                        Image(systemName: "gearshape")
                            .foregroundColor(.gray)
                    }
                    
                    Button(action: {
                        // 登出功能
                    }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.gray)
                    }
                }
            }
            .gridCellColumns(5)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .sheet(isPresented: $showingUserProfile) {
                UserProfileView()
                    .environmentObject(userModel)
            }
        }
    }
}

#Preview {
    NavigationHeader(
        patient: Patient.sample,
        pageTitle: "測試頁面"
    )
    .environmentObject(UserModel.preview)
}
