import Foundation
import UserNotifications

/// 到期提醒：到期前 7 天与到期当天上午 9 点各提醒一次。
final class ExpiryReminders {
    static let shared = ExpiryReminders()
    static let enabledKey = "vanity.reminders.enabled"
    private let center = UNUserNotificationCenter.current()
    private let prefix = "vanity.expiry."

    var isEnabled: Bool { UserDefaults.standard.bool(forKey: Self.enabledKey) }

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func disable() {
        center.getPendingNotificationRequests { [prefix, center] requests in
            let ids = requests.map(\.identifier).filter { $0.hasPrefix(prefix) }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    func reschedule(for records: [CollectionRecord]) {
        guard isEnabled else { return }
        let today = Day.today()
        var plans: [(id: String, day: String, title: String, body: String)] = []
        for record in records {
            guard let date = record.expiry(today: today).date else { continue }
            let label = [record.brand, record.name].compactMap { $0 }.joined(separator: " ")
            if let week = Day.adding(days: -7, to: date), week > today {
                plans.append((prefix + record.id + ".week", week, "还有 7 天到期", "\(label) 将在 \(Day.display(date)) 到期"))
            }
            if date >= today {
                plans.append((prefix + record.id + ".day", date, "今日到期", "\(label) 今天到期，记得检查状态"))
            }
        }
        // 系统最多保留 64 条待发通知，只排最近的 60 条
        let chosen: [(id: String, components: DateComponents, title: String, body: String)] = plans
            .sorted { $0.day < $1.day }
            .prefix(60)
            .compactMap { plan in
                guard let date = Day.date(from: plan.day) else { return nil }
                var components = Day.calendar.dateComponents([.year, .month, .day], from: date)
                components.hour = 9
                return (plan.id, components, plan.title, plan.body)
            }
        center.getPendingNotificationRequests { [prefix, center] requests in
            let old = requests.map(\.identifier).filter { $0.hasPrefix(prefix) }
            center.removePendingNotificationRequests(withIdentifiers: old)
            for plan in chosen {
                let content = UNMutableNotificationContent()
                content.title = plan.title
                content.body = plan.body
                content.sound = .default
                let trigger = UNCalendarNotificationTrigger(dateMatching: plan.components, repeats: false)
                center.add(UNNotificationRequest(identifier: plan.id, content: content, trigger: trigger))
            }
        }
    }
}
