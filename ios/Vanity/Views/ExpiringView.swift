import SwiftUI

/// 到期页：按紧急程度分组，参考「提醒事项」的智能列表。
struct ExpiringView: View {
    @Environment(CollectionStore.self) private var store
    @State private var path: [Route] = []
    @Namespace private var zoom

    private struct Bucket: Identifiable {
        let id: String
        let title: String
        let footer: String?
        let records: [CollectionRecord]
    }

    private var groups: [Bucket] {
        let today = Day.today()
        let dated = store.records
            .map { (record: $0, expiry: $0.expiry(today: today)) }
            .filter { $0.expiry.date != nil }
            .sorted { ($0.expiry.date ?? "") < ($1.expiry.date ?? "") }
        let expired = dated.filter { ($0.expiry.daysLeft ?? 0) < 0 }.map(\.record)
        let soon = dated.filter { (0...30).contains($0.expiry.daysLeft ?? -1) }.map(\.record)
        let later = dated.filter { ($0.expiry.daysLeft ?? 0) > 30 }.map(\.record)
        let missing = store.records.filter { $0.expiry(today: today).prompt != nil }
        return [
            Bucket(id: "expired", title: "已过期", footer: "过期的化妆品可能滋生细菌，建议停用。", records: expired),
            Bucket(id: "soon", title: "30 天内", footer: nil, records: soon),
            Bucket(id: "later", title: "之后", footer: nil, records: later),
            Bucket(id: "missing", title: "待补全", footer: "记录开封日期或包装到期日后，就能算出到期时间。", records: missing)
        ].filter { !$0.records.isEmpty }
    }

    var body: some View {
        NavigationStack(path: $path) {
            let groups = groups
            List {
                ForEach(groups) { group in
                    Section {
                        ForEach(group.records) { record in
                            NavigationLink(value: Route.record(record.id)) {
                                row(record, group: group.id)
                            }
                        }
                    } header: {
                        Text(group.title)
                    } footer: {
                        if let footer = group.footer { Text(footer) }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .overlay {
                if groups.isEmpty {
                    ContentUnavailableView {
                        Label("没有需要留意的藏品", systemImage: "checkmark.seal")
                    } description: {
                        Text("记录开封日期后，快到期的化妆品会出现在这里。")
                    }
                }
            }
            .navigationTitle("到期")
            .routeDestinations(path: $path, zoom: zoom)
        }
    }

    private func row(_ record: CollectionRecord, group: String) -> some View {
        let expiry = record.expiry()
        return HStack(spacing: 14) {
            RecordArtwork(record: record, cornerRadius: 9)
                .frame(width: 44, height: 44)
                .zoomSource("record-\(record.id)", in: zoom)
            VStack(alignment: .leading, spacing: 2) {
                Text(record.name).font(.body.weight(.medium)).lineLimit(1)
                Text(group == "missing" ? (expiry.prompt ?? "") : record.categoryId.info.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            if group != "missing" {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(Day.short(expiry.date))
                        .font(.subheadline.weight(.medium))
                        .monospacedDigit()
                        .foregroundStyle(expiry.status?.tone.color ?? .primary)
                    Text(relative(expiry.daysLeft))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func relative(_ days: Int?) -> String {
        guard let days else { return "" }
        if days < 0 { return "已过 \(-days) 天" }
        if days == 0 { return "今天" }
        return "\(days) 天后"
    }
}
