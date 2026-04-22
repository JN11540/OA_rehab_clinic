import SwiftUI

// 新增輔助元件
struct InfoField: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 18, weight: .medium))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

extension InfoField {
    init(label: String, value: Gender) {
        self.init(label: label, value: value.rawValue)
    }
    
    init(label: String, value: AffectedSide) {
        self.init(label: label, value: value.rawValue)
    }
    
    init(label: String, value: SmartKneeStatus) {
        self.init(label: label, value: value.rawValue)
    }
    
    init(label: String, value: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY.MM.dd"
        self.init(label: label, value: formatter.string(from: value))
    }
    
    init(label: String, value: Double) {
        self.init(label: label, value: String(format: "%.1f", value))
    }
    
    init(label: String, value: Int) {
        self.init(label: label, value: "\(value) 級")
    }
    
    init(label: String, value: Bool) {
        self.init(label: label, value: value ? "有" : "無")
    }
    
    init(label: String, value: [String]) {
        self.init(label: label, value: value.isEmpty ? "無" : value.joined(separator: "、"))
    }
} 
