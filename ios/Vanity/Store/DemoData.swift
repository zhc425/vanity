import Foundation
import UIKit

/// 仅在以 `-VanityDemo YES` 启动时使用（CI 截图、SwiftUI 预览），数据写在临时目录，不会碰到真实藏品。
enum DemoData {
    static var isEnabled: Bool { UserDefaults.standard.bool(forKey: "VanityDemo") }
    static var screen: String? { UserDefaults.standard.string(forKey: "VanityDemoScreen") }
    static let featuredID = "demo-lipstick-1"

    @MainActor
    static func makeStore() -> CollectionStore {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("VanityDemo-\(UUID().uuidString)", isDirectory: true)
        let store = CollectionStore(directory: directory)
        store.replaceAll(records())
        for (id, image) in [(featuredID, "cat-lipstick"), ("demo-blush-1", "cat-blush"), ("demo-cream-1", "cat-cream"),
                            ("demo-powder-1", "cat-loose-powder"), ("demo-foundation-1", "cat-foundation")] {
            if let photo = UIImage(named: image) { store.savePhoto(photo, for: id) }
        }
        store.dismissNotice()
        return store
    }

    private static func day(_ offset: Int) -> String {
        Day.adding(days: offset, to: Day.today()) ?? Day.today()
    }

    private static func uses(_ offsets: [Int]) -> [UseEntry] {
        offsets.enumerated().map { UseEntry(id: "u\($0.offset)", date: day(-$0.element)) }
    }

    static func records() -> [CollectionRecord] {
        func make(_ id: String, _ category: CategoryID, _ name: String, brand: String, shade: String? = nil,
                  opened: Int? = nil, pao: Int? = nil, package: Int? = nil, price: Int? = nil,
                  uses useDays: [Int] = [], note: String? = nil) -> CollectionRecord {
            var record = CollectionRecord(id: id, categoryId: category, name: name)
            record.brand = brand
            record.shade = shade
            record.openedDate = opened.map { day(-$0) }
            record.paoMonths = pao
            record.packageExpiryDate = package.map { day($0) }
            record.purchasedDate = opened.map { day(-$0 - 10) }
            record.price = price.map { Money(minorUnits: $0 * 100) }
            record.uses = useDays.isEmpty ? nil : uses(useDays)
            record.note = note
            return record
        }
        return [
            make(featuredID, .lipstick, "丝绒唇膏", brand: "Chanel", shade: "#58 Rouge Vie", opened: 120, pao: 18, price: 390,
                 uses: [0, 1, 3, 4, 6, 9, 12, 15, 20, 26, 33, 41], note: "秋冬日常色，薄涂很温柔。"),
            make("demo-blush-1", .blush, "柔光腮红", brand: "Chanel", shade: "Rose Initiale", opened: 700, pao: 24, price: 420, uses: [2, 8, 19]),
            make("demo-cream-1", .cream, "A.G.E. 修护面霜", brand: "SkinCeuticals", opened: 352, pao: 12, price: 1180, uses: [0, 1, 2, 3]),
            make("demo-powder-1", .loosePowder, "四宫格散粉", brand: "Givenchy", shade: "No.1", opened: 400, pao: 24, price: 560, uses: [1, 5]),
            make("demo-foundation-1", .foundation, "恒久粉底液", brand: "YSL", shade: "B20", package: -6, price: 590, uses: [30]),
            make("demo-puff-1", .puff, "棉花糖粉扑", brand: "Momo's Workshop", opened: 80, pao: 3, price: 39, uses: [0, 2, 4]),
            make("demo-mask-1", .mask, "补水面膜", brand: "Fan Beauty Diary", package: 300, price: 129)
        ]
    }
}
