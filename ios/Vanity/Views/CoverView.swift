import SwiftUI

struct CoverView: View {
    let zoom: Namespace.ID
    let onOpen: (CategoryID) -> Void
    let onIndex: () -> Void
    let onSettings: () -> Void
    let onRecord: (CollectionRecord) -> Void

    @Environment(CollectionStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var position: Int?
    @State private var showExpiring = false
    @State private var appeared = false

    private let categories = VanityCategory.all
    private static let loops = 40
    private var count: Int { categories.count }
    private var start: Int {
        count * (Self.loops / 2) + (categories.firstIndex { $0.id == .loosePowder } ?? 0)
    }
    private var activeIndex: Int { (((position ?? start) % count) + count) % count }
    private var active: VanityCategory { categories[activeIndex] }

    var body: some View {
        GeometryReader { geo in
            let cardWidth = min(geo.size.width * 0.6, 320)
            let cardHeight = cardWidth * 1.05
            VStack(spacing: 0) {
                topBar
                Spacer(minLength: 8)
                VStack(spacing: 4) {
                    VanityMark(size: geo.size.height < 700 ? 54 : 66)
                    Text("我的美妆藏品")
                        .font(Typeface.serif(14))
                        .tracking(5)
                        .foregroundStyle(Palette.silver)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 8)
                Spacer(minLength: 18)
                carousel(cardWidth: cardWidth, cardHeight: cardHeight, viewport: geo.size.width)
                    .frame(height: cardHeight + 24)
                caption
                    .padding(.top, 14)
                Spacer(minLength: 16)
            }
            .frame(maxWidth: .infinity)
        }
        .background(Palette.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showExpiring) {
            ExpiringListView { record in
                showExpiring = false
                onRecord(record)
            }
            .presentationDetents([.medium, .large])
        }
        .onAppear {
            if position == nil { position = start }
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.6)) { appeared = true }
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            let expiring = store.expiringSoon.count
            if expiring > 0 {
                Button {
                    showExpiring = true
                } label: {
                    Label("\(expiring) 件即将到期", systemImage: "hourglass")
                        .font(.footnote)
                }
                .buttonStyle(QuietButtonStyle())
                .foregroundStyle(Palette.warning)
            }
            Spacer()
            Button("全部分类", action: onIndex)
                .font(.subheadline)
                .foregroundStyle(Palette.ink)
            Button(action: onSettings) {
                Image(systemName: "gearshape")
                    .font(.body)
                    .frame(width: 40, height: 40)
            }
            .foregroundStyle(Palette.ink)
            .accessibilityLabel("设置")
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
    }

    private func carousel(cardWidth: CGFloat, cardHeight: CGFloat, viewport: CGFloat) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(0..<(count * Self.loops), id: \.self) { index in
                    let category = categories[index % count]
                    Button {
                        open(category, index: index)
                    } label: {
                        Image(category.imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: cardWidth, height: cardHeight)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: .black.opacity(0.14), radius: 14, y: 10)
                            .accessibilityLabel(category.title)
                            .accessibilityHint(category.alt)
                    }
                    .buttonStyle(.plain)
                    .zoomSource(index == position ? "category-\(category.id.rawValue)" : "cover-\(index)", in: zoom)
                    .visualEffect { content, proxy in
                        let frame = proxy.frame(in: .scrollView(axis: .horizontal))
                        let offset = max(-1.5, min(1.5, (frame.midX - viewport / 2) / max(cardWidth, 1)))
                        return content
                            .rotation3DEffect(.degrees(-offset * 24), axis: (x: 0, y: 1, z: 0), perspective: 0.55)
                            .scaleEffect(1 - min(abs(offset), 1) * 0.12)
                            .opacity(1 - min(abs(offset), 1.5) * 0.3)
                    }
                }
            }
            .scrollTargetLayout()
        }
        .contentMargins(.horizontal, max(0, (viewport - cardWidth) / 2), for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $position, anchor: .center)
        .sensoryFeedback(.selection, trigger: activeIndex)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared || reduceMotion ? 1 : 0.94)
    }

    private var caption: some View {
        HStack(alignment: .center) {
            stepButton(left: true)
            Spacer(minLength: 8)
            VStack(spacing: 6) {
                Text(String(format: "%02d / %d", activeIndex + 1, count))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Palette.silver)
                Text(active.title)
                    .font(Typeface.serif(32, relativeTo: .largeTitle))
                    .foregroundStyle(Palette.ink)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: activeIndex)
                Button {
                    open(active, index: position ?? start)
                } label: {
                    HStack(spacing: 4) {
                        Text("查看\(active.title)")
                        let total = store.records(in: active.id).count
                        if total > 0 { Text("· \(total) 件").foregroundStyle(Palette.silver) }
                        Image(systemName: "chevron.right").font(.caption)
                    }
                    .font(.subheadline)
                    .foregroundStyle(Palette.ink)
                    .frame(minHeight: 36)
                }
            }
            Spacer(minLength: 8)
            stepButton(left: false)
        }
        .padding(.horizontal, 24)
    }

    private func stepButton(left: Bool) -> some View {
        Button {
            withAnimation(.snappy) { position = (position ?? start) + (left ? -1 : 1) }
        } label: {
            Image(systemName: left ? "chevron.left" : "chevron.right")
                .font(.body)
                .frame(width: 46, height: 46)
                .overlay(Circle().strokeBorder(Palette.rule))
        }
        .foregroundStyle(Palette.ink)
        .accessibilityLabel(left ? "上一个分类" : "下一个分类")
    }

    private func open(_ category: VanityCategory, index: Int) {
        if index != position {
            withAnimation(.snappy) { position = index }
            return
        }
        onOpen(category.id)
    }
}

struct ExpiringListView: View {
    let onSelect: (CollectionRecord) -> Void
    @Environment(CollectionStore.self) private var store

    var body: some View {
        NavigationStack {
            List(store.expiringSoon) { record in
                let expiry = record.expiry()
                Button {
                    onSelect(record)
                } label: {
                    HStack(spacing: 12) {
                        RecordArtwork(record: record)
                            .frame(width: 44, height: 44)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(record.name).font(Typeface.serif(17)).foregroundStyle(Palette.ink)
                            Text("\(record.categoryId.info.title) · \(Day.display(expiry.date))")
                                .font(.caption).foregroundStyle(Palette.silver)
                        }
                        Spacer()
                        StatusBadge(status: expiry.status)
                    }
                }
                .listRowBackground(Palette.paper)
            }
            .scrollContentBackground(.hidden)
            .background(Palette.background)
            .navigationTitle("即将到期")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
