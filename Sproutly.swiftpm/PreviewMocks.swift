import SwiftData
import SwiftUI

@MainActor
public let previewContainer: ModelContainer = {
    do {
        let schema = Schema([Milestone.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        DataSeeder.seedIfNeeded(modelContext: container.mainContext)
        return container
    } catch {
        fatalError("Failed to build preview container: \(error)")
    }
}()
