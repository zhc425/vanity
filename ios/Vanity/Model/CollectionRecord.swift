import Foundation

struct Money: Codable, Hashable {
    var minorUnits: Int
    var currency: String = "CNY"

    var display: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: NSNumber(value: Double(minorUnits) / 100)) ?? "¥\(minorUnits / 100)"
    }
}

struct UseEntry: Codable, Hashable, Identifiable {
    var id: String
    var date: String
}

/// 与网页版 `vanity.collection.v2` 相同的数据结构，导出的 JSON 两端通用。
struct CollectionRecord: Codable, Hashable, Identifiable {
    var id: String
    var categoryId: CategoryID
    var name: String
    var brand: String?
    var shade: String?
    var purchasedDate: String?
    var packageExpiryDate: String?
    var openedDate: String?
    var paoMonths: Int?
    var price: Money?
    var note: String?
    var usageCount: Int?
    var uses: [UseEntry]?
    var imageUrl: String?
    var imageAlt: String?
    /// iOS 专用：本机照片文件名（存放在 Application Support/Photos）
    var photoFile: String?
    /// iOS 专用：创建时间，用于"最近添加"排序
    var createdAt: Date?

    init(id: String = Self.newID(), categoryId: CategoryID, name: String) {
        self.id = id
        self.categoryId = categoryId
        self.name = name
        self.createdAt = Date()
    }

    static func newID() -> String { UUID().uuidString.lowercased() }

    var useCount: Int { (usageCount ?? 0) + (uses?.count ?? 0) }

    var identity: String {
        [brand, shade].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " / ")
    }

    var lastUsed: String? { uses?.map(\.date).max() }

    func expiry(today: String = Day.today()) -> Expiry { Expiry(record: self, today: today) }

    func matches(_ query: String) -> Bool {
        let query = query.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return true }
        return [name, brand ?? "", shade ?? "", note ?? ""].contains { $0.localizedCaseInsensitiveContains(query) }
    }
}

// MARK: - 到期计算（移植自网页版 getExpiry）

struct Expiry: Hashable {
    enum Tone: Hashable { case warning, expired }
    struct Status: Hashable {
        let label: String
        let tone: Tone
    }

    let date: String?
    let basis: String?
    let prompt: String?
    let status: Status?
    let daysLeft: Int?

    init(record: CollectionRecord, today: String) {
        let afterOpening: String? = {
            guard let opened = record.openedDate, let months = record.paoMonths else { return nil }
            return Day.adding(months: months, to: opened)
        }()
        let byPackage: Bool = {
            guard let package = record.packageExpiryDate else { return false }
            guard let afterOpening else { return true }
            return package <= afterOpening
        }()
        let date = byPackage ? record.packageExpiryDate : afterOpening
        self.date = date
        self.basis = date == nil ? nil : (byPackage ? "按包装有效期" : "按开封后期限")
        if record.openedDate != nil && record.paoMonths == nil {
            self.prompt = "补录开封后可用月数"
        } else if date == nil {
            self.prompt = "可补录包装到期日，或记录开封"
        } else {
            self.prompt = nil
        }
        let days = date.flatMap { Day.daysBetween(today, $0) }
        self.daysLeft = days
        switch days {
        case .some(let d) where d < 0: self.status = Status(label: "已过期", tone: .expired)
        case .some(0): self.status = Status(label: "今日到期", tone: .warning)
        case .some(let d) where d <= 30: self.status = Status(label: "还有 \(d) 天到期", tone: .warning)
        default: self.status = nil
        }
    }
}

// MARK: - 宽松解析（与网页版 normalizeRecord 规则一致）

enum RecordParser {
    static let maxRecords = 2000
    static let maxUses = 10000
    private static let idCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-")

    static func isValidID(_ value: String) -> Bool {
        (1...80).contains(value.count) && value.unicodeScalars.allSatisfy { idCharacters.contains($0) }
    }

    /// 接受 `{version, records}` 或直接的数组；返回解析出的藏品与被跳过的条数。
    static func parse(_ data: Data) throws -> (records: [CollectionRecord], skipped: Int) {
        let object = try JSONSerialization.jsonObject(with: data)
        let list: [Any]
        if let dict = object as? [String: Any], let records = dict["records"] as? [Any] {
            list = records
        } else if let array = object as? [Any] {
            list = array
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
        var seen = Set<String>()
        var records: [CollectionRecord] = []
        var skipped = 0
        for item in list {
            if let dict = item as? [String: Any], dict["demo"] as? Bool == true { continue }
            guard let record = record(from: item), !seen.contains(record.id) else {
                skipped += 1
                continue
            }
            seen.insert(record.id)
            records.append(record)
        }
        return (records, skipped)
    }

    static func record(from value: Any) -> CollectionRecord? {
        guard let dict = value as? [String: Any],
              let id = dict["id"] as? String, isValidID(id),
              let categoryRaw = dict["categoryId"] as? String, let category = CategoryID(rawValue: categoryRaw),
              let name = text(dict["name"], limit: 100) else { return nil }
        var record = CollectionRecord(id: id, categoryId: category, name: name)
        record.createdAt = nil
        record.brand = text(dict["brand"], limit: 80)
        record.shade = text(dict["shade"], limit: 60)
        record.note = text(dict["note"], limit: 2000)
        record.purchasedDate = date(dict["purchasedDate"])
        record.packageExpiryDate = date(dict["packageExpiryDate"])
        record.openedDate = date(dict["openedDate"])
        record.paoMonths = integer(dict["paoMonths"], 1...120)
        if let count = integer(dict["usageCount"], 0...100_000), count > 0 { record.usageCount = count }
        if let price = dict["price"] as? [String: Any],
           let minor = integer(price["minorUnits"], 0...999_999_999),
           (price["currency"] as? String) == "CNY" {
            record.price = Money(minorUnits: minor)
        }
        if let uses = dict["uses"] as? [Any] {
            var seen = Set<String>()
            var list: [UseEntry] = []
            for case let use as [String: Any] in uses {
                guard list.count < maxUses,
                      let useID = use["id"] as? String, isValidID(useID), !seen.contains(useID),
                      let useDate = date(use["date"]) else { continue }
                seen.insert(useID)
                list.append(UseEntry(id: useID, date: useDate))
            }
            if !list.isEmpty { record.uses = list }
        }
        record.imageUrl = text(dict["imageUrl"], limit: 2048)
        record.imageAlt = text(dict["imageAlt"], limit: 200)
        if let file = dict["photoFile"] as? String, isValidPhotoName(file) { record.photoFile = file }
        if let created = dict["createdAt"] as? Double { record.createdAt = Date(timeIntervalSinceReferenceDate: created) }
        return record
    }

    static func isValidPhotoName(_ value: String) -> Bool {
        value.count <= 120 && !value.contains("/") && !value.contains("..")
    }

    private static func text(_ value: Any?, limit: Int) -> String? {
        guard let string = value as? String else { return nil }
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || trimmed.count > limit ? nil : trimmed
    }

    private static func date(_ value: Any?) -> String? {
        guard let string = value as? String, Day.isValid(string) else { return nil }
        return string
    }

    private static func integer(_ value: Any?, _ range: ClosedRange<Int>) -> Int? {
        guard let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID() else { return nil }
        let double = number.doubleValue
        guard double.rounded() == double, let int = Int(exactly: double), range.contains(int) else { return nil }
        return int
    }
}
