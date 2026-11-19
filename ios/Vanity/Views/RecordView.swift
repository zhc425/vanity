import PhotosUI
import SwiftUI

struct RecordView: View {
    let recordID: String
    let onDeleted: () -> Void

    @Environment(CollectionStore.self) private var store
    @State private var editor: EditorMode?
    @State private var photoItem: PhotosPickerItem?
    @State private var showBackfill = false
    @State private var backfillDate = Date()
    @State private var confirmDelete = false
    @State private var showAllUses = false
    @State private var usedTrigger = 0

    var body: some View {
        Group {
            if let record = store.record(id: recordID) {
                content(record)
            } else {
                Text("这件藏品已被删除")
                    .font(Typeface.serif(18))
                    .foregroundStyle(Palette.silver)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear(perform: onDeleted)
            }
        }
        .background(Palette.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Palette.background, for: .navigationBar)
        .sensoryFeedback(.success, trigger: usedTrigger)
        .sheet(item: $editor) { EditorView(mode: $0) }
        .sheet(isPresented: $showBackfill) { backfillSheet }
        .onChange(of: photoItem) { _, item in loadPhoto(item) }
    }

    private func content(_ record: CollectionRecord) -> some View {
        let expiry = record.expiry()
        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(record.categoryId.info.title + " · " + record.categoryId.info.subtitle)
                        .font(.caption)
                        .foregroundStyle(Palette.plum)
                    Text(record.name)
                        .font(Typeface.serif(36, relativeTo: .largeTitle))
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if !record.identity.isEmpty {
                        Text(record.identity)
                            .font(.subheadline)
                            .foregroundStyle(Palette.silver)
                    }
                }

                photoCard(record)
                usageCard(record)
                expiryCard(record, expiry: expiry)
                purchaseCard(record)

                if let note = record.note {
                    Card {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("备注").font(.footnote).foregroundStyle(Palette.silver)
                            Text(note)
                                .font(Typeface.serif(16))
                                .foregroundStyle(Palette.ink)
                                .textSelection(.enabled)
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 90)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .toolbar {
            ToolbarItem(placement: .principal) { VanityMark(size: 28) }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { editor = .edit(record) } label: { Label("编辑藏品", systemImage: "pencil") }
                    Button { editor = .opening(record) } label: { Label(record.openedDate == nil ? "记录开封" : "修改开封记录", systemImage: "seal") }
                    Button { showBackfill = true } label: { Label("补记一次使用", systemImage: "calendar.badge.plus") }
                    Divider()
                    Button(role: .destructive) { confirmDelete = true } label: { Label("删除藏品", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("更多操作")
            }
        }
        .confirmationDialog("删除「\(record.name)」？", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("删除", role: .destructive) {
                store.delete(id: record.id)
                onDeleted()
            }
        } message: {
            Text("使用记录和照片会一起删除，删除后可在提示中撤销。")
        }
    }

    // MARK: Cards

    private func photoCard(_ record: CollectionRecord) -> some View {
        PhotosPicker(selection: $photoItem, matching: .images) {
            RecordArtwork(record: record, cornerRadius: 18, showsHint: true)
                .aspectRatio(1.15, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Palette.rule))
        }
        .buttonStyle(.plain)
        .contextMenu {
            if record.photoFile != nil {
                Button(role: .destructive) { store.removePhoto(for: record.id) } label: { Label("移除照片", systemImage: "trash") }
            }
        }
        .accessibilityLabel(record.photoFile == nil ? "添加照片" : "更换照片")
    }

    private func usageCard(_ record: CollectionRecord) -> some View {
        let uses = (record.uses ?? []).sorted { $0.date > $1.date }
        let shown = showAllUses ? uses : Array(uses.prefix(5))
        return Card {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("使用记录").font(.footnote).foregroundStyle(Palette.silver)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(record.useCount)")
                            .font(.system(size: 34, weight: .regular, design: .default).monospacedDigit())
                            .contentTransition(.numericText())
                        Text("次").font(.subheadline).foregroundStyle(Palette.silver)
                    }
                    .foregroundStyle(Palette.ink)
                    if let last = record.lastUsed {
                        Text("上次使用 \(Day.display(last))").font(.caption).foregroundStyle(Palette.silver)
                    }
                }
                Spacer()
                Button {
                    withAnimation(.snappy) { store.logUse(id: record.id) }
                    usedTrigger += 1
                } label: {
                    Label("记一次使用", systemImage: "plus")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(18)

            if !uses.isEmpty {
                Divider().overlay(Palette.rule)
                VStack(spacing: 0) {
                    ForEach(shown) { use in
                        HStack {
                            Text(Day.display(use.date)).font(.subheadline.monospacedDigit())
                            Spacer()
                            Button {
                                withAnimation(.snappy) { store.removeUse(recordID: record.id, useID: use.id) }
                            } label: {
                                Image(systemName: "minus.circle")
                                    .foregroundStyle(Palette.silver)
                                    .frame(width: 36, height: 36)
                            }
                            .accessibilityLabel("删除 \(Day.display(use.date)) 的使用记录")
                        }
                        .foregroundStyle(Palette.ink)
                        .padding(.horizontal, 18)
                        .frame(minHeight: 40)
                    }
                    if uses.count > 5 {
                        Button(showAllUses ? "收起" : "查看全部 \(uses.count) 条") {
                            withAnimation(.snappy) { showAllUses.toggle() }
                        }
                        .font(.footnote)
                        .foregroundStyle(Palette.plum)
                        .frame(maxWidth: .infinity, minHeight: 40)
                    }
                }
                .padding(.vertical, 6)
            }
            if let earlier = record.usageCount, earlier > 0 {
                Text("含导入时记录的 \(earlier) 次")
                    .font(.caption)
                    .foregroundStyle(Palette.silver)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 12)
            }
        }
    }

    private func expiryCard(_ record: CollectionRecord, expiry: Expiry) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("到期日").font(.footnote).foregroundStyle(Palette.silver)
                    Spacer()
                    Button(record.openedDate == nil ? "记录开封" : "修改开封记录") { editor = .opening(record) }
                        .font(.footnote)
                        .foregroundStyle(Palette.plum)
                }
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(Day.display(expiry.date))
                        .font(Typeface.serif(26))
                        .foregroundStyle(Palette.ink)
                    StatusBadge(status: expiry.status)
                }
                let meta = [expiry.basis, expiry.prompt].compactMap { $0 }.joined(separator: "。")
                if !meta.isEmpty {
                    Text(meta).font(.caption).foregroundStyle(Palette.silver)
                }
                if let opened = record.openedDate {
                    Text("开封于 \(Day.display(opened))" + (record.paoMonths.map { "，开封后可用 \($0) 个月" } ?? ""))
                        .font(.caption)
                        .foregroundStyle(Palette.silver)
                }
                if let days = expiry.daysLeft, days > 30 {
                    ProgressView(value: lifeProgress(record, expiry: expiry))
                        .tint(Palette.plum)
                        .accessibilityLabel("已使用期限比例")
                }
            }
            .padding(18)
        }
    }

    private func purchaseCard(_ record: CollectionRecord) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("购入信息").font(.footnote).foregroundStyle(Palette.silver)
                    Spacer()
                    Button("编辑藏品") { editor = .edit(record) }
                        .font(.footnote)
                        .foregroundStyle(Palette.plum)
                }
                Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 12) {
                    GridRow {
                        field("购买日期", Day.display(record.purchasedDate))
                        field("实付价格", record.price?.display ?? "未记录")
                    }
                    GridRow {
                        field("包装到期日", Day.display(record.packageExpiryDate))
                        if let price = record.price, record.useCount > 0 {
                            field("每次约", Money(minorUnits: price.minorUnits / record.useCount).display)
                        } else {
                            field("每次约", "—")
                        }
                    }
                }
            }
            .padding(18)
        }
    }

    private func field(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(.caption).foregroundStyle(Palette.silver)
            Text(value).font(.subheadline.monospacedDigit()).foregroundStyle(Palette.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func lifeProgress(_ record: CollectionRecord, expiry: Expiry) -> Double {
        guard let end = expiry.date,
              let start = record.openedDate ?? record.purchasedDate,
              let total = Day.daysBetween(start, end), total > 0,
              let passed = Day.daysBetween(start, Day.today()) else { return 0 }
        return min(1, max(0, Double(passed) / Double(total)))
    }

    // MARK: Backfill & photo

    private var backfillSheet: some View {
        NavigationStack {
            DatePicker("使用日期", selection: $backfillDate, in: ...Date(), displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding()
                .navigationTitle("补记一次使用")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("取消") { showBackfill = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("记下") {
                            store.logUse(id: recordID, on: Day.string(from: backfillDate))
                            usedTrigger += 1
                            showBackfill = false
                        }
                        .fontWeight(.semibold)
                    }
                }
        }
        .presentationDetents([.medium, .large])
    }

    private func loadPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                store.savePhoto(image, for: recordID)
            } else {
                store.show("无法读取这张照片")
            }
            photoItem = nil
        }
    }
}
