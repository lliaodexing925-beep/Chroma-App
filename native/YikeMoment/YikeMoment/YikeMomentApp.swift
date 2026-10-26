import SwiftUI
import SwiftData

@main
struct YikeMomentApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([Moment.self, YCollection.self])
        do {
            container = try ModelContainer(
                for: schema,
                configurations: ModelConfiguration(schema: schema)
            )
        } catch {
            container = try! ModelContainer(
                for: schema,
                configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            )
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
