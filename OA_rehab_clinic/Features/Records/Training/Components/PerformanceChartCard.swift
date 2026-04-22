import SwiftUI
import Charts

/**
 * PerformanceChartCard.swift - 表現指標圖表卡片組件
 * 
 * 功能：
 * - 顯示單個表現指標的折線圖
 * - 支援趨勢分析和數值顯示
 * - 可重複使用於多個視圖
 * - 支援不同的數值範圍和單位
 */

struct PerformanceChartCard: View {
    let title: String
    let data: [(Date, Double)]
    let color: Color
    let unit: String
    let yRange: ClosedRange<Double>?
    let isLowerBetter: Bool
    
    // 滑動窗口控制
    @State private var windowSize: Int = 7
    @State private var currentWindowStart: Int = 0
    @State private var dragOffset: CGFloat = 0
    
    // 數據點選擇互動
    @State private var selectedDataPoint: (Date, Double)?
    
    init(title: String, data: [(Date, Double)], color: Color, unit: String, yRange: ClosedRange<Double>? = nil, isLowerBetter: Bool = false) {
        self.title = title
        self.data = data
        self.color = color
        self.unit = unit
        self.yRange = yRange
        self.isLowerBetter = isLowerBetter
    }
    
    // 當前窗口顯示的數據
    private var windowedData: [(Date, Double)] {
        let sortedData = data.sorted { $0.0 < $1.0 }
        guard !sortedData.isEmpty else { return [] }
        
        let actualWindowSize = min(windowSize, sortedData.count)
        let maxStartIndex = max(0, sortedData.count - actualWindowSize)
        let safeStartIndex = min(currentWindowStart, maxStartIndex)
        let endIndex = min(safeStartIndex + actualWindowSize, sortedData.count)
        
        return Array(sortedData[safeStartIndex..<endIndex])
    }
    
    // 滑動控制邏輯
    private var canSlideLeft: Bool {
        currentWindowStart > 0
    }
    
    private var canSlideRight: Bool {
        currentWindowStart + windowSize < data.count
    }
    
    private var totalWindows: Int {
        max(1, (data.count + windowSize - 1) / windowSize)
    }
    
    private var currentWindowIndex: Int {
        currentWindowStart / windowSize + 1
    }
    
