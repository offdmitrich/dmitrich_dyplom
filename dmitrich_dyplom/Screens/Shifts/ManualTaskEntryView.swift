import SwiftData
import SwiftUI

struct ManualTaskEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(LanguageManager.self) private var languageManager
    @Environment(ToastManager.self) private var toastManager

    @State private var drafts = [TaskDraft()]
    @State private var errorMessage: String?

    let shift: WorkShift

    var body: some View {
        Form {
            Section {
                ForEach($drafts) { $draft in
                    HStack {
                        TextField(languageManager.string(L.shiftDetailsTaskDuration), text: $draft.duration)
                            .keyboardType(.numbersAndPunctuation)
                            .accessibilityLabel(languageManager.string(L.shiftDetailsTaskDuration))

                        if drafts.count > 1 {
                            Button(role: .destructive) {
                                let id = draft.id
                                drafts.removeAll { $0.id == id }
                                errorMessage = nil
                            } label: {
                                Label(languageManager.string(L.shiftDetailsDeleteTask), systemImage: "trash")
                                    .labelStyle(.iconOnly)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }

                Button(languageManager.string(L.shiftDetailsAddAnotherTask)) {
                    drafts.append(TaskDraft())
                    errorMessage = nil
                }
            } footer: {
                Text(languageManager.string(L.shiftDetailsDurationHint))
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(languageManager.string(L.shiftDetailsAddTask))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(languageManager.string(L.commonClose)) {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(languageManager.string(L.commonSave)) {
                    saveTasks()
                }
            }
        }
    }

    private func saveTasks() {
        var durations: [Int] = []

        // сначала проверяем все строки, затем сохраняем задачи одним действием
        for draft in drafts {
            guard let seconds = durationInSeconds(draft.duration) else {
                errorMessage = languageManager.string(L.shiftDetailsInvalidTaskDuration)
                return
            }
            durations.append(seconds)
        }

        let firstNumber = ManualTaskNumbering.nextManualTaskNumber(for: shift)
        for (index, seconds) in durations.enumerated() {
            let task = TaskRecord(
                externalTaskID: String(firstNumber + index),
                taskDate: shift.startTime,
                taskType: KnownTaskType.logEditing.rawValue,
                status: KnownTaskStatus.completed.rawValue,
                durationSeconds: seconds,
                rawBlock: TaskRecord.manualEntryRawBlock
            )
            modelContext.insert(task)
            task.shift = shift
        }

        do {
            try modelContext.save()
            toastManager.show(AppToast(message: languageManager.string(L.shiftDetailsTaskAdded), kind: .success))
            dismiss()
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
        }
    }

    private func durationInSeconds(_ text: String) -> Int? {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = value.split(separator: ":", omittingEmptySubsequences: false)
        guard (1...3).contains(parts.count) else { return nil }

        // при переходе к следующей части часы и минуты переводим в секунды
        var total = 0
        for part in parts {
            guard let number = Int(part), number >= 0 else { return nil }
            let (scaled, scaleOverflow) = total.multipliedReportingOverflow(by: 60)
            let (sum, sumOverflow) = scaled.addingReportingOverflow(number)
            guard !scaleOverflow, !sumOverflow else { return nil }
            total = sum
        }
        return total > 0 ? total : nil
    }
}

private struct TaskDraft: Identifiable {
    let id = UUID()
    var duration = ""
}
