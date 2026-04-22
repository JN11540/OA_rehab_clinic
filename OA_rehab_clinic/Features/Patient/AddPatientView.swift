import SwiftUI

struct AddPatientView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var patientStore = PatientStore.shared
    @Binding var addedPatient: Patient?
    
    @State private var patientId: String = ""
    @State private var searchResult: Patient? = nil
    @State private var showingConfirmation = false
    @State private var isSearching = false
    @State private var showError = false
    
    var body: some View {
        ZStack {
            // 半透明背景層
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            // 主要內容
            VStack(spacing: 30) {
                Text("新增個案")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.navy)
                    .padding(.top, 40)

                Spacer()
                
                // 搜尋區域
                VStack(spacing: 24) {
                    // ID輸入框
                    TextField("輸入患者病歷號", text: $patientId)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(size: 28))
                        .frame(maxWidth: 400, maxHeight: 60)
                    
                    // 搜尋按鈕
                    Button(action: searchPatient) {
                        Text("搜尋個案")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 180, height: 50)
                            .background(Color.orange)
                            .cornerRadius(25)
                    }
                }
                .padding(.horizontal, 40)
                
                if isSearching {
                    ProgressView()
                        .scaleEffect(1.5)
                }
                
                Spacer()

                // 底部按鈕區域
                HStack(spacing: 24) {
                    Button {
                        // 掃描QR code 功能
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 24))
                            Text("掃描QR code")
                        }
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.teal)
                        .frame(width: 220, height: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.teal, lineWidth: 1)
                        )
                    }
                    
                    Button {
                        // 搜尋ID 功能
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 24))
                            Text("搜尋ID")
                        }
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 180, height: 50)
                        .background(Color.teal)
                        .cornerRadius(25)
                    }
                }
                .padding(.bottom, 40)
            }
            .frame(width: 600, height: 650)
            .background(Color.white)
            .cornerRadius(16)
        }
        .alert("找不到此病患", isPresented: $showError) {
            Button("確定", role: .cancel) { }
        } message: {
            Text("查無此病歷號，或此病歷號已存在於系統中")
        }
        .sheet(isPresented: $showingConfirmation) {
            if let patient = searchResult {
                ConfirmAddPatientView(patient: patient) { confirmed in
                    if confirmed {
                        addedPatient = patient
                        dismiss()
                    }
                    showingConfirmation = false
                }
            }
        }
    }
    
    private func searchPatient() {
        isSearching = true
        
        // 模擬網路請求延遲
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            searchResult = patientStore.searchById(patientId)
            isSearching = false
            
            if let _ = searchResult {
                showingConfirmation = true
            } else {
                showError = true
            }
        }
    }
}

struct ConfirmAddPatientView: View {
    let patient: Patient
    let onConfirm: (Bool) -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 120, height: 120)
                .foregroundColor(.gray.opacity(0.3))
            
            Text(patient.name)
                .font(.system(size: 32, weight: .bold))
            
            Text(patient.id)
                .font(.system(size: 24))
                .foregroundColor(.gray)
            
            HStack(spacing: 24) {
                Button("返回搜尋") {
                    onConfirm(false)
                }
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.gray)
                .frame(width: 180, height: 50)
                .background(Color.white)
                .cornerRadius(25)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.gray, lineWidth: 1)
                )
                
                Button("確認新增") {
                    onConfirm(true)
                }
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 180, height: 50)
                .background(Color.orange)
                .cornerRadius(25)
            }
            .padding(.top, 30)
        }
        .padding(40)
        .frame(width: 500, height: 450)
        .background(Color.white)
        .cornerRadius(16)
    }
}

extension Color {
    static let navy = Color(red: 0.2, green: 0.3, blue: 0.5)
    static let teal = Color(red: 0.2, green: 0.6, blue: 0.6)
}

#Preview {
    AddPatientView(addedPatient: .constant(nil))
} 
