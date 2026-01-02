import Foundation
import Combine
import SwiftUI

class StorageManager: ObservableObject {
    static let shared = StorageManager()
    @Published var records: [GameRecord] = []
    @Published var userRating: Int = 1200
    
    private let currentFileName = "save_data_v4.json"
    private let legacyFileNames = ["save_data_v3.json", "save_data_v2.json", "save_data.json"]
    
    init() { loadData() }
    
    private func getFileURL(name: String) -> URL {
        if let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") {
            if !FileManager.default.fileExists(atPath: iCloudURL.path) {
                try? FileManager.default.createDirectory(at: iCloudURL, withIntermediateDirectories: true, attributes: nil)
            }
            return iCloudURL.appendingPathComponent(name)
        } else {
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(name)
        }
    }
    
    struct StorageContainer: Codable {
        let rating: Int
        let records: [GameRecord]
    }
    
    func saveGame(_ record: GameRecord) {
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
        } else {
            records.insert(record, at: 0)
        }
        persist()
    }
    
    func toggleFavorite(for id: UUID) {
        if let index = records.firstIndex(where: { $0.id == id }) {
            records[index].isFavorite.toggle()
            if records[index].isFavorite { records[index].isArchived = true }
            persist()
        }
    }
    
    func setArchived(for id: UUID, isArchived: Bool) {
        if let index = records.firstIndex(where: { $0.id == id }) {
            records[index].isArchived = isArchived
            if !isArchived { records[index].isFavorite = false }
            persist()
        }
    }
    
    func batchDelete(ids: Set<UUID>) {
        records.removeAll { ids.contains($0.id) }
        persist()
    }
    
    func batchFavorite(ids: Set<UUID>) {
        for i in 0..<records.count {
            if ids.contains(records[i].id) {
                records[i].isFavorite = true
                records[i].isArchived = true
            }
        }
        persist()
    }
    
    func deleteRecord(at offsets: IndexSet) {
        records.remove(atOffsets: offsets)
        persist()
    }
    
    func deleteRecord(id: UUID) {
        if let index = records.firstIndex(where: { $0.id == id }) {
            records.remove(at: index)
            persist()
        }
    }
    
    func updateUserRating(add points: Int) {
        userRating += points
        persist()
    }
    
    func loadData() {
        let currentURL = getFileURL(name: currentFileName)
        
        // 1. 尝试加载当前版本 (v4)
        if FileManager.default.fileExists(atPath: currentURL.path),
           let data = try? Data(contentsOf: currentURL),
           let decoded = try? JSONDecoder().decode(StorageContainer.self, from: data) {
            DispatchQueue.main.async {
                self.records = decoded.records.sorted(by: { $0.lastPlayedTime > $1.lastPlayedTime })
                self.userRating = decoded.rating
            }
            return
        }
        
        // 2. 迁移逻辑
        print("⚠️ Current save not found. Attempting migration...")
        for legacyName in legacyFileNames {
            let legacyURL = getFileURL(name: legacyName)
            if FileManager.default.fileExists(atPath: legacyURL.path) {
                print("✅ Found legacy save: \(legacyName)")
                if let data = try? Data(contentsOf: legacyURL),
                   let decoded = try? JSONDecoder().decode(StorageContainer.self, from: data) {
                    
                    DispatchQueue.main.async {
                        // [关键修复] 将所有迁移过来的旧记录强制标记为已存档
                        // 因为在旧版本中，只要在列表里就是"已保存"的
                        var migratedRecords = decoded.records
                        for i in 0..<migratedRecords.count {
                            migratedRecords[i].isArchived = true
                        }
                        
                        self.records = migratedRecords.sorted(by: { $0.lastPlayedTime > $1.lastPlayedTime })
                        self.userRating = decoded.rating
                        // 立即保存为 v4 格式，完成迁移
                        self.persist()
                        print("🚀 Migration successful. All legacy records marked as archived.")
                    }
                    return
                }
            }
        }
    }
    
    private func persist() {
        let container = StorageContainer(rating: userRating, records: records)
        if let data = try? JSONEncoder().encode(container) {
            try? data.write(to: getFileURL(name: currentFileName))
        }
    }
}

