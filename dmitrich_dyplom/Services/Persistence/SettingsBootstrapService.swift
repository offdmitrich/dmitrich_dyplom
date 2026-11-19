import SwiftData

struct SettingsBootstrapService {
    func bootstrapIfNeeded(in context: ModelContext) throws {
        var descriptor = FetchDescriptor<AppSettings>()
        descriptor.fetchLimit = 1
        guard try context.fetch(descriptor).isEmpty else { return }

        context.insert(AppSettings())
        try context.save()
    }
}
