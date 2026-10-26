import SwiftUI
import SwiftData

struct CollectionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \YCollection.createdAt) private var collections: [YCollection]

    @State private var isAdding = false
    @State private var newTitle = ""
    @State private var renaming: YCollection?
    @State private var renameTitle = ""
    @State private var pendingDelete: YCollection?

    var body: some View {
        NavigationStack {
            List {
                if collections.isEmpty {
                    ContentUnavailableView {
                        Label("还没有合集", systemImage: "square.stack")
                    } description: {
                        Text("把相关的提醒和记录收进一个合集，比如「健身」「宝宝成长」。")
                    } actions: {
                        Button("新建合集") { isAdding = true }
                            .buttonStyle(.borderedProminent)
                            .frame(minHeight: 44)
                    }
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(collections) { collection in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(collection.title)
                                    .font(.body.weight(.medium))
                                Text("\(collection.moments.count) 条内容")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                pendingDelete = collection
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                            Button {
                                renameTitle = collection.title
                                renaming = collection
                            } label: {
                                Label("重命名", systemImage: "pencil")
                            }
                            .tint(.orange)
                        }
                        .contextMenu {
                            Button {
                                renameTitle = collection.title
                                renaming = collection
                            } label: {
                                Label("重命名", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                pendingDelete = collection
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("合集")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        newTitle = ""
                        isAdding = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .accessibilityLabel("新建合集")
                }
            }
            .alert("新建合集", isPresented: $isAdding) {
                TextField("合集名称", text: $newTitle)
                Button("取消", role: .cancel) {}
                Button("创建") { addCollection() }
                    .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .alert("重命名合集", isPresented: renameBinding, presenting: renaming) { collection in
                TextField("合集名称", text: $renameTitle)
                Button("取消", role: .cancel) {}
                Button("保存") { rename(collection) }
                    .disabled(renameTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .alert("删除合集「\(pendingDelete?.title ?? "")」？", isPresented: deleteBinding, presenting: pendingDelete) { collection in
                Button("取消", role: .cancel) {}
                Button("删除合集", role: .destructive) { delete(collection) }
            } message: { collection in
                Text("只会删除合集本身。里面的 \(collection.moments.count) 条提醒和记录都会保留，并移出这个合集。")
            }
        }
    }

    private var renameBinding: Binding<Bool> {
        Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })
    }

    private var deleteBinding: Binding<Bool> {
        Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })
    }

    private func addCollection() {
        let title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        withAnimation {
            modelContext.insert(YCollection(title: title))
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func rename(_ collection: YCollection) {
        let title = renameTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, title != collection.title else { return }
        collection.title = title
    }

    private func delete(_ collection: YCollection) {
        withAnimation {
            modelContext.delete(collection)
        }
    }
}
