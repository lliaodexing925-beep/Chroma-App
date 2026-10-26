import SwiftUI
import SwiftData

/// 「我的」：通知设置、分享、关于。
/// 分享入口按需求集中放在这里，顶部不再放分享按钮。
struct SettingsView: View {
    @Query(sort: \Moment.dueAt) private var moments: [Moment]

    @State private var notificationStatus = "检测中…"
    @State private var testSent = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Label("系统通知", systemImage: "bell.badge")
                        Spacer()
                        Text(notificationStatus)
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                    .frame(minHeight: 44)

                    if notificationStatus == "未开启" {
                        Button {
                            openSystemSettings()
                        } label: {
                            Label("去系统设置开启", systemImage: "gear")
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                    }

                    Button {
                        sendTest()
                    } label: {
                        Label(testSent ? "已发送，5 秒后弹出" : "发送测试通知（5 秒后）",
                              systemImage: "paperplane")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .disabled(testSent)
                } header: {
                    Text("提醒")
                } footer: {
                    Text("提醒由 iOS 系统统一调度，即使「一刻」没有打开也会按时弹出。系统静音或专注模式下的表现由系统设置决定。")
                }

                Section {
                    ShareLink(item: shareText) {
                        Label("分享我的时间线", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                } header: {
                    Text("分享")
                } footer: {
                    Text("把时间线的文字摘要分享给朋友。数据只保存在这台设备上，不会上传到云端。")
                }

                Section {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("2.0.0 · 原生版")
                            .foregroundStyle(.secondary)
                    }
                    .frame(minHeight: 44)
                    HStack {
                        Text("数据存储")
                        Spacer()
                        Text("仅本机")
                            .foregroundStyle(.secondary)
                    }
                    .frame(minHeight: 44)
                } header: {
                    Text("关于一刻")
                } footer: {
                    Text("一刻，把今天串成一条线。所有数据保存在本机，卸载 App 会同时删除数据。")
                }
            }
            .navigationTitle("我的")
            .task { await refreshStatus() }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                Task { await refreshStatus() }
            }
        }
    }

    private var shareText: String {
        let upcoming = moments
            .filter { !$0.isCompleted }
            .sorted { $0.dueAt < $1.dueAt }
            .prefix(20)
        guard !upcoming.isEmpty else { return "我在用「一刻」记录每一天。" }
        let lines = upcoming.map { moment in
            let time = moment.dueAt.formatted(date: .abbreviated, time: .shortened)
            return "\(time) · \(moment.title)"
        }
        return "我的一刻时间线：\n" + lines.joined(separator: "\n")
    }

    private func refreshStatus() async {
        switch await NotificationManager.authorizationStatus() {
        case .authorized, .provisional, .ephemeral:
            notificationStatus = "已开启"
        case .denied:
            notificationStatus = "未开启"
        case .notDetermined:
            notificationStatus = "保存第一条提醒时会请求权限"
        @unknown default:
            notificationStatus = "未知"
        }
    }

    private func sendTest() {
        Task {
            let status = await NotificationManager.authorizationStatus()
            if status == .notDetermined {
                let granted = await NotificationManager.requestAuthorization()
                guard granted else {
                    await refreshStatus()
                    return
                }
            } else if status != .authorized && status != .provisional {
                openSystemSettings()
                return
            }
            NotificationManager.scheduleTest()
            testSent = true
            try? await Task.sleep(for: .seconds(6))
            testSent = false
        }
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
