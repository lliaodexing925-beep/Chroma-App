import Foundation
import UserNotifications

/// 系统级本地通知：和 iOS 自带闹钟同一套调度机制，
/// App 未打开、设备锁屏都会按时弹出。
@MainActor
enum NotificationManager {
    /// iOS 每 App 待处理通知上限 64，留 8 条余量给测试通知等临时用途。
    static let maxScheduled = 56

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// 为单条提醒调度通知。重复规则用日历触发器由系统无限重复；
    /// 单次提醒用时间间隔触发器。
    static func schedule(for moment: Moment) {
        cancel(for: moment)
        guard moment.kind == .reminder, !moment.isCompleted else { return }

        let content = UNMutableNotificationContent()
        content.title = "一刻 · \(moment.title)"
        if let note = moment.note, !note.isEmpty {
            content.body = note
        }
        content.sound = .default
        content.userInfo = ["momentID": moment.id.uuidString]

        let trigger: UNNotificationTrigger?
        switch moment.repeatRule {
        case .none:
            let interval = moment.dueAt.timeIntervalSinceNow
            guard interval > 1 else { return }
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        case .daily:
            trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.hour, .minute], from: moment.dueAt),
                repeats: true)
        case .weekly:
            trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.weekday, .hour, .minute], from: moment.dueAt),
                repeats: true)
        case .monthly:
            trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.day, .hour, .minute], from: moment.dueAt),
                repeats: true)
        }
        guard let trigger else { return }

        let request = UNNotificationRequest(
            identifier: moment.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func cancel(for moment: Moment) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [moment.id.uuidString])
    }

    /// 全量对账：先清掉所有自有通知，再按时间从近到远重新调度，
    /// 保证不超 64 条上限，且删掉的提醒不会残留通知。
    static func syncAll(moments: [Moment]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let upcoming = moments
            .filter { $0.kind == .reminder && !$0.isCompleted }
            .filter { $0.repeatRule != .none || $0.dueAt > Date() }
            .sorted { $0.dueAt < $1.dueAt }

        for moment in upcoming.prefix(maxScheduled) {
            schedule(for: moment)
        }
    }

    /// 5 秒后弹出一条测试通知，可退回桌面/锁屏验证系统弹出。
    static func scheduleTest() {
        let content = UNMutableNotificationContent()
        content.title = "一刻 · 测试通知"
        content.body = "如果你看到这条通知，说明系统提醒已经正常工作。"
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "yike.test.notification",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false))
        UNUserNotificationCenter.current().add(request)
    }
}
