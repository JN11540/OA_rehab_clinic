import SwiftUI

struct UserProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userModel: UserModel
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                GradientBackground(
                    startColor: Color(red: 0.47, green: 0.84, blue: 0.98),
                    endColor: Color(red: 0.72, green: 0.89, blue: 0.59)
                )
                .ignoresSafeArea(edges: .all)
                
                VStack(spacing: 30) {
                    // Navigation header with back button
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            HStack(spacing: 4) {
                                Text("回前頁")
                                    .foregroundColor(.gray)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    
                    // Profile content
                    ScrollView {
                        VStack(spacing: 30) {
                            Text("個人資料維護")
                                .font(.system(size: 24, weight: .bold))
                            
                            // Profile image section
                            VStack {
                                if let image = selectedImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .frame(width: 120, height: 120)
                                        .foregroundColor(.gray.opacity(0.3))
                                }
                                
                                Button("編輯大頭貼") {
                                    showingImagePicker = true
                                }
                                .foregroundColor(.orange)
                                .padding(.top, 8)
                            }
                            
                            // User information form
                            VStack(spacing: 20) {
                                FormField(title: "姓    名", text: $userModel.name)
                                FormField(title: "信    箱", text: $userModel.email)
                                FormField(title: "服務院所", text: $userModel.department)
                                
                                // Role picker
                                HStack {
                                    Text("職    稱")
                                        .frame(width: 80, alignment: .leading)
                                    Picker("職稱", selection: $userModel.role) {
                                        ForEach(UserModel.Role.allCases, id: \.self) { role in
                                            Text(role.rawValue).tag(role)
                                        }
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                }
                                .padding(.horizontal)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                            
                            // Save button
                            Button(action: {
                                userModel.saveUserData()
                                dismiss()
                            }) {
                                Text("儲存")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 120, height: 40)
                                    .background(Color.orange)
                                    .cornerRadius(20)
                            }
                            .padding(.top, 2)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            // TODO: Implement image picker
            EmptyView()
        }
    }
}

// Form field component
struct FormField: View {
    let title: String
    @Binding var text: String
    
    var body: some View {
        HStack {
            Text(title)
                .frame(width: 80, alignment: .leading)
            TextField("", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        UserProfileView()
            .environmentObject(UserModel.preview)
    }
} 
