import SwiftUI

/// 列表中的一行藏品，样式参考「提醒事项」与「音乐」资料库的行。
struct RecordRow: View {
    let record: CollectionRecord
    let zoom: Namespace.ID
    var compact = false
    var showsCategory = false

    var body: some View {
        let expiry = record.expiry()
        HStack(spacing: 14) {
            RecordArtwork(record: record, cornerRadius: compact ? 9 : 10)
                .frame(width: compact ? 46 : 54, height: compact ? 46 : 54)
                .zoomSource("record-\(record.id)", in: zoom)

            VStack(alignment: .leading, spacing: 3) {
                Text(record.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                if let status = expiry.status, !compact {
                    StatusLabel(status: status)
                }
            }

            Spacer(minLength: 8)

            if compact, let status = expiry.status {
                StatusLabel(status: status)
            } else if !compact {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(record.useCount)")
                        .font(.title3.weight(.semibold))
                        .fontDesign(.rounded)
                        .monospacedDigit()
                        .foregroundStyle(record.useCount == 0 ? .tertiary : .primary)
                        .contentTransition(.numericText())
                    Text("次")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("使用 \(record.useCount) 次")
            }
        }
        .padding(.vertical, compact ? 0 : 2)
        .accessibilityElement(children: .combine)
    }

    private var subtitle: String? {
        var parts: [String] = []
        if showsCategory { parts.append(record.categoryId.info.title) }
        if !record.identity.isEmpty { parts.append(record.identity) }
        return parts.isEmpty ? nil : parts.joined(separator: "，")
    }
}
