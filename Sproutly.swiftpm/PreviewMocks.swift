import SwiftData
import SwiftUI

@MainActor
public let previewContainer: ModelContainer = {
    do {
        let schema = Schema([Milestone.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])

        // For in-memory preview containers the remote-change notification trick
        // is not needed — the store is ephemeral and there are no persistent
        // change notifications at all. We just insert directly and save once,
        // before any view is created, so the data is already in the store when
        // @Query first evaluates.
        //
        // This works in previews because the container is fully constructed and
        // the in-memory SQLite file is populated BEFORE SwiftUI renders the
        // preview view. @Query reads the initial snapshot synchronously on first
        // render and picks up all 80 rows.
        let all = DataSeeder.allMilestones
        for m in all { container.mainContext.insert(m) }
        try container.mainContext.save()

        return container
    } catch {
        fatalError("Failed to build preview container: \(error)")
    }
}()
