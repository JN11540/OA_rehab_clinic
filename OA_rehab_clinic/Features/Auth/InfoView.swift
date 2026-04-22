import SwiftUI

struct InfoView: View {
    @State private var hospitalDepartment: String = ""
    @State private var selectedRole: Role?
    @State private var showAlert: Bool = false
    @State private var isFormValid: Bool = false
    
    // 定义职称选项
    enum Role: String, CaseIterable {
        case doctor = "醫師"
        case therapist = "治療師"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    // 标题部分
                    VStack(alignment: .leading, spacing: 8) {
                        Text("歡迎使用")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.gray.opacity(0.8))
                        
                        Text("填寫您的個人資料")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.black.opacity(0.8))
                        
                        // 橙色装饰线
                        Rectangle()
                            .frame(width: 60, height: 3)
                            .foregroundColor(.orange)
                            .padding(.top, 4)
                    }
                    .padding(.top, 40)
                    
                    // 表单部分
                    VStack(alignment: .leading, spacing: 25) {
                        // 服务院所
                        VStack(alignment: .leading, spacing: 8) {
                            Text("服務院所")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            TextField("單位名稱、科別，例：OO醫院OO科", text: $hospitalDepartment)
                                .textFieldStyle(CustomTextFieldStyle())
                                .autocapitalization(.none)
                        }
                        
                        // 职称选择
                        VStack(alignment: .leading, spacing: 8) {
                            Text("職稱")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            HStack(spacing: 15) {
                                ForEach(Role.allCases, id: \.id) { role in
                                    RoleSelectionButton(
                                        title: role.rawValue,
                                        isSelected: selectedRole == role,
                                        action: { selectedRole = role }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // 提交按钮
                    Button(action: {
                        validateAndSubmit()
                    }) {
                        Text("儲存並開始使用")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isFormValid ? Color.orange : Color.gray.opacity(0.3))
                            )
                    }
                    .disabled(!isFormValid)
                    .padding(.bottom, 30)
                }
                .padding(.horizontal, 40)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(#colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)).opacity(0.2),
                        Color(#colorLiteral(red: 0.721568644, green: 0.8862745166, blue: 0.5921568871, alpha: 1)).opacity(0.2)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .alert("請填寫完整資料", isPresented: $showAlert) {
            Button("確定", role: .cancel) {}
        }
        .onChange(of: hospitalDepartment) { _ in
            validateForm()
        }
        .onChange(of: selectedRole) { _ in
            validateForm()
        }
    }
    
    // 表单验证
    private func validateForm() {
        isFormValid = !hospitalDepartment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && selectedRole != nil
    }
    
    // 提交处理
    private func validateAndSubmit() {
        if isFormValid {
            // TODO: 处理提交逻辑
            print("Form submitted with hospital: \(hospitalDepartment), role: \(selectedRole?.rawValue ?? "")")
        } else {
            showAlert = true
        }
    }
}

// 自定义输入框样式
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
}

// 职称选择按钮
struct RoleSelectionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isSelected ? Color.blue : Color.clear)
                        )
                )
        }
    }
}

#Preview {
    InfoView()
} 