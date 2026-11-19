import SwiftUI

struct CategoryIndexView: View {
    let current: CategoryID?
    let onSelect: (CategoryID) -> Void
    @Environment(CollectionStore.self) private var store

    var body: some View {
        NavigationStack {
            List(VanityCategory.all) { category in
                Button {
                    onSelect(category.id)
                } label: {
                    HStack(spacing: 14) {
                        Image(category.imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.title).font(Typeface.serif(19)).foregroundStyle(Palette.ink)
                            Text(category.subtitle).font(.caption).foregroundStyle(Palette.silver)
                        }
                        Spacer()
                        let total = store.records(in: category.id).count
                        if total > 0 {
                            Text("\(total)")
                                .font(.footnote.monospacedDigit())
                                .foregroundStyle(Palette.silver)
                        }
                        Image(systemName: category.id == current ? "checkmark" : "chevron.right")
                            .font(.footnote)
                            .foregroundStyle(category.id == current ? Palette.plum : Palette.silver)
                    }
                }
                .listRowBackground(Palette.paper)
                .accessibilityAddTraits(category.id == current ? .isSelected : [])
            }
            .scrollContentBackground(.hidden)
            .background(Palette.background)
            .navigationTitle("全部分类")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
