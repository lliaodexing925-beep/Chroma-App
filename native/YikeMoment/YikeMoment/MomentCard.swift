import SwiftUI

/// Apple Music 式平面卡片：封面大图先行，元数据干净克制，
/// 无 3D、无重阴影；按压有轻微缩放回弹。
struct MomentCard: View {
    let moment: Moment
    let isNext: Bool
    let now: Date

    private var overdue: Bool {
        moment.kind == .reminder && !moment.isCompleted && moment.dueAt <= now
    }

    private var dayText: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(moment.dueAt) { return "今天" }
        if calendar.isDateInTomorrow(moment.dueAt) { return "明天" }
        if calendar.isDateInYesterday(moment.dueAt) { return "昨天" }
        return moment.dueAt.formatted(date: .abbreviated, time: .omitted)
    }

    private var statusText: String {
        if moment.kind == .memory { return dayText }
        if moment.isCompleted { return "\(dayText) · 已完成" }
        if overdue { return "\(dayText) · 已到时" }
        return dayText
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let first = moment.photoNames.first,
               let image = PhotoStore.image(named: first) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .aspectRatio(16.0 / 10.0, contentMode: .fill)
                    .clipped()
                    .overlay(alignment: .topLeading) {
                        if isNext { nextBadge.padding(12) }
                    }
                    .overlay(alignment: .bottomTrailing) {
                        if moment.photoNames.count > 1 {
                            Label("\(moment.photoNames.count)", systemImage: "photo.stack")
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial, in: Capsule())
                                .padding(10)
                        }
                    }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(moment.dueAt, format: .dateTime.hour().minute())
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(overdue ? Color.secondary : Color.primary)

                    Spacer(minLength: 12)

                    VStack(alignment: .trailing, spacing: 3) {
                        kindLabel
                        Text(statusText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(moment.title)
                    .font(.headline)
                    .lineLimit(2)

                if let note = moment.note, !note.isEmpty {
                    Text(note)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                if moment.collection != nil || moment.repeatRule != .none || moment.isCompleted {
                    HStack(spacing: 12) {
                        if let collection = moment.collection {
                            Label(collection.title, systemImage: "square.stack")
                        }
                        if moment.repeatRule != .none {
                            Label(moment.repeatRule.label, systemImage: "repeat")
                        }
                        if moment.isCompleted {
                            Label("已完成", systemImage: "checkmark.circle.fill")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
        .opacity(moment.isCompleted ? 0.62 : 1)
        .overlay(alignment: .topLeading) {
            if isNext, moment.photoNames.isEmpty { nextBadge.padding(12) }
        }
        .accessibilityElement(children: .combine)
    }

    private var kindLabel: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(moment.kind == .reminder ? Color.accentColor : Color.orange)
                .frame(width: 6, height: 6)
            Text(moment.kind.label)
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(.secondary)
    }

    private var nextBadge: some View {
        HStack(spacing: 5) {
            Text("NEXT")
                .font(.caption2.weight(.heavy))
                .tracking(1)
            Text("即将发生")
                .font(.caption2.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.accentColor, in: Capsule())
        .foregroundStyle(.white)
    }
}

/// 按压缩放回弹，替代旧的 3D/悬浮效果
struct CardButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 0.97 : 1))
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}
