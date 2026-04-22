// FileShareManager.swift
import Foundation
import UIKit

/// 文件共享管理器 - 處理文件共享和導出功能
class FileShareManager {
    /// 單例實例
    static let shared = FileShareManager()
    
    /// 文件管理器
    private let fileManager = FileManager.default
    
    /// 私有初始化方法
    private init() {}
    
    /// 共享指定路徑的文件
    /// - Parameters:
    ///   - url: 文件的 URL
    ///   - completion: 完成回調，返回成功或失敗結果
    func shareFile(at url: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        // 檢查文件是否存在
        guard fileManager.fileExists(atPath: url.path) else {
            let error = NSError(domain: "FileShareManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "文件不存在"])
            completion(.failure(error))
            return
        }
        
        // 在主線程上執行 UI 操作
        DispatchQueue.main.async {
            // 創建活動視圖控制器
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            
            // 配置活動視圖控制器
            activityVC.excludedActivityTypes = [
                .assignToContact,
                .addToReadingList
            ]
            
            // 添加完成處理程序
            activityVC.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
                if let error = error {
                    print("共享時發生錯誤: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                if completed {
                    print("共享成功完成，活動類型: \(activityType?.rawValue ?? "未知")")
                    completion(.success(()))
                } else {
                    print("共享被取消或未完成")
                    completion(.success(()))
                }
            }
            
            // 尋找當前的 UIViewController
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                
                // 找到最頂層的視圖控制器
                var topController = rootViewController
                while let presentedController = topController.presentedViewController {
                    topController = presentedController
                }
                
                // 在 iPad 上，需要設置彈出位置
                if let popoverController = activityVC.popoverPresentationController {
                    popoverController.sourceView = topController.view
                    popoverController.sourceRect = CGRect(x: topController.view.bounds.midX, y: topController.view.bounds.midY, width: 0, height: 0)
                    popoverController.permittedArrowDirections = []
                }
                
                // 顯示活動視圖控制器
                topController.present(activityVC, animated: true)
            } else {
                let error = NSError(domain: "FileShareManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "無法顯示共享選項"])
                completion(.failure(error))
            }
        }
    }
    
    /// 保存數據到文件並共享
    /// - Parameters:
    ///   - data: 要保存的數據
    ///   - fileName: 文件名
    ///   - completion: 完成回調，返回成功或失敗結果
    func saveAndShareData(_ data: Data, fileName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            // 獲取 Documents 目錄路徑
            guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                throw NSError(domain: "FileShareManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "無法獲取文件路徑"])
            }
            
            // 創建文件 URL
            let fileURL = documentsPath.appendingPathComponent(fileName)
            
            // 寫入數據到文件
            try data.write(to: fileURL)
            
            // 檢查文件是否存在
            if fileManager.fileExists(atPath: fileURL.path) {
                print("文件已成功保存到: \(fileURL.path)")
                
                // 延遲以確保文件系統操作完成
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.shareFile(at: fileURL, completion: completion)
                }
            } else {
                throw NSError(domain: "FileShareManager", code: 4, userInfo: [NSLocalizedDescriptionKey: "文件保存失敗: 文件不存在"])
            }
        } catch {
            completion(.failure(error))
        }
    }
} 