    // 日期格式化器
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter
    }
    
    // 簡潔日期格式化器（包含西元年）
    private var compactDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/M/d"
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter
    }
    
    // 檢查是否為空數據狀態
    private var isEmpty: Bool {
        data.isEmpty
    }
    
    // 自適應 Y 軸範圍計算
    private var adaptiveYRange: ClosedRange<Double> {
        if let fixedRange = yRange {
            return fixedRange
        }
        
        guard !windowedData.isEmpty else {
            // 空數據時使用預設範圍
            return unit == "s" ? 0...2 : 0...100
        }
        
        let values = windowedData.map { $0.1 }
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 100
        
        // 添加 10% 的緩衝區間，讓圖表更美觀
        let padding = (maxValue - minValue) * 0.1
        let adjustedMin = max(0, minValue - padding)
        let adjustedMax = maxValue + padding
        
        // 確保最小範圍差距
        let minimumRange = 10.0
        if adjustedMax - adjustedMin < minimumRange {
            let center = (adjustedMax + adjustedMin) / 2
            return (center - minimumRange/2)...(center + minimumRange/2)
        }
        
        return adjustedMin...adjustedMax
    }
    
    private var trendIcon: String {
        guard windowedData.count >= 2 else { return "minus" }
        let first = windowedData.first!.1
        let last = windowedData.last!.1
        
        if isLowerBetter {
            return last < first ? "arrow.up" : "arrow.down"
        } else {
            return last > first ? "arrow.up" : "arrow.down"
        }
    }
    
    private var trendColor: Color {
        guard windowedData.count >= 2 else { return .gray }
        let first = windowedData.first!.1
        let last = windowedData.last!.1
        
        let isImproving = isLowerBetter ? (last < first) : (last > first)
        return isImproving ? .green : .red
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerSection
            chartSection
            statisticsSection
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .onAppear {
            initializeWindow()
        }
        .onChange(of: data.count) { _ in
            initializeWindow()
        }
    }
    
    // MARK: - 子視圖組件
    
    @ViewBuilder
    private var headerSection: some View {
        HStack {
            // 標題和指標圓點
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            // 滑動控制（僅在有多頁數據時顯示）
            if !isEmpty && data.count > windowSize {
                HStack(spacing: 8) {
                    // 向左滑動按鈕
                    Button(action: slideLeft) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(canSlideLeft ? color : .gray)
                            .font(.caption)
                            .frame(width: 24, height: 24)
                            .background(Color.gray.opacity(canSlideLeft ? 0.1 : 0.05))
                            .cornerRadius(6)
                    }
                    .disabled(!canSlideLeft)
                    
                    // 窗口位置指示器（簡化版）
                    Text("\(currentWindowIndex)/\(totalWindows)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(minWidth: 30)
                    
                    // 向右滑動按鈕
                    Button(action: slideRight) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(canSlideRight ? color : .gray)
                            .font(.caption)
                            .frame(width: 24, height: 24)
                            .background(Color.gray.opacity(canSlideRight ? 0.1 : 0.05))
                            .cornerRadius(6)
                    }
                    .disabled(!canSlideRight)
                }
            }
            
            // 單位標籤（移到滑動控制右邊）
            if !unit.isEmpty {
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
            }
            
            // 趨勢圖標或空數據狀態圖標
            if isEmpty {
                Image(systemName: "chart.line.dotted.xyaxis.descending")
                    .foregroundColor(.gray.opacity(0.6))
                    .font(.subheadline)
            } else if isLowerBetter {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            } else {
                Image(systemName: trendIcon)
                    .foregroundColor(trendColor)
                    .font(.subheadline)
            }
        }
    }
    
    @ViewBuilder
    private var chartSection: some View {
        if isEmpty {
            // 空數據狀態的圖表
            emptyChartView
        } else {
            // 有數據的正常圖表
            dataChartView
        }
    }
    
    @ViewBuilder
    private var emptyChartView: some View {
        Chart {
            // 空的圖表，只顯示軸線結構
            RuleMark(y: .value("Zero", 0))
                .foregroundStyle(.clear)
        }
        .frame(height: 160)
        .chartYScale(domain: adaptiveYRange)
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.gray.opacity(0.2))
                AxisTick()
                    .foregroundStyle(.clear)
                AxisValueLabel()
                    .foregroundStyle(.clear)
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.gray.opacity(0.2))
                AxisValueLabel()
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .overlay(
            // 空數據提示
            VStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(color.opacity(0.3))
                
                Text("尚無數據")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        )
    }
    
    @ViewBuilder
    private var dataChartView: some View {
        Chart {
            ForEach(Array(windowedData.enumerated()), id: \.0) { index, point in
                LineMark(
                    x: .value("日期", point.0),
                    y: .value("數值", point.1)
                )
                .foregroundStyle(color)
                .lineStyle(StrokeStyle(lineWidth: 3.0))
                .interpolationMethod(.catmullRom)
                
                PointMark(
                    x: .value("日期", point.0),
                    y: .value("數值", point.1)
                )
                .foregroundStyle(color)
                .symbolSize(isPointSelected(point) ? 120 : 60)
                .opacity(isPointSelected(point) ? 1.0 : 0.8)
                
                // 顯示選中數據點的簡潔標籤
                if isPointSelected(point) {
                    PointMark(
                        x: .value("日期", point.0),
                        y: .value("數值", point.1)
                    )
                    .annotation(position: .top) {
                        VStack(spacing: 1) {
                            Text(compactDateFormatter.string(from: point.0))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(String(format: "%.1f", point.1)) \(unit)")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(6)
                        .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1)
                    }
                }
            }
        }
        .frame(height: 160)
        .chartYScale(domain: adaptiveYRange)
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel(format: .dateTime.month().day())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.gray.opacity(0.3))
                AxisValueLabel()
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        updateSelectedPoint(at: location, proxy: proxy, geometry: geometry)
                    }
            }
        }
        .overlay(
            // 添加微妙的滑動提示
            data.count > windowSize ? 
            HStack {
                // 左側漸變提示
                if canSlideLeft {
                    LinearGradient(
                        colors: [Color.blue.opacity(0.1), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 20)
                }
                
                Spacer()
                
                // 右側漸變提示
                if canSlideRight {
                    LinearGradient(
                        colors: [Color.clear, Color.blue.opacity(0.1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 20)
                }
            }
            .allowsHitTesting(false) : nil
        )
        .simultaneousGesture(
            DragGesture()
                .onChanged { value in
                    // 只有在主要是水平滑動時才更新偏移量
                    let horizontalDistance = abs(value.translation.width)
                    let verticalDistance = abs(value.translation.height)
                    
                    if horizontalDistance > verticalDistance {
                        dragOffset = value.translation.width
                    }
                }
                .onEnded { value in
                    // 只有當水平滑動距離明顯大於垂直滑動距離時才處理圖表滑動
                    let horizontalDistance = abs(value.translation.width)
                    let verticalDistance = abs(value.translation.height)
                    
                    if horizontalDistance > verticalDistance && horizontalDistance > 50 {
                        handleSwipeGesture(translation: value.translation.width)
                    }
                    dragOffset = 0
                }
        )
    }
    
    @ViewBuilder
    private var statisticsSection: some View {
        if isEmpty {
            // 空數據狀態的統計區域
            VStack(alignment: .leading, spacing: 6) {
                Text("-- \(unit)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                
                HStack(spacing: 4) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text("等待數據")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                }
            }
        } else if let latestValue = windowedData.last?.1, let firstValue = windowedData.first?.1 {
            VStack(alignment: .leading, spacing: 6) {
                Text("\(String(format: "%.1f", latestValue)) \(unit)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                let change = isLowerBetter ? firstValue - latestValue : latestValue - firstValue
                let changePercent = abs(change) / firstValue * 100
                
                if change != 0 {
                    HStack(spacing: 4) {
                        Image(systemName: change > 0 ? "arrow.up" : "arrow.down")
                            .font(.caption2)
                            .foregroundColor(change > 0 ? .green : .red)
                        Text("\(String(format: "%.1f%%", changePercent))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(change > 0 ? .green : .red)
                        if data.count > windowSize {
                            Text("(當前窗口)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 滑動控制方法
    
    private func initializeWindow() {
        if data.count > windowSize {
            // 預設顯示最新的數據
            currentWindowStart = max(0, data.count - windowSize)
        } else {
            currentWindowStart = 0
        }
    }
    
    private func slideLeft() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if canSlideLeft {
                currentWindowStart = max(0, currentWindowStart - 1)
                // 清除選中的點，因為可能不在新窗口中
                selectedDataPoint = nil
            }
        }
    }
    
    private func slideRight() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if canSlideRight {
                currentWindowStart = min(data.count - windowSize, currentWindowStart + 1)
                // 清除選中的點，因為可能不在新窗口中
                selectedDataPoint = nil
            }
        }
    }
    
    private func handleSwipeGesture(translation: CGFloat) {
        let threshold: CGFloat = 50
        
        if translation > threshold {
            // 向右滑動 - 查看較舊的數據
            slideLeft()
        } else if translation < -threshold {
            // 向左滑動 - 查看較新的數據
            slideRight()
        }
    }
    
    // MARK: - 圖表互動方法
    
    private func isPointSelected(_ point: (Date, Double)) -> Bool {
        guard let selected = selectedDataPoint else { return false }
        return selected.0 == point.0 && selected.1 == point.1
    }

    private func updateSelectedPoint(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        let frame = geometry[proxy.plotAreaFrame]
        let xPosition = location.x - frame.origin.x

        // 從點擊位置的 x 座標獲取對應的日期
        guard let date: Date = proxy.value(atX: xPosition) else {
            return
        }

        // 找到最接近該日期的數據點
        var minDistance: TimeInterval = .greatestFiniteMagnitude
        var closestPoint: (Date, Double)? = nil
        
        for point in windowedData {
            let distance = abs(point.0.timeIntervalSince(date))
            if distance < minDistance {
                minDistance = distance
                closestPoint = point
            }
        }

        // 更新選中的數據點
        if let point = closestPoint {
            withAnimation(.easeInOut(duration: 0.1)) {
                selectedDataPoint = point
            }
        }
    }
    
    
}

// MARK: - Preview
struct PerformanceChartCard_Previews: PreviewProvider {
    static var previews: some View {
        // 創建更多測試數據來展示滑動功能
        let extendedData = Array(Array(0..<15).map { i in
            (Date().addingTimeInterval(TimeInterval(-i*24*3600)), Double.random(in: 70...95))
        }.reversed())
        
        let reactionTimeData = Array(Array(0..<12).map { i in
            (Date().addingTimeInterval(TimeInterval(-i*24*3600)), Double.random(in: 800...1500))
        }.reversed())
        
        VStack(spacing: 20) {
            // 有滑動功能的圖表 (數據 > 7 筆)
            PerformanceChartCard(
                title: "肌力 (可滑動)",
                data: extendedData,
                color: .red,
                unit: "分"
            )
            
            // 較少數據的圖表 (數據 ≤ 7 筆)
            PerformanceChartCard(
                title: "穩定度 (無滑動)",
                data: Array(extendedData.prefix(5)),
                color: .blue,
                unit: "分"
            )
            
            // 空數據圖表
            PerformanceChartCard(
                title: "規律性 (空數據)",
                data: [],
                color: .green,
                unit: "分"
            )
            
            // 反應時間圖表
            PerformanceChartCard(
                title: "反應時間 (可滑動)",
                data: reactionTimeData.map { ($0.0, $0.1 / 1000.0) },
                color: .orange,
                unit: "s",
                isLowerBetter: true
            )
            
            // 柔軟度空數據圖表
            PerformanceChartCard(
                title: "柔軟度 (空數據)",
                data: [],
                color: .mint,
                unit: "分"
            )
        }
        .frame(width: 420)
        .padding()
        .background(Color.gray.opacity(0.1))
        .previewLayout(.sizeThatFits)
    }
}