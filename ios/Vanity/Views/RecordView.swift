import PhotosUI
import SwiftUI

/// 藏品详情：大图头部 + 分组列表，结构参考「通讯录」和「钱包」的详情页。
struct RecordView: View {
    let recordID: String
    let onDeleted: () -> Void
    let onHistory: () -> Void

    @Environment(CollectionStore.self) private var store
    @State private var editor: EditorMode?
    @State private var photoItem: PhotosPickerItem?
    @State private var showBackfill = false
    @State private var backfillDate = Date()
    @State private var confirmDelete = false
    @State private var usedTrigger = 0

    var body: some View {
        Group {
            if let record = store.record(id: recordID) {
                content(record)
            } else {
                ContentUnavailableView("这件藏品已删除", systemImage: "trash")
                    .onAppear(perform: onDeleted)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.increase, trigger: usedTrigger)
        .sheet(item: $editor) { EditorView(mode: $0) }
        .sheet(isPresented: $showBackfill) { backfillSheet }
        .onChange(of: photoItem) { _, item in loadPhoto(item) }
    }

    private func content(_ record: CollectionRecord) -> some View {
        let expiry = record.expiry()
        return List {
            Section {
                header(record, expiry: expiry)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            Section {
                usageSummary(record)
                if !(record.uses ?? []).isEmpty {
                    Button(action: onHistory) {
                        LabeledContent("使用记录") {
                            HStack(spacing: 6) {
                                Text("\(record.uses?.count ?? 0) 条")
                                Image(systemName: "chevron.forward")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .tint(.primary)
                }
                Button {
                    backfillDate = Date()
                    showBackfill = true
                } label: {
                    Label("补记一次使用", systemImage: "calendar.badge.plus")
                }
            } header: {
                Text("使用")
            } footer: {
                if let earlier = record.usageCount, earlier > 0 {
                    Text("其中 \(earlier) 次来自导入，没有具体日期。")
                }
            }

            Section {
                LabeledContent("到期日") {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(Day.display(expiry.date))
                            .foregroundStyle(expiry.status?.tone.color ?? .secondary)
                        if let status = expiry.status {
                            Text(status.label).font(.caption).foregroundStyle(status.tone.color)
                        } else if let days = expiry.daysLeft {
                            Text("还有 \(days) 天").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                if let progress = lifeProgress(record, expiry: expiry) {
                    Gauge(value: progress) {
                        Text("已用期限")
                    } currentValueLabel: {
                        Text(progress, format: .percent.precision(.fractionLength(0)))
                    }
                    .gaugeStyle(.accessoryLinear)
                    .tint(gaugeGradient)
                    .accessibilityLabel("已用期限 \(Int(progress * 100))%")
                }
                if let opened = record.openedDate {
                    LabeledContent("开封日期", value: Day.display(opened))
                    LabeledContent("开封后可用", value: record.paoMonths.map { "\($0) 个月" } ?? "未填写")
                }
                if record.packageExpiryDate != nil {
                    LabeledContent("包装到期日", value: Day.display(record.packageExpiryDate))
                }
                Button {
                    editor = .opening(record)
                } label: {
                    Label(record.openedDate == nil ? "记录开封" : "修改开封日期", systemImage: "seal")
                }
            } header: {
                Text("有效期")
            } footer: {
                let meta = [expiry.basis, expiry.prompt].compactMap { $0 }.joined(separator: "。")
                if !meta.isEmpty { Text(meta + "。") }
            }

            if record.price != nil || record.purchasedDate != nil {
                Section("购买") {
                    if let purchased = record.purchasedDate {
                        LabeledContent("购买日期", value: Day.display(purchased))
                    }
                    if let price = record.price {
                        LabeledContent("实付", value: price.display)
                        if record.useCount > 0 {
                            LabeledContent("每次使用约", value: Money(minorUnits: price.minorUnits / record.useCount).display)
                        }
                    }
                }
            }

            if let note = record.note {
                Section("备注") {
                    Text(note)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Section {
                Button("删除藏品", role: .destructive) { confirmDelete = true }
                    .frame(maxWidth: .infinity)
            }
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(.compact)
        .navigationTitle(record.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("编辑") { editor = .edit(record) }
            }
        }
        .confirmationDialog("删除「\(record.name)」？", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("删除藏品", role: .destructive) {
                store.delete(id: record.id)
                onDeleted()
            }
        } message: {
            Text("使用记录和照片会一起删除。")
        }
    }

    // MARK: Header

    private func header(_ record: CollectionRecord, expiry: Expiry) -> some View {
        VStack(spacing: 16) {
            PhotosPicker(selection: $photoItem, matching: .images) {
                RecordArtwork(record: record, cornerRadius: 22)
                    .aspectRatio(4 / 3, contentMode: .fit)
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: record.photoFile == nil ? "camera.fill" : "photo.on.rectangle")
                            .font(.footnote.weight(.semibold))
                            .padding(9)
                            .background(.thinMaterial, in: Circle())
                            .padding(12)
                    }
            }
            .buttonStyle(.plain)
            .contextMenu {
                if record.photoFile != nil {
                    Button(role: .destructive) { store.removePhoto(for: record.id) } label: {
                        Label("移除照片", systemImage: "trash")
                    }
                }
            }
            .accessibilityLabel(record.photoFile == nil ? "添加照片" : "更换照片")

            VStack(spacing: 4) {
                Text(record.categoryId.info.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.accent)
                Text(record.name)
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)
                if !record.identity.isEmpty {
                    Text(record.identity)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private func usageSummary(_ record: CollectionRecord) -> some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(record.useCount)")
                        .font(.system(size: 40, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text("次").font(.headline).foregroundStyle(.secondary)
                }
                Text(record.lastUsed.map { "上次 \(Day.display($0))" } ?? "还没有使用记录")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                withAnimation(.snappy) { store.logUse(id: record.id) }
                usedTrigger += 1
            } label: {
                Label("使用一次", systemImage: "plus")
                    .font(.body.weight(.semibold))
                    .padding(.horizontal, 6)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
        }
        .padding(.vertical, 6)
    }

    private var gaugeGradient: Gradient {
        Gradient(colors: [Palette.fresh, .yellow, Palette.warning, Palette.expired])
    }

    private func lifeProgress(_ record: CollectionRecord, expiry: Expiry) -> Double? {
        guard let end = expiry.date,
              let start = record.openedDate ?? record.purchasedDate,
              let total = Day.daysBetween(start, end), total > 0,
              let passed = Day.daysBetween(start, Day.today()) else { return nil }
        return min(1, max(0, Double(passed) / Double(total)))
    }

    // MARK: Backfill & photo

    private var backfillSheet: some View {
        NavigationStack {
            Form {
                DatePicker("使用日期", selection: $backfillDate, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(.graphical)
            }
            .navigationTitle("补记使用")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { showBackfill = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        store.logUse(id: recordID, on: Day.string(from: backfillDate))
                        usedTrigger += 1
                        showBackfill = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
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

/// 使用记录：按月分组，左滑删除。
struct UseHistoryView: View {
    let recordID: String
    @Environment(CollectionStore.self) private var store

    var body: some View {
        let uses = (store.record(id: recordID)?.uses ?? []).sorted { $0.date > $1.date }
        let groups = Dictionary(grouping: uses) { String($0.date.prefix(7)) }
        let months = groups.keys.sorted(by: >)
        List {
            ForEach(months, id: \.self) { month in
                Section(monthTitle(month)) {
                    ForEach(groups[month] ?? []) { use in
                        Text(Day.display(use.date))
                            .monospacedDigit()
                            .swipeActions {
                                Button(role: .destructive) {
                                    withAnimation { store.removeUse(recordID: recordID, useID: use.id) }
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .overlay {
            if uses.isEmpty { ContentUnavailableView("没有使用记录", systemImage: "calendar") }
        }
        .navigationTitle("使用记录")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func monthTitle(_ month: String) -> String {
        let parts = month.split(separator: "-")
        guard parts.count == 2, let m = Int(parts[1]) else { return month }
        return "\(parts[0])年\(m)月"
    }
}
