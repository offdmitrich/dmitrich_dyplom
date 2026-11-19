import Foundation
import SwiftData

enum AppModelContainer {
    static func makeContainer() -> ModelContainer {
        makeContainer(isStoredInMemoryOnly: false)
    }

    static func makePreviewContainer() -> ModelContainer {
        // предпросмотр в Xcode использует отдельную базу в памяти
        makeContainer(isStoredInMemoryOnly: true)
    }

    private static func makeContainer(isStoredInMemoryOnly: Bool) -> ModelContainer {
        let schema = Schema([
            Employee.self,
            WorkShift.self,
            TaskRecord.self,
            AppSettings.self
        ])

        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isStoredInMemoryOnly)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create model container: \(error.localizedDescription)")
        }
    }
}
