import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var moments: [Moment]

    var body: some View {
        TabView {
            TimelineView()
                .tabItem {
                    Label("时间轴", systemImage: "timeline.selection")
                }
            CollectionsView()
                .tabItem {
                    Label("合集", systemImage: "square.stack")
                }
            SettingsView()
                .tabItem {
                    Label("我的", systemImage: "person.crop.circle")
                }
        }
        .tint(.accentColor)
        .onAppear {
            NotificationManager.syncAll(moments: moments)
        }
        .onChange(of: moments.map(\.id)) { _, _ in
            NotificationManager.syncAll(moments: moments)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Moment.self, YCollection.self], inMemory: true)
}
