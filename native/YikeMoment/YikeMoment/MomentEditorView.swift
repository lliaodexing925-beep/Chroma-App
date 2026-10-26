import SwiftUI
import SwiftData
import PhotosUI

/// 新建 / 编辑提醒或生活记录
struct MomentEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \YCollection.createdAt) private var collections: [YCollection]

    private let existing: Moment?

    @State private var kind: MomentKind
    @State private var title: String
    @State private var note: String
    @State private var dueAt: Date
    @State private var repeatRule: RepeatRule
    @State private var collection: YCollection?
    @State private var photoNames: [String]
    @State private var pickedItems: [PhotosPickerItem] = []
    @State private var isSavingPhotos = false

    init(moment: Moment) {
        existing = moment
        _kind = State(initialValue: moment.kind)
        _title = State(initialValue: moment.title)
        _note = State(initialValue: moment.note ?? "")
        _dueAt = State(initialValue: moment.dueAt)
        _repeatRule = State(initialValue: moment.repeatRule)
        _collection = State(initialValue: moment.collection)
        _photoNames = State(initialValue: moment.photoNames)
    }

    init(collection: YCollection? = nil) {
        existing = nil
        _kind = State(initialValue: .reminder)
        _title = State(initialValue: "")
        _note = State(initialValue: "")
        let base = Date().addingTimeInterval(3600)
        let rounded = Calendar.current.dateInterval(of: .hour, for: base)?.start ?? base
        _dueAt = State(initialValue: rounded)
        _repeatRule = State(initialValue: .none)
        _collection = State(initialValue: collection)
        _photoNames = State(initialValue: [])
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSavingPhotos
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("类型", selection: $kind) {
                        ForEach(MomentKind.allCases) { kind in
                            Text(kind.label).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                Section(kind == .reminder ? "提醒我" : "记录") {
                    TextField(kind == .reminder ? "要提醒什么？" : "这一刻发生了什么？", text: $title)
                        .frame(minHeight: 44)
                    TextEditor(text: $note)
                        .frame(minHeight: 72)
                        .overlay(alignment: .topLeading) {
                            if note.isEmpty {
                                Text("补充一点细节（可选）")
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                                    .allowsHitTesting(false)
                            }
                        }
                }

                Section("时间") {
                    DatePicker(
                        kind == .reminder ? "提醒时间" : "发生时间",
                        selection: $dueAt,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .frame(minHeight: 44)

                    if kind == .reminder {
                        Picker("重复", selection: $repeatRule) {
                            ForEach(RepeatRule.allCases) { rule in
                                Text(rule.label).tag(rule)
                            }
                        }
                        .frame(minHeight: 44)
                    }
                }

                Section("合集") {
                    Picker("所属合集", selection: $collection) {
                        Text("不属于任何合集").tag(YCollection?.none)
                        ForEach(collections) { item in
                            Text(item.title).tag(YCollection?.some(item))
                        }
                    }
                    .frame(minHeight: 44)
                }

                Section("照片") {
                    if !photoNames.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(photoNames, id: \.self) { name in
                                    photoThumb(name)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    PhotosPicker(
                        selection: $pickedItems,
                        maxSelectionCount: 9,
                        matching: .images
                    ) {
                        Label(isSavingPhotos ? "正在处理照片…" : "添加照片", systemImage: "photo.on.rectangle.angled")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .disabled(isSavingPhotos)
                }
            }
            .navigationTitle(existing == nil ? "新建" : "编辑")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .frame(minWidth: 44, minHeight: 44)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                        .frame(minWidth: 44, minHeight: 44)
                }
            }
            .onChange(of: pickedItems) { _, items in
                loadPickedPhotos(items)
            }
        }
    }

    private func photoThumb(_ name: String) -> some View {
        ZStack(alignment: .topTrailing) {
            if let image = PhotoStore.image(named: name) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 84, height: 84)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            Button {
                photoNames.removeAll { $0 == name }
                PhotoStore.delete(names: [name])
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.55))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("移除这张照片")
        }
    }

    private func loadPickedPhotos(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        isSavingPhotos = true
        Task {
            defer {
                pickedItems = []
                isSavingPhotos = false
            }
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let name = PhotoStore.save(data: data) {
                    await MainActor.run { photoNames.append(name) }
                }
            }
        }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        let target: Moment
        if let existing {
            target = existing
            existing.kind = kind
            existing.title = trimmedTitle
            existing.note = trimmedNote.isEmpty ? nil : trimmedNote
            existing.dueAt = dueAt
            existing.repeatRule = kind == .reminder ? repeatRule : .none
            existing.collection = collection
            existing.photoNames = photoNames
        } else {
            target = Moment(
                kind: kind,
                title: trimmedTitle,
                note: trimmedNote.isEmpty ? nil : trimmedNote,
                dueAt: dueAt,
                repeatRule: kind == .reminder ? repeatRule : .none,
                photoNames: photoNames,
                collection: collection
            )
            modelContext.insert(target)
        }

        if target.kind == .reminder {
            Task {
                let status = await NotificationManager.authorizationStatus()
                if status == .notDetermined {
                    _ = await NotificationManager.requestAuthorization()
                }
                NotificationManager.schedule(for: target)
            }
        }

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}
