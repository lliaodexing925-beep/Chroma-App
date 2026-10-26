import Foundation
import SwiftData

enum MomentKind: String, Codable, CaseIterable, Identifiable {
    case reminder
    case memory

    var id: String { rawValue }

    var label: String {
        switch self {
        case .reminder: return "定时提醒"
        case .memory: return "生活记录"
        }
    }
}

enum RepeatRule: String, Codable, CaseIterable, Identifiable {
    case none
    case daily
    case weekly
    case monthly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none: return "不重复"
        case .daily: return "每天"
        case .weekly: return "每周"
        case .monthly: return "每月"
        }
    }
}

@Model
final class YCollection {
    @Attribute(.unique) var id: UUID
    var title: String
    var note: String?
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \Moment.collection)
    var moments: [Moment] = []

    init(title: String, note: String? = nil) {
        self.id = UUID()
        self.title = title
        self.note = note
        self.createdAt = Date()
    }
}

@Model
final class Moment {
    @Attribute(.unique) var id: UUID
    var kindRaw: String
    var title: String
    var note: String?
    var dueAt: Date
    var createdAt: Date
    var isCompleted: Bool
    var repeatRaw: String
    var photoNames: [String]
    var collection: YCollection?

    init(
        kind: MomentKind,
        title: String,
        note: String? = nil,
        dueAt: Date,
        repeatRule: RepeatRule = .none,
        photoNames: [String] = [],
        collection: YCollection? = nil
    ) {
        self.id = UUID()
        self.kindRaw = kind.rawValue
        self.title = title
        self.note = note
        self.dueAt = dueAt
        self.createdAt = Date()
        self.isCompleted = false
        self.repeatRaw = repeatRule.rawValue
        self.photoNames = photoNames
        self.collection = collection
    }

    var kind: MomentKind {
        get { MomentKind(rawValue: kindRaw) ?? .memory }
        set { kindRaw = newValue.rawValue }
    }

    var repeatRule: RepeatRule {
        get { RepeatRule(rawValue: repeatRaw) ?? .none }
        set { repeatRaw = newValue.rawValue }
    }
}
