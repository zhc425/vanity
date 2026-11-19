import SwiftUI

/// 藏品缩略图：用户照片 > 占位图
struct RecordArtwork: View {
    let record: CollectionRecord
    var cornerRadius: CGFloat = 8
    var showsHint = false
    @Environment(CollectionStore.self) private var store

    var body: some View {
        ZStack {
            if let image = store.photo(for: record) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .accessibilityLabel(record.imageAlt ?? record.name)
            } else {
                LinearGradient(colors: [Palette.veil, Palette.rule.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                VStack(spacing: 8) {
                    Image(systemName: showsHint ? "camera" : "photo")
                        .font(showsHint ? .title2 : .footnote)
                    if showsHint {
                        Text("添加照片").font(.footnote)
                    }
                }
                .foregroundStyle(Palette.silver)
                .accessibilityHidden(!showsHint)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
