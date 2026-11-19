import Foundation

/// 以 "yyyy-MM-dd" 字符串表示的日历日，与网页版数据格式一致。
enum Day {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    private static let isoFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy年M月d日"
        return formatter
    }()

    private static let shortFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "M月d日"
        return formatter
    }()

    static func today() -> String { string(from: Date()) }

    static func string(from date: Date) -> String {
        isoFormatter.timeZone = .current
        return isoFormatter.string(from: date)
    }

    static func date(from value: String?) -> Date? {
        guard let value, isValid(value) else { return nil }
        isoFormatter.timeZone = .current
        return isoFormatter.date(from: value)
    }

    static func isValid(_ value: String) -> Bool {
        let parts = value.split(separator: "-")
        guard parts.count == 3, parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]),
              (1900...9800).contains(year), (1...12).contains(month), day >= 1 else { return false }
        var components = DateComponents()
        components.year = year
        components.month = month
        guard let first = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: first) else { return false }
        return range.contains(day)
    }

    static func display(_ value: String?) -> String {
        guard let date = date(from: value) else { return "未记录" }
        displayFormatter.timeZone = .current
        return displayFormatter.string(from: date)
    }

    static func short(_ value: String?) -> String {
        guard let date = date(from: value) else { return "—" }
        shortFormatter.timeZone = .current
        return shortFormatter.string(from: date)
    }

    /// 加月份；超出当月天数时取当月最后一天（与网页版 addMonths 一致）。
    static func adding(months: Int, to value: String) -> String? {
        guard let date = date(from: value),
              let result = calendar.date(byAdding: .month, value: months, to: date) else { return nil }
        return string(from: result)
    }

    static func adding(days: Int, to value: String) -> String? {
        guard let date = date(from: value),
              let result = calendar.date(byAdding: .day, value: days, to: date) else { return nil }
        return string(from: result)
    }

    static func daysBetween(_ from: String, _ to: String) -> Int? {
        guard let start = date(from: from), let end = date(from: to) else { return nil }
        return calendar.dateComponents([.day], from: start, to: end).day
    }
}
