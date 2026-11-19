import PhotosUI
import SwiftUI

enum EditorMode: Identifiable {
    case add(CategoryID)
    case edit(CollectionRecord)
    case opening(CollectionRecord)

    var id: String {
        switch self {
        case .add(let category): "add-\(category.rawValue)"
        case .edit(let record): "edit-\(record.id)"
        case .opening(let record): "opening-\(record.id)"
        }
    }
}

struct EditorView: View {
    let mode: EditorMode
    var onSaved: (String) -> Void = { _ in }

    @Environment(CollectionStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var brand = ""
    @State private var shade = ""
    @State private var note = ""
    @State private var priceText = ""
    @State private var hasPurchased = false
    @State private var purchased = Date()
    @State private var hasPackageExpiry = false
    @State private var packageExpiry = Calendar.current.date(byAdding: .year, value: 2, to: Date()) ?? Date()
    @State private var isOpened = false
    @State private var opened = Date()
    @State private var paoMonths: Int?
    @State private var photoItem: PhotosPickerItem?
    @State private var pickedPhoto: UIImage?
    @State private var error: String?
    @State private var loaded = false
    @State private var categoryID: CategoryID = .lipstick
    @FocusState private var nameFocused: Bool

    private var category: VanityCategory { categoryID.info }

    private var title: String {
        switch mode {
        case .add: "添加藏品"
        case .edit: "编辑藏品"
        case .opening: "记录开封"
        }
    }

    private var isOpeningOnly: Bool {
        if case .opening = mode { return true }
        return false
    }

    private var existingRecord: CollectionRecord? {
        switch mode {
        case .add: return nil
        case .edit(let record), .opening(let record): return store.record(id: record.id) ?? record
        }
    }

    private var existingPhoto: UIImage? { existingRecord.flatMap { store.photo(for: $0) } }

    var body: some View {
        NavigationStack {
            Form {
                if isOpeningOnly {
                    openingSection(alwaysOn: true)
                } else {
                    identitySection
                    purchaseSection
                    openingSection(alwaysOn: false)
                    noteSection
                }
                if let error {
                    Section {
                        Label(error, systemImage: "exclamationmark.circle.fill")
                            .foregroundStyle(Palette.expired)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isAdding ? "添加" : "完成") { save() }
                        .fontWeight(.semibold)
                        .disabled(!isOpeningOnly && name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear(perform: populate)
            .onChange(of: isOpened) { _, opened in
                if opened && paoMonths == nil { paoMonths = category.suggestedPAO }
            }
            .onChange(of: photoItem) { _, item in loadPhoto(item) }
        }
        .presentationDragIndicator(.visible)
    }

    // MARK: Sections

    private var isAdding: Bool {
        if case .add = mode { return true }
        return false
    }

    private var identitySection: some View {
        Group {
            Section {
                VStack(spacing: 10) {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Group {
                            if let pickedPhoto {
                                Image(uiImage: pickedPhoto).resizable().scaledToFill()
                            } else if let image = existingPhoto {
                                Image(uiImage: image).resizable().scaledToFill()
                            } else {
                                ZStack {
                                    Rectangle().fill(Palette.fill)
                                    Image(systemName: category.symbol)
                                        .font(.system(size: 34, weight: .light))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .frame(width: 112, height: 112)
                        .continuousCorners(24)
                    }
                    .buttonStyle(.plain)
                    PhotosPicker(pickedPhoto == nil && existingPhoto == nil ? "添加照片" : "更换照片", selection: $photoItem, matching: .images)
                        .font(.subheadline.weight(.medium))
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }

            Section {
                TextField("名称", text: $name)
                    .focused($nameFocused)
                    .submitLabel(.next)
                TextField("品牌", text: $brand)
                TextField("色号或规格", text: $shade)
                if isAdding {
                    Picker("分类", selection: $categoryID) {
                        ForEach(VanityCategory.all) { Label($0.title, systemImage: $0.symbol).tag($0.id) }
                    }
                }
            } footer: {
                Text("只有名称必填，其他信息可以之后再补。")
            }
        }
    }

    private var purchaseSection: some View {
        Section("购入与有效期") {
            Toggle("记录购买日期", isOn: $hasPurchased.animation())
            if hasPurchased {
                DatePicker("购买日期", selection: $purchased, in: ...Date(), displayedComponents: .date)
            }
            HStack {
                Text("实付价格")
                Spacer()
                Text("¥").foregroundStyle(.secondary)
                TextField("选填", text: $priceText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 120)
            }
            Toggle("包装上有到期日", isOn: $hasPackageExpiry.animation())
            if hasPackageExpiry {
                DatePicker("包装到期日", selection: $packageExpiry, displayedComponents: .date)
            }
        }
    }

    @ViewBuilder
    private func openingSection(alwaysOn: Bool) -> some View {
        Section {
            if !alwaysOn {
                Toggle("已开封", isOn: $isOpened.animation())
            }
            if isOpened || alwaysOn {
                DatePicker("开封日期", selection: $opened, in: ...Date(), displayedComponents: .date)
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("开封后可用")
                        Spacer()
                        Text(paoMonths.map { "\($0) 个月" } ?? "未填写")
                            .foregroundStyle(paoMonths == nil ? .secondary : .primary)
                            .monospacedDigit()
                        Stepper("", value: Binding(get: { paoMonths ?? category.suggestedPAO },
                                                   set: { paoMonths = $0 }), in: 1...120)
                            .labelsHidden()
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach([3, 6, 12, 18, 24, 36], id: \.self) { months in
                                Button("\(months)M") { paoMonths = months }
                                    .font(.footnote.weight(.medium).monospacedDigit())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(paoMonths == months ? Palette.accent : Palette.fill, in: Capsule())
                                    .foregroundStyle(paoMonths == months ? Color.white : Color.primary)
                            }
                        }
                    }
                    .buttonStyle(.borderless)
                }
            }
        } header: {
            Text("开封")
        } footer: {
            Text("包装上的开盖图标（如 12M）表示开封后可用的月数。到期日取包装有效期与开封后期限中较早的一个。")
        }

        if alwaysOn, let record = existingRecord, record.openedDate != nil {
            Section {
                Button("清除开封记录", role: .destructive) {
                    var next = record
                    next.openedDate = nil
                    next.paoMonths = nil
                    if store.update(next, message: "已清除开封记录") { dismiss() }
                }
            }
            }
    }

    private var noteSection: some View {
        Section("备注") {
            TextField("肤感、搭配、回购意向……", text: $note, axis: .vertical)
                .lineLimit(3...8)
        }
    }

    // MARK: Logic

    private func populate() {
        guard !loaded else { return }
        loaded = true
        switch mode {
        case .add(let id):
            categoryID = id
            nameFocused = true
        case .edit(let record), .opening(let record):
            categoryID = record.categoryId
            name = record.name
            brand = record.brand ?? ""
            shade = record.shade ?? ""
            note = record.note ?? ""
            if let price = record.price {
                priceText = price.minorUnits % 100 == 0 ? "\(price.minorUnits / 100)" : String(format: "%.2f", Double(price.minorUnits) / 100)
            }
            if let date = Day.date(from: record.purchasedDate) { hasPurchased = true; purchased = date }
            if let date = Day.date(from: record.packageExpiryDate) { hasPackageExpiry = true; packageExpiry = date }
            if let date = Day.date(from: record.openedDate) { isOpened = true; opened = date }
            paoMonths = record.paoMonths
            if case .opening = mode, record.openedDate == nil { opened = Date() }
        }
    }

    private func loadPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                pickedPhoto = image.resized(maxSide: 1600)
            } else {
                error = "无法读取这张照片"
            }
        }
    }

    private func save() {
        error = nil
        let today = Day.today()

        if isOpeningOnly, var record = existingRecord {
            let openedDay = Day.string(from: opened)
            guard openedDay <= today else { error = "开封日期不能晚于今天"; return }
            record.openedDate = openedDay
            record.paoMonths = paoMonths
            if store.update(record, message: "开封记录已保存") { dismiss() }
            return
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { error = "请填写藏品名称"; nameFocused = true; return }
        guard trimmedName.count <= 100 else { error = "名称最多 100 个字"; return }

        var price: Money?
        let rawPrice = priceText.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        if !rawPrice.isEmpty {
            guard let value = Decimal(string: rawPrice, locale: Locale(identifier: "en_US_POSIX")),
                  value >= 0, value <= 9_999_999.99 else { error = "价格格式不正确"; return }
            var cents = value * 100
            var rounded = Decimal()
            NSDecimalRound(&rounded, &cents, 0, .plain)
            price = Money(minorUnits: NSDecimalNumber(decimal: rounded).intValue)
        }

        let purchasedDay = hasPurchased ? Day.string(from: purchased) : nil
        if let purchasedDay, purchasedDay > today { error = "购买日期不能晚于今天"; return }
        let openedDay = isOpened ? Day.string(from: opened) : nil
        if let openedDay, openedDay > today { error = "开封日期不能晚于今天"; return }
        if let openedDay, let purchasedDay, openedDay < purchasedDay { error = "开封日期早于购买日期，请检查"; return }

        func apply(_ record: inout CollectionRecord) {
            record.name = trimmedName
            record.brand = clean(brand, 80)
            record.shade = clean(shade, 60)
            record.note = clean(note, 2000)
            record.price = price
            record.purchasedDate = purchasedDay
            record.packageExpiryDate = hasPackageExpiry ? Day.string(from: packageExpiry) : nil
            record.openedDate = openedDay
            record.paoMonths = openedDay == nil ? nil : paoMonths
        }

        switch mode {
        case .add:
            var record = CollectionRecord(categoryId: categoryID, name: trimmedName)
            apply(&record)
            guard store.add(record) else { return }
            if let pickedPhoto { store.savePhoto(pickedPhoto, for: record.id) }
            dismiss()
            onSaved(record.id)
        case .edit:
            guard var record = existingRecord else { return }
            apply(&record)
            guard store.update(record) else { return }
            if let pickedPhoto { store.savePhoto(pickedPhoto, for: record.id) }
            dismiss()
            onSaved(record.id)
        case .opening:
            break
        }
    }

    private func clean(_ value: String, _ limit: Int) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : String(trimmed.prefix(limit))
    }
}
