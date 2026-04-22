// MARK: - 子视图组件

import SwiftUI

struct PatientInfoCard: View {
    let patient: Patient
    
    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            // 左側頭像和個人資訊 (約佔 1/2)
            HStack(alignment: .top, spacing: 16) {
                // 頭像
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.gray.opacity(0.3))
                
                // 基本資料（拆分為兩行）
                VStack(alignment: .leading, spacing: 16) {
                    // 第一行：姓名、性別、生日
                    HStack(spacing: 12) {
                        InfoField(label: "姓名", value: patient.name)
                            .frame(width: 100)
                        InfoField(label: "性別", value: patient.gender)
                            .frame(width: 80)
                        InfoField(label: "生日", value: patient.birthDate)
                            .frame(width: 120)
                    }
                    
                    // 第二行：身高、體重、患側
                    HStack(spacing: 12) {
                        InfoField(label: "身高", value: "\(patient.height) cm")
                            .frame(width: 100)
                        InfoField(label: "體重", value: "\(patient.weight) kg")
                            .frame(width: 80)
                        InfoField(label: "患側", value: patient.affectedSide)
                            .frame(width: 120)
                    }
                }
            }
            
            Rectangle()
                .frame(width: 1)
                .foregroundColor(.gray.opacity(0.3))
            
            // 中間設備資訊 (約佔 1/4)
            VStack(alignment: .leading, spacing: 16) {
                InfoField(label: "智慧護膝", value: patient.equipment.smartKnee)
                InfoField(label: "心律節律器", value: patient.equipment.stimulator)
            }
            .frame(width: 140)
            
            Rectangle()
                .frame(width: 1)
                .foregroundColor(.gray.opacity(0.3))
            
            // 右側設備資訊 (約佔 1/4)
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("家中道具")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(patient.equipment.homeEquipment, id: \.self) { item in
                                Text(item)
                                    .font(.system(size: 18, weight: .medium))
                            }
                        }
                    }
                }
                InfoField(label: "可接受電刺激", value: patient.acceptsElectricity)
            }
            .frame(width: 140)
            
            Spacer(minLength: 20)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(12)
    }
}

#Preview {
    PatientInfoCard(patient: Patient.sample)
        .padding()
        .background(Color.gray.opacity(0.1))
}
