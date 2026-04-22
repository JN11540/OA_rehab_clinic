import SwiftUI

struct PatientUserProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userModel: UserModel
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var department: String = ""
    @State private var role: UserModel.Role = .doctor
    @State private var showingSaveAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("姓名", text: $name)
                    TextField("Email", text: $email)
                    TextField("部門", text: $department)
                    
                    Picker("角色", selection: $role) {
                        ForEach(UserModel.Role.allCases, id: \.self) { role in
                            Text(role.rawValue).tag(role)
                        }
                    }
                } header: {
                    Text("基本資料")
                }
                
                Section {
                    Button("儲存資料") {
                        userModel.name = name
                        userModel.email = email
                        userModel.department = department
                        userModel.role = role
                        showingSaveAlert = true
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("使用者資料")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                name = userModel.name
                email = userModel.email
                department = userModel.department
                role = userModel.role
            }
            .alert("儲存成功", isPresented: $showingSaveAlert) {
                Button("確定") {
                    dismiss()
                }
            } message: {
                Text("您的使用者資料已更新。")
            }
        }
    }
}

#Preview {
    PatientUserProfileView()
        .environmentObject(UserModel.preview)
} 