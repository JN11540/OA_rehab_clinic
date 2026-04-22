//
//  ContentView.swift
//  OA_rehab_clinic
//
//  Created by CHIENMING LO on 2025/1/17.
//

import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left side - Image placeholder
                Rectangle()
                    .fill(.clear)
                    .frame(width: geometry.size.width * 0.5)
                    .overlay(
                        Image(systemName: "building.columns")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200)
                            .foregroundColor(.gray.opacity(0.3))
                    )
                
                // Right side - Login form
                VStack(spacing: 25) {
                    Text("歡迎回來")
                        .font(.system(size: 32, weight: .bold))
                        .padding(.bottom, 20)
                    
                    // Email field
                    TextField("信箱", text: $email)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .frame(maxWidth: 400)
                    
                    // Password field
                    HStack {
                        if isPasswordVisible {
                            TextField("密碼", text: $password)
                        } else {
                            SecureField("密碼", text: $password)
                        }
                        
                        Button(action: {
                            isPasswordVisible.toggle()
                        }) {
                            Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .frame(maxWidth: 400)
                    
                    // Login button
                    Button(action: {
                        // Login action
                    }) {
                        Text("登入")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: 400)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.orange)
                            )
                    }
                    .padding(.top, 10)
                    
                    // Links
                    HStack(spacing: 20) {
                        Button("忘記密碼？") {
                            // Forgot password action
                        }
                        
                        Text("•")
                            .foregroundColor(.gray)
                        
                        Button("第一次使用？點此註冊帳戶") {
                            // Register action
                        }
                    }
                    .foregroundColor(.blue)
                    .font(.system(size: 14))
                }
                .padding(40)
                .frame(width: geometry.size.width * 0.5)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(#colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)).opacity(0.2),
                                                  Color(#colorLiteral(red: 0.721568644, green: 0.8862745166, blue: 0.5921568871, alpha: 1)).opacity(0.2)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .ignoresSafeArea()
        .statusBar(hidden: true)
        // Force landscape orientation
        .onAppear {
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue,
                                   forKey: "orientation")
        }
    }
}

#Preview {
    LoginView()
}
