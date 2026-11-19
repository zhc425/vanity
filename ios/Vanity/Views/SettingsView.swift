import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(CollectionStore.self) private var store
    @AppStorage("vanity.appearance") private var appearance: AppearanceMode = .system
    @AppStorage(ExpiryReminders.enabledKey) private var remindersOn = false
    @State private var exportURL: URL?
    @State private var importing = false
    @State private var reminderDenied = false

    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("外观") {
                    Picker("显示模式", selection: $appearance) {
                        ForEach(AppearanceMode.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Toggle("到期提醒", isOn: Binding(get: { remindersOn }, set: setReminders))
                } footer: {
                    Text(reminderDenied ? "通知权限已关闭，请在系统设置中允许 Vanity 发送通知。" : "到期前 7 天和到期当天上午 9 点提醒。")
                }

                Section {
                    LabeledContent("藏品", value: "\(store.records.count) 件")
                    LabeledContent("累计使用", value: "\(store.records.reduce(0) { $0 + $1.useCount }) 次")
                    let spent = store.records.compactMap(\.price?.minorUnits).reduce(0, +)
                    if spent > 0 {
                        LabeledContent("记录的花费", value: Money(minorUnits: spent).display)
                    }
                } header: {
                    Text("统计")
                }

                Section {
                    if let exportURL {
                        ShareLink(item: exportURL) {
                            Label("导出备份（JSON）", systemImage: "square.and.arrow.up")
                        }
                    } else {
                        Button {
                            exportURL = store.exportFile()
                        } label: {
                            Label("生成备份文件", systemImage: "doc.badge.arrow.up")
                        }
                    }
                    Button {
                        importing = true
                    } label: {
                        Label("从备份导入", systemImage: "square.and.arrow.down")
                    }
                } header: {
                    Text("数据")
                } footer: {
                    Text("备份格式与网页版通用。导入时会合并，已存在的藏品不会被覆盖。照片只保存在本机，不包含在备份中。")
                }

                Section {
                    LabeledContent("版本", value: version)
                    if let url = URL(string: "https://github.com/zhc425/vanity") {
                        Link(destination: url) { Label("GitHub 仓库", systemImage: "chevron.left.forwardslash.chevron.right") }
                    }
                } footer: {
                    Text("所有数据仅保存在本机。")
                }
            }
            .navigationTitle("设置")
            .fileImporter(isPresented: $importing, allowedContentTypes: [.json, .plainText]) { result in
                if case .success(let url) = result {
                    store.importBackup(from: url)
                    exportURL = nil
                }
            }
            .onAppear { exportURL = nil }
        }
    }

    private func setReminders(_ on: Bool) {
        guard on else {
            remindersOn = false
            ExpiryReminders.shared.disable()
            return
        }
        Task {
            let granted = await ExpiryReminders.shared.requestAuthorization()
            reminderDenied = !granted
            remindersOn = granted
            if granted { ExpiryReminders.shared.reschedule(for: store.records) }
        }
    }
}
