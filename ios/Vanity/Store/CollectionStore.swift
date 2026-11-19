import Foundation
import Observation
import SwiftUI
import UIKit

@MainActor
@Observable
final class CollectionStore {
    enum LoadProblem: Equatable {
        case none
        case corrupt
        case skipped(Int)
    }

    struct Notice: Identifiable, Equatable {
        let id = UUID()
        let text: String
        var undo: UndoAction?
    }

    enum UndoAction: Equatable {
        case use(recordID: String, useID: String)
        case delete(CollectionRecord)
    }

    private(set) var records: [CollectionRecord] = []
    private(set) var loadProblem: LoadProblem = .none
    var notice: Notice?
    var saveError: String?

    @ObservationIgnored private let directory: URL
    private var fileURL: URL { directory.appendingPathComponent("collection.json") }
    var photosDirectory: URL { directory.appendingPathComponent("Photos", isDirectory: true) }
    @ObservationIgnored private var noticeTask: Task<Void, Never>?

    init(directory: URL? = nil) {
        let base = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Vanity", isDirectory: true)
        self.directory = base
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: base.appendingPathComponent("Photos", isDirectory: true), withIntermediateDirectories: true)
        load()
    }

    // MARK: 读写

    func load() {
        guard let data = try? Data(contentsOf: fileURL) else {
            records = []
            loadProblem = .none
            return
        }
        do {
            let result = try RecordParser.parse(data)
            records = result.records
            loadProblem = result.skipped > 0 ? .skipped(result.skipped) : .none
        } catch {
            // 保留损坏文件，避免被覆盖
            let backup = directory.appendingPathComponent("collection.corrupt-\(Int(Date().timeIntervalSince1970)).json")
            try? FileManager.default.copyItem(at: fileURL, to: backup)
            records = []
            loadProblem = .corrupt
        }
    }

    private func persist(_ next: [CollectionRecord]) -> Bool {
        guard next.count <= RecordParser.maxRecords else {
            saveError = "藏品数量已达上限（\(RecordParser.maxRecords) 件），未能保存"
            return false
        }
        do {
            let data = try Self.encoder.encode(Payload(version: 2, records: next))
            try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            records = next
            saveError = nil
            ExpiryReminders.shared.reschedule(for: next)
            return true
        } catch {
            saveError = "未能保存，请重试（\(error.localizedDescription)）"
            return false
        }
    }

    struct Payload: Codable {
        let version: Int
        let records: [CollectionRecord]
    }

    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return encoder
    }()

    // MARK: 查询

    func record(id: String) -> CollectionRecord? { records.first { $0.id == id } }

    func records(in category: CategoryID) -> [CollectionRecord] { records.filter { $0.categoryId == category } }

    var expiringSoon: [CollectionRecord] {
        let today = Day.today()
        return records
            .filter { ($0.expiry(today: today).daysLeft ?? .max) <= 30 }
            .sorted { ($0.expiry(today: today).daysLeft ?? 0) < ($1.expiry(today: today).daysLeft ?? 0) }
    }

    // MARK: 修改

    /// 整体替换（用于演示数据）
    func replaceAll(_ next: [CollectionRecord]) { _ = persist(next) }

    @discardableResult
    func add(_ record: CollectionRecord) -> Bool {
        guard persist([record] + records) else { return false }
        show("藏品已添加")
        return true
    }

    @discardableResult
    func update(_ record: CollectionRecord, message: String = "藏品已更新") -> Bool {
        guard let index = records.firstIndex(where: { $0.id == record.id }) else { return false }
        var next = records
        next[index] = record
        guard persist(next) else { return false }
        show(message)
        return true
    }

    func delete(id: String) {
        guard let record = record(id: id) else { return }
        guard persist(records.filter { $0.id != id }) else { return }
        show("已删除「\(record.name)」", undo: .delete(record))
    }

    func logUse(id: String, on date: String = Day.today()) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }
        var next = records
        let use = UseEntry(id: CollectionRecord.newID(), date: date)
        next[index].uses = (next[index].uses ?? []) + [use]
        guard persist(next) else { return }
        show(date == Day.today() ? "已记下今天的一次使用" : "已补记 \(Day.short(date)) 的使用", undo: .use(recordID: id, useID: use.id))
    }

    func removeUse(recordID: String, useID: String, announce: Bool = true) {
        guard let index = records.firstIndex(where: { $0.id == recordID }) else { return }
        var next = records
        next[index].uses = next[index].uses?.filter { $0.id != useID }
        if next[index].uses?.isEmpty == true { next[index].uses = nil }
        guard persist(next) else { return }
        if announce { show("已删除这次使用记录") }
    }

    func performUndo() {
        guard let undo = notice?.undo else { return }
        switch undo {
        case let .use(recordID, useID):
            removeUse(recordID: recordID, useID: useID, announce: false)
            show("已撤销这次使用")
        case let .delete(record):
            if persist([record] + records) { show("已恢复「\(record.name)」") }
        }
    }

    // MARK: 导入导出

    func exportFile() -> URL? {
        let stamp = Day.today()
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("vanity-backup-\(stamp).json")
        do {
            let data = try Self.encoder.encode(Payload(version: 2, records: records))
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            saveError = "导出失败：\(error.localizedDescription)"
            return nil
        }
    }

    /// 合并导入：已有的同 ID 藏品保持不变。
    func importBackup(from url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let data = try Data(contentsOf: url)
            let result = try RecordParser.parse(data)
            let existing = Set(records.map(\.id))
            let incoming = result.records.filter { !existing.contains($0.id) }.map { record -> CollectionRecord in
                var record = record
                if let file = record.photoFile,
                   !FileManager.default.fileExists(atPath: photosDirectory.appendingPathComponent(file).path) {
                    record.photoFile = nil
                }
                return record
            }
            guard !incoming.isEmpty else {
                show(result.records.isEmpty ? "文件里没有可导入的藏品" : "这些藏品都已在本机")
                return
            }
            if persist(records + incoming) {
                let skippedText = result.skipped > 0 ? "，跳过 \(result.skipped) 条无效记录" : ""
                show("已导入 \(incoming.count) 件藏品\(skippedText)")
            }
        } catch {
            show("无法读取这个文件，请选择 Vanity 导出的 JSON")
        }
    }

    // MARK: 照片

    func savePhoto(_ image: UIImage, for recordID: String) {
        guard var record = record(id: recordID) else { return }
        let resized = image.resized(maxSide: 1600)
        guard let data = resized.jpegData(compressionQuality: 0.85) else { return }
        let name = "\(recordID)-\(Int(Date().timeIntervalSince1970)).jpg"
        do {
            try data.write(to: photosDirectory.appendingPathComponent(name), options: .atomic)
            let old = record.photoFile
            record.photoFile = name
            if update(record, message: "照片已更新") { removePhotoFile(old) }
        } catch {
            saveError = "照片保存失败：\(error.localizedDescription)"
        }
    }

    func removePhoto(for recordID: String) {
        guard var record = record(id: recordID), let old = record.photoFile else { return }
        record.photoFile = nil
        if update(record, message: "照片已移除") { removePhotoFile(old) }
    }

    func photo(for record: CollectionRecord) -> UIImage? {
        guard let file = record.photoFile else { return nil }
        return PhotoCache.shared.image(at: photosDirectory.appendingPathComponent(file))
    }

    private func removePhotoFile(_ name: String?) {
        guard let name else { return }
        let url = photosDirectory.appendingPathComponent(name)
        PhotoCache.shared.remove(url)
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: 提示

    func show(_ text: String, undo: UndoAction? = nil) {
        noticeTask?.cancel()
        withAnimation(.snappy) { notice = Notice(text: text, undo: undo) }
        noticeTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(undo == nil ? 2.6 : 5))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.2)) { self?.notice = nil }
        }
    }

    func dismissNotice() {
        noticeTask?.cancel()
        withAnimation(.easeOut(duration: 0.2)) { notice = nil }
    }
}

// MARK: - 照片缓存

final class PhotoCache {
    static let shared = PhotoCache()
    private let cache = NSCache<NSURL, UIImage>()

    func image(at url: URL) -> UIImage? {
        if let cached = cache.object(forKey: url as NSURL) { return cached }
        guard let image = UIImage(contentsOfFile: url.path) else { return nil }
        cache.setObject(image, forKey: url as NSURL)
        return image
    }

    func remove(_ url: URL) { cache.removeObject(forKey: url as NSURL) }
}

extension UIImage {
    func resized(maxSide: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxSide else { return self }
        let scale = maxSide / longest
        let target = CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
