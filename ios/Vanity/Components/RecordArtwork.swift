import SwiftUI

/// 藏品缩略图：用户照片优先，没有照片时显示所属品类的 SF Symbol。
struct RecordArtwork: View {
    let record: CollectionRecord
    var cornerRadius: CGFloat = 10
    @Environment(CollectionStore.self) private var store

    var body: some View {
        ZStack {
            if let image = store.photo(for: record) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .accessibilityLabel(record.imageAlt ?? record.name)
            } else {
                Rectangle().fill(Palette.fill)
                GeometryReader { proxy in
                    Image(systemName: record.categoryId.info.symbol)
                        .font(.system(size: proxy.size.width * 0.36, weight: .light))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .accessibilityHidden(true)
            }
        }
        .continuousCorners(cornerRadius)
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

/// 品类封面图（随 App 打包的产品照片）。
struct CategoryArtwork: View {
    let category: VanityCategory
    var body: some View {
        Image(category.imageName)
            .resizable()
            .scaledToFill()
            .accessibilityLabel(category.alt)
    }
}
