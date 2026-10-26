import SwiftUI
import SwiftData

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \Moment.dueAt) private var moments: [Moment]
    @Query(sort: \YCollection.createdAt) private var collections: [YCollection]

    @State private var selectedCollection: YCollection?
    @State private var editingMoment: Moment?
    @State private var isComposing = false
    @State private var momentPendingDelete: Moment?

    private var filtered: [Moment] {
        guard let selectedCollection else { return moments }
        return moments.filter { $0.collection?.id == selectedCollection.id }
    }

    /// 下一条即将发生的提醒：未完成的、时间未到的最早一条
    private var nextMomentID: UUID? {
        moments
            .filter { $0.kind == .reminder && !$0.isCompleted && $0.dueAt > Date() }
            .sorted { $0.dueAt < $1.dueAt }
            .first?.id
    }

    var body: some View {
        NavigationStack {
            Group {
                if filtered.isEmpty {
                    emptyState
                } else {
                    timeline
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(selectedCollection?.title ?? "一刻")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    collectionMenu
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isComposing = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .accessibilityLabel("新建提醒或记录")
                }
            }
            .sheet(isPresented: $isComposing) {
                MomentEditorView(collection: selectedCollection)
            }
            .sheet(item: $editingMoment) { moment in
                MomentEditorView(moment: moment)
            }
            .alert("删除这条\(momentPendingDelete?.kind.label ?? "内容")？", isPresented: deleteBinding, presenting: momentPendingDelete) { moment in
                Button("取消", role: .cancel) {}
                Button("删除", role: .destructive) {
                    delete(moment)
                }
            } message: { _ in
                Text("删除后不可恢复，关联的系统通知也会一并取消。")
            }
        }
    }

    private var deleteBinding: Binding<Bool> {
        Binding(
            get: { momentPendingDelete != nil },
            set: { if !$0 { momentPendingDelete = nil } }
        )
    }

    private var collectionMenu: some View {
        Menu {
            Button {
                withAnimation { selectedCollection = nil }
            } label: {
                if selectedCollection == nil {
                    Label("全部", systemImage: "checkmark")
                } else {
                    Text("全部")
                }
            }
            ForEach(collections) { collection in
                Button {
                    withAnimation { selectedCollection = collection }
                } label: {
                    if selectedCollection?.id == collection.id {
                        Label(collection.title, systemImage: "checkmark")
                    } else {
                        Text(collection.title)
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selectedCollection?.title ?? "全部")
                    .font(.subheadline.weight(.medium))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .accessibilityLabel("按合集筛选")
    }

    private var timeline: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filtered) { moment in
                    MomentCard(
                        moment: moment,
                        isNext: moment.id == nextMomentID,
                        now: Date()
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .onTapGesture {
                        editingMoment = moment
                    }
                    .contextMenu {
                        if moment.kind == .reminder, !moment.isCompleted {
                            Button {
                                complete(moment)
                            } label: {
                                Label("标记完成", systemImage: "checkmark.circle")
                            }
                        }
                        Button(role: .destructive) {
                            momentPendingDelete = moment
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                    .transition(reduceMotion ? .opacity : .asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("还没有内容", systemImage: "clock.badge.questionmark")
        } description: {
            Text(selectedCollection == nil
                 ? "点右上角 +，安排第一条提醒，或记录一个生活瞬间。"
                 : "这个合集还是空的，点右上角 + 添加内容。")
        } actions: {
            Button("新建") { isComposing = true }
                .buttonStyle(.borderedProminent)
                .frame(minHeight: 44)
        }
    }

    private func complete(_ moment: Moment) {
        withAnimation {
            moment.isCompleted = true
        }
        NotificationManager.cancel(for: moment)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func delete(_ moment: Moment) {
        NotificationManager.cancel(for: moment)
        PhotoStore.delete(names: moment.photoNames)
        withAnimation {
            modelContext.delete(moment)
        }
    }
}
