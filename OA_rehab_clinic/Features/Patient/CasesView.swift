import SwiftUI

struct CasesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userModel: UserModel
    @StateObject private var patientStore = PatientStore.shared
    @State private var searchText: String = ""
    @State private var showingAddPatient = false
    @State private var newPatient: Patient? = nil
    @State private var showingUserProfile = false
    
    // 過濾後的病患列表
    var filteredPatients: [Patient] {
        if searchText.isEmpty {
            return patientStore.patients
        } else {
            return patientStore.patients.filter { $0.id.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with tabs
                HStack {
                    // App logo
                    Image("AppIcon-Standard.png")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .cornerRadius(10)
                        .padding(.leading, 30)
                    
                    Spacer()
                    
                    // Tab navigation
                    HStack(spacing: 30) {
                        Text("個案管理")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.orange)
                            .padding(.bottom, 5)
                            .overlay(
                                Rectangle()
                                    .frame(height: 2)
                                    .foregroundColor(.orange),
                                alignment: .bottom
                            )
                        
                        NavigationLink(destination: MenuManagementView()
                            .environmentObject(userModel)
                            .environmentObject(TrainingScheduleStore.shared)
                            .environmentObject(TrainingMenuStore.shared)
                            .environmentObject(patientStore)
                        ) {
                            Text("菜單管理")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    // User info and Search bar
                    HStack(spacing: 20) {
                        // Search bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("搜尋個案", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.1))
                        )
                        .frame(width: 300)
                        
                        // User info
                        HStack(spacing: 12) {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 32, height: 32)
                                .foregroundColor(.gray)
                            Text("\(userModel.name) \(userModel.role.rawValue)")
                                .foregroundColor(.gray)
                            Text(userModel.department)
                                .foregroundColor(.gray)
                            
                            Button(action: {
                                showingUserProfile = true
                            }) {
                                Image(systemName: "gearshape")
                                    .foregroundColor(.gray)
                            }
                            
                            Button(action: {}) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                
                // Content area
                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 200, maximum: 200), spacing: 24)
                        ],
                        spacing: 24
                    ) {
                        // Add case button (只在沒有搜尋時顯示)
                        if searchText.isEmpty {
                            Button(action: { showingAddPatient = true }) {
                                AddCaseCard()
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Patient cards (顯示過濾後的病患)
                        ForEach(filteredPatients) { patient in
                            NavigationLink(destination: CaseManageView(patient: patient)
                                .environmentObject(TrainingScheduleStore.shared)
                                .environmentObject(TrainingMenuStore.shared)
                                .environmentObject(userModel)
                            ) {
                                CaseCard(patient: patient)
                            }
                        }
                    }
                    .padding(30)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    GradientBackground(
                        startColor: Color(red: 0.47, green: 0.84, blue: 0.98),
                        endColor: Color(red: 0.72, green: 0.89, blue: 0.59)
                    )
                )
            }
            .sheet(isPresented: $showingAddPatient) {
                AddPatientView(addedPatient: $newPatient)
            }
            .sheet(isPresented: $showingUserProfile) {
                UserProfileView()
            }
            .onChange(of: newPatient, perform: { newValue in
                if let patient = newValue {
                    patientStore.addPatient(patient)
                    newPatient = nil
                }
            })
        }
        .environmentObject(userModel)
        .environmentObject(TrainingScheduleStore.shared)
        .environmentObject(TrainingMenuStore.shared)
    }
}

// Add case card
struct AddCaseCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "plus.circle.fill")
                .resizable()
                .frame(width: 40, height: 40)
            Text("新增個案")
                .font(.system(size: 16, weight: .medium))
        }
        .foregroundColor(.orange)
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                .background(Color.white)
        )
        .cornerRadius(12)
    }
}

// Case card view
struct CaseCard: View {
    let patient: Patient
    @StateObject private var patientStore = PatientStore.shared
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.gray.opacity(0.3))
            
            VStack(spacing: 6) {
                Text(patient.id)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                Text(patient.name)
                    .font(.system(size: 16, weight: .medium))
            }
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3)
        .contextMenu {
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("刪除個案", systemImage: "trash")
            }
        }
        .alert("確認刪除", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("刪除", role: .destructive) {
                patientStore.removePatient(patient)
            }
        } message: {
            Text("確定要刪除 \(patient.name) (\(patient.id)) 的所有資料嗎？")
        }
    }
}

#Preview {
    CasesView()
        .environmentObject(UserModel.preview)
        .environmentObject(TrainingScheduleStore.preview)
        .environmentObject(TrainingMenuStore.preview)
} 